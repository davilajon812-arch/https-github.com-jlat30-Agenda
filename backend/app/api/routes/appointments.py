"""Citas: agenda por rango, creación, edición y cambios de estado."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from psycopg import AsyncConnection
from psycopg.errors import CheckViolation, ForeignKeyViolation

from app.api.deps import get_current_user
from app.core.db import get_connection
from app.core.security import AuthenticatedUser
from app.schemas.appointments import (
    AppointmentCreate,
    AppointmentRead,
    AppointmentStatusUpdate,
    AppointmentUpdate,
)
from app.services import appointments as rules
from app.services.access import BUSINESS_STAFF_ROLES, require_member, require_roles

router = APIRouter(prefix="/businesses/{business_id}/appointments", tags=["appointments"])

APPOINTMENT_SELECT = """
    select a.id, a.business_id, a.client_id,
           c.full_name as client_name, c.phone as client_phone,
           a.service_id, s.name as service_name,
           a.staff_id, st.display_name as staff_name,
           a.location_id, a.starts_at, a.ends_at, a.status,
           a.price::float8 as price, a.notes
    from public.appointments a
    join public.clients c on c.id = a.client_id
    left join public.services s on s.id = a.service_id
    left join public.staff_members st on st.id = a.staff_id
"""

Connection = Annotated[AsyncConnection[Any], Depends(get_connection)]
CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_user)]


@router.get("", response_model=list[AppointmentRead], summary="Agenda por rango")
async def list_appointments(
    business_id: UUID,
    conn: Connection,
    user: CurrentUser,
    date_from: Annotated[datetime | None, Query(alias="from")] = None,
    date_to: Annotated[datetime | None, Query(alias="to")] = None,
    staff_id: Annotated[UUID | None, Query()] = None,
    appointment_status: Annotated[
        str | None, Query(alias="status", pattern="^(pendiente|confirmada|completada|cancelada|no_asistio)$")
    ] = None,
    limit: Annotated[int, Query(ge=1, le=500)] = 200,
) -> list[dict[str, Any]]:
    await require_member(conn, user.id, str(business_id))

    query = f"{APPOINTMENT_SELECT} where a.business_id = %s"
    params: list[Any] = [str(business_id)]

    if date_from is not None:
        query += " and a.ends_at >= %s"
        params.append(date_from)
    if date_to is not None:
        query += " and a.starts_at <= %s"
        params.append(date_to)
    if staff_id is not None:
        query += " and a.staff_id = %s"
        params.append(str(staff_id))
    if appointment_status is not None:
        query += " and a.status = %s"
        params.append(appointment_status)

    query += " order by a.starts_at limit %s"
    params.append(limit)

    return list(await (await conn.execute(query, params)).fetchall())


@router.get(
    "/{appointment_id}", response_model=AppointmentRead, summary="Detalle de cita"
)
async def get_appointment(
    business_id: UUID, appointment_id: UUID, conn: Connection, user: CurrentUser
) -> dict[str, Any]:
    await require_member(conn, user.id, str(business_id))
    return await _fetch_appointment(conn, business_id, appointment_id)


@router.post(
    "",
    response_model=AppointmentRead,
    status_code=status.HTTP_201_CREATED,
    summary="Crear cita",
)
async def create_appointment(
    business_id: UUID,
    payload: AppointmentCreate,
    conn: Connection,
    user: CurrentUser,
) -> dict[str, Any]:
    await require_roles(conn, user.id, str(business_id), BUSINESS_STAFF_ROLES)

    await rules.ensure_client_belongs(conn, str(business_id), payload.client_id)

    duration = None
    if payload.service_id is not None:
        duration = await rules.fetch_service_duration(
            conn, str(business_id), payload.service_id
        )
        if duration is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Servicio no encontrado",
            )

    staff_id = str(payload.staff_id) if payload.staff_id else None
    if payload.staff_id is not None:
        await rules.ensure_staff_belongs(conn, str(business_id), payload.staff_id)

    starts_at, ends_at = rules.resolve_range(
        payload.starts_at, payload.ends_at, duration
    )

    if staff_id is not None:
        await rules.ensure_no_conflict(
            conn, str(business_id), staff_id, starts_at, ends_at
        )
        await rules.ensure_block_free(conn, staff_id, starts_at, ends_at)

    try:
        row = await (
            await conn.execute(
                """
                insert into public.appointments (
                    business_id, client_id, service_id, staff_id, location_id,
                    starts_at, ends_at, status, price, notes, created_by
                )
                values (%s, %s, %s, %s, %s, %s, %s, 'pendiente', %s, %s, %s)
                returning id
                """,
                (
                    str(business_id),
                    str(payload.client_id),
                    str(payload.service_id) if payload.service_id else None,
                    staff_id,
                    str(payload.location_id) if payload.location_id else None,
                    starts_at,
                    ends_at,
                    payload.price,
                    payload.notes,
                    user.id,
                ),
            )
        ).fetchone()
    except (CheckViolation, ForeignKeyViolation) as exc:
        raise _conflict_from_db(exc) from exc

    assert row is not None
    return await _fetch_appointment(conn, business_id, row["id"])


@router.patch(
    "/{appointment_id}", response_model=AppointmentRead, summary="Editar cita"
)
async def update_appointment(
    business_id: UUID,
    appointment_id: UUID,
    payload: AppointmentUpdate,
    conn: Connection,
    user: CurrentUser,
) -> dict[str, Any]:
    await require_roles(conn, user.id, str(business_id), BUSINESS_STAFF_ROLES)

    current = await _fetch_appointment(conn, business_id, appointment_id)
    changes = payload.model_dump(exclude_unset=True)

    duration = None
    if payload.service_id is not None:
        duration = await rules.fetch_service_duration(
            conn, str(business_id), payload.service_id
        )
        if duration is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado"
            )
    elif current["service_id"] is not None:
        duration = await rules.fetch_service_duration(
            conn, str(business_id), current["service_id"]
        )

    starts_raw = payload.starts_at or current["starts_at"].isoformat()
    ends_raw = payload.ends_at or (
        None if payload.starts_at else current["ends_at"].isoformat()
    )
    starts_at, ends_at = rules.resolve_range(starts_raw, ends_raw, duration)

    staff_id = (
        str(payload.staff_id)
        if payload.staff_id is not None
        else (str(current["staff_id"]) if current["staff_id"] else None)
    )
    if payload.staff_id is not None:
        await rules.ensure_staff_belongs(conn, str(business_id), payload.staff_id)

    if staff_id is not None:
        await rules.ensure_no_conflict(
            conn,
            str(business_id),
            staff_id,
            starts_at,
            ends_at,
            exclude_id=str(appointment_id),
        )
        await rules.ensure_block_free(conn, staff_id, starts_at, ends_at)

    assignments: list[str] = ["starts_at = %s", "ends_at = %s", "staff_id = %s"]
    values: list[Any] = [starts_at, ends_at, staff_id]

    for column in ("service_id", "location_id"):
        if column in changes:
            value = changes[column]
            assignments.append(f"{column} = %s")
            values.append(str(value) if value is not None else None)

    for column in ("price", "notes"):
        if column in changes:
            assignments.append(f"{column} = %s")
            values.append(changes[column])

    values.extend([str(appointment_id), str(business_id)])

    try:
        await conn.execute(
            f"""
            update public.appointments
            set {", ".join(assignments)}
            where id = %s and business_id = %s
            """,
            values,
        )
    except (CheckViolation, ForeignKeyViolation) as exc:
        raise _conflict_from_db(exc) from exc

    return await _fetch_appointment(conn, business_id, appointment_id)


@router.post(
    "/{appointment_id}/status",
    response_model=AppointmentRead,
    summary="Cambiar estado de la cita",
)
async def change_status(
    business_id: UUID,
    appointment_id: UUID,
    payload: AppointmentStatusUpdate,
    conn: Connection,
    user: CurrentUser,
) -> dict[str, Any]:
    await require_roles(conn, user.id, str(business_id), BUSINESS_STAFF_ROLES)

    current = await _fetch_appointment(conn, business_id, appointment_id)
    rules.validate_transition(current["status"], payload.status)

    extra = ""
    values: list[Any] = [payload.status]
    if payload.status == "confirmada":
        extra = ", confirmed_at = now()"
    elif payload.status == "cancelada":
        extra = ", canceled_reason = %s"
        values.append(payload.reason)

    values.extend([str(appointment_id), str(business_id)])

    try:
        await conn.execute(
            f"""
            update public.appointments
            set status = %s{extra}
            where id = %s and business_id = %s
            """,
            values,
        )
    except CheckViolation as exc:
        raise _conflict_from_db(exc) from exc

    return await _fetch_appointment(conn, business_id, appointment_id)


async def _fetch_appointment(
    conn: AsyncConnection[Any], business_id: UUID, appointment_id: UUID
) -> dict[str, Any]:
    row = await (
        await conn.execute(
            f"{APPOINTMENT_SELECT} where a.business_id = %s and a.id = %s",
            (str(business_id), str(appointment_id)),
        )
    ).fetchone()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Cita no encontrada"
        )
    return row


def _conflict_from_db(exc: Exception) -> HTTPException:
    """Traduce las validaciones de la base a respuestas HTTP claras."""
    message = str(exc)
    if "horario" in message:
        detail = "El empleado ya tiene una cita en ese horario"
    elif "bloqueo" in message:
        detail = "El empleado tiene un bloqueo en ese horario"
    else:
        detail = "Los datos de la cita no son válidos"
    return HTTPException(status_code=status.HTTP_409_CONFLICT, detail=detail)
