"""Reservas públicas: el cliente final agenda sin cuenta desde un enlace.

Toda la lógica vive aquí para que las rutas queden delgadas. El negocio se
identifica por su `slug` público y nunca se expone el id interno de la cita:
el cliente recibe un token opaco con el que consulta o cancela.
"""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from fastapi import HTTPException, status
from psycopg import Connection

from app.core.timeutils import day_bounds_utc, get_timezone
from app.schemas.public import PublicBookingCreate
from app.services.availability import compute_availability
from app.services.entitlements import (
    LIMIT_APPOINTMENTS,
    ensure_capacity,
    load_entitlements,
)

# Días hacia adelante que ofrece el enlace público.
DAYS_AHEAD = 21
# Reservas activas que un mismo teléfono puede tener en un día.
MAX_SAME_DAY_BOOKINGS = 3

ACTIVE_STATUSES = ("pendiente", "confirmada", "completada")

BUSINESS_SELECT = """
    select id, name, slug, industry, currency, timezone, phone, address,
           country_code
    from public.businesses
    where slug = %s and public_booking_enabled
"""


def load_business(conn: Connection[Any], slug: str) -> dict[str, Any]:
    """Negocio con reservas públicas activas, o 404."""
    row = (conn.execute(BUSINESS_SELECT, (slug,))).fetchone()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Este enlace de reservas no está disponible",
        )
    return row


def list_services(conn: Connection[Any], business_id: str) -> list[dict[str, Any]]:
    rows = (
        conn.execute(
            """
            select id, name, description, duration_minutes, price::float8 as price
            from public.services
            where business_id = %s and is_active
            order by name
            """,
            (business_id,),
        )
    ).fetchall()
    return list(rows)


def list_staff(conn: Connection[Any], business_id: str) -> list[dict[str, Any]]:
    rows = (
        conn.execute(
            """
            select id, display_name
            from public.staff_members
            where business_id = %s and is_active
            order by display_name
            """,
            (business_id,),
        )
    ).fetchall()
    return list(rows)


def business_hours(conn: Connection[Any], business_id: str) -> list[dict[str, Any]]:
    """Horario de atención del local, agregado de todo el personal.

    No existe un horario del negocio aparte del de cada empleado, así que el
    día abre con el turno más temprano y cierra con el más tardío.
    """
    rows = (
        conn.execute(
            """
            select weekday,
                   to_char(min(start_time), 'HH24:MI') as opens_at,
                   to_char(max(end_time), 'HH24:MI') as closes_at
            from public.staff_schedules
            where business_id = %s and is_active
            group by weekday
            order by case when weekday = 0 then 7 else weekday end
            """,
            (business_id,),
        )
    ).fetchall()
    return list(rows)


def is_bookable(conn: Connection[Any], business_id: str) -> bool:
    """Verdadero si al menos un empleado activo tiene horario cargado."""
    row = (
        conn.execute(
            """
            select exists (
                select 1
                from public.staff_members st
                join public.staff_schedules sc
                  on sc.staff_id = st.id and sc.is_active
                where st.business_id = %s and st.is_active
            ) as bookable
            """,
            (business_id,),
        )
    ).fetchone()
    return bool(row["bookable"]) if row else False


def _normalize_phone(phone: str) -> str:
    return "".join(char for char in phone if char.isdigit())


def _upsert_client(
    conn: Connection[Any], business_id: str, name: str, phone: str
) -> str:
    """Reutiliza el cliente si el teléfono ya existe en el negocio."""
    digits = _normalize_phone(phone)
    row = (
        conn.execute(
            """
            select id
            from public.clients
            where business_id = %s
              and regexp_replace(phone, '[^0-9]', '', 'g') = %s
            order by created_at
            limit 1
            """,
            (business_id, digits),
        )
    ).fetchone()
    if row is not None:
        return row["id"]

    created = (
        conn.execute(
            """
            insert into public.clients (business_id, full_name, phone)
            values (%s, %s, %s)
            returning id
            """,
            (business_id, name, digits),
        )
    ).fetchone()
    assert created is not None
    return created["id"]


def _slot_candidates(
    conn: Connection[Any],
    business: dict[str, Any],
    payload: PublicBookingCreate,
    timezone_name: str,
) -> list[str]:
    """Empleados libres en ese hueco, según la disponibilidad real.

    Cuando el cliente no eligió a nadie, todos los que puedan atenderlo son
    candidatos y luego se elige al menos ocupado del día.
    """
    tz = get_timezone(timezone_name)
    local_day = payload.starts_at.astimezone(tz).date().isoformat()
    requested = payload.starts_at.astimezone(ZoneInfo("UTC"))

    availability = compute_availability(
        conn,
        business_id=str(business["id"]),
        service_id=str(payload.service_id),
        day_value=local_day,
        staff_id=str(payload.staff_id) if payload.staff_id else None,
    )

    candidates = [
        str(staff.staff_id)
        for staff in availability.staff
        if any(
            slot.starts_at.astimezone(ZoneInfo("UTC")) == requested
            for slot in staff.slots
        )
    ]
    if not candidates:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ese horario ya no está disponible. Elige otro.",
        )
    return candidates


def _pick_staff(
    conn: Connection[Any],
    business_id: str,
    candidates: list[str],
    starts_at: datetime,
    timezone_name: str,
) -> str:
    """Reparte la cita al empleado con menos citas ese día.

    Evita que "cualquier profesional" cargue siempre al primero de la lista
    alfabética mientras los demás quedan con la agenda vacía.
    """
    if len(candidates) == 1:
        return candidates[0]

    tz = get_timezone(timezone_name)
    day_start, day_end = day_bounds_utc(starts_at.astimezone(tz).date(), tz)

    rows = (
        conn.execute(
            """
            select staff_id, count(*) as total
            from public.appointments
            where business_id = %s
              and staff_id = any(%s)
              and status = any(%s)
              and starts_at >= %s and starts_at < %s
            group by staff_id
            """,
            (business_id, candidates, list(ACTIVE_STATUSES), day_start, day_end),
        )
    ).fetchall()

    load = {str(row["staff_id"]): row["total"] for row in rows}
    ranked = sorted(
        enumerate(candidates),
        key=lambda item: (load.get(item[1], 0), item[0]),
    )
    return ranked[0][1]


def _ensure_not_repeating(
    conn: Connection[Any],
    business_id: str,
    client_id: str,
    timezone_name: str,
    starts_at: datetime,
) -> None:
    """Evita que un mismo teléfono acapare el día con reservas repetidas."""
    tz = get_timezone(timezone_name)
    day_start = datetime.combine(
        starts_at.astimezone(tz).date(), datetime.min.time(), tzinfo=tz
    ).astimezone(ZoneInfo("UTC"))
    day_end = day_start + timedelta(days=1)

    row = (
        conn.execute(
            """
            select count(*) as total
            from public.appointments
            where business_id = %s
              and client_id = %s
              and status = any(%s)
              and starts_at >= %s and starts_at < %s
            """,
            (business_id, client_id, list(ACTIVE_STATUSES), day_start, day_end),
        )
    ).fetchone()

    if row is not None and row["total"] >= MAX_SAME_DAY_BOOKINGS:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=(
                "Ya tienes varias citas para ese día. "
                "Llámanos al negocio si necesitas otra."
            ),
        )


def appointment_payload(row: dict[str, Any]) -> dict[str, Any]:
    """Da forma a la cita tal como la ve el cliente final."""
    cancellable = (
        row["status"] in ("pendiente", "confirmada")
        and row["starts_at"].astimezone(ZoneInfo("UTC")) > datetime.now(ZoneInfo("UTC"))
    )
    return {
        "token": row["public_token"],
        "business_name": row["business_name"],
        "business_phone": row["business_phone"],
        "business_address": row.get("business_address"),
        "service_name": row["service_name"],
        "staff_name": row["staff_name"],
        "starts_at": row["starts_at"],
        "ends_at": row["ends_at"],
        "status": row["status"],
        "price": row["price"],
        "currency": row["currency"],
        "timezone": row["timezone"],
        "cancellable": cancellable,
    }


APPOINTMENT_SELECT = """
    select a.id, a.public_token, a.starts_at, a.ends_at, a.status,
           a.price::float8 as price,
           b.name as business_name, b.phone as business_phone,
           b.address as business_address,
           b.currency, b.timezone,
           s.name as service_name, st.display_name as staff_name
    from public.appointments a
    join public.businesses b on b.id = a.business_id
    left join public.services s on s.id = a.service_id
    left join public.staff_members st on st.id = a.staff_id
"""


def book(
    conn: Connection[Any], business: dict[str, Any], payload: PublicBookingCreate
) -> dict[str, Any]:
    """Crea la cita validando disponibilidad, plan y anti-abuso."""
    business_id = str(business["id"])
    timezone_name = business["timezone"] or "UTC"

    service = (
        conn.execute(
            """
            select id, name, duration_minutes, price::float8 as price
            from public.services
            where id = %s and business_id = %s and is_active
            """,
            (str(payload.service_id), business_id),
        )
    ).fetchone()
    if service is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado"
        )

    starts_at = payload.starts_at.astimezone(ZoneInfo("UTC"))
    ends_at = starts_at + timedelta(minutes=service["duration_minutes"])

    candidates = _slot_candidates(conn, business, payload, timezone_name)
    staff_id = (
        str(payload.staff_id)
        if payload.staff_id
        else _pick_staff(conn, business_id, candidates, starts_at, timezone_name)
    )

    ensure_capacity(
        load_entitlements(conn, business_id), LIMIT_APPOINTMENTS
    )

    client_id = _upsert_client(
        conn, business_id, payload.client_name, payload.client_phone
    )
    _ensure_not_repeating(
        conn, business_id, client_id, timezone_name, starts_at
    )

    row = (
        conn.execute(
            """
            insert into public.appointments (
                business_id, client_id, service_id, staff_id,
                starts_at, ends_at, status, price, notes, confirmed_at,
                booked_online
            )
            values (%s, %s, %s, %s, %s, %s, 'confirmada', %s, %s, now(), true)
            returning id
            """,
            (
                business_id,
                client_id,
                str(service["id"]),
                staff_id,
                starts_at,
                ends_at,
                service["price"],
                payload.notes,
            ),
        )
    ).fetchone()
    assert row is not None

    return fetch_by_token(conn, business_id, token=None, appointment_id=row["id"])


def fetch_by_token(
    conn: Connection[Any],
    business_id: str,
    token: str | None,
    appointment_id: str | None = None,
) -> dict[str, Any]:
    """Cita por token (o por id, para uso interno al crearla)."""
    if token is None:
        row = (
            conn.execute(
                f"{APPOINTMENT_SELECT} where a.business_id = %s and a.id = %s",
                (business_id, appointment_id),
            )
        ).fetchone()
    else:
        row = (
            conn.execute(
                f"{APPOINTMENT_SELECT} where a.business_id = %s and a.public_token = %s",
                (business_id, token),
            )
        ).fetchone()

    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Cita no encontrada"
        )
    return appointment_payload(row)


def cancel(conn: Connection[Any], business_id: str, token: str) -> dict[str, Any]:
    """Cancela la propia cita si sigue activa y no ha pasado."""
    appointment = fetch_by_token(conn, business_id, token)
    if not appointment["cancellable"]:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Esta cita ya no se puede cancelar",
        )

    conn.execute(
        """
        update public.appointments
        set status = 'cancelada',
            canceled_reason = 'Cancelada por el cliente desde el enlace'
        where business_id = %s and public_token = %s
        """,
        (business_id, token),
    )
    return fetch_by_token(conn, business_id, token)
