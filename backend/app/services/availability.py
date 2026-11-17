"""Cálculo de huecos libres por servicio, empleado y fecha."""

from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from fastapi import HTTPException, status
from psycopg import Connection

from app.core.timeutils import day_bounds_utc, get_timezone, weekday_sunday_zero
from app.schemas.availability import AvailabilityResponse, SlotRead, StaffAvailability

SLOT_STEP_MINUTES = 15
ACTIVE_STATUSES = ("pendiente", "confirmada", "completada")


def _fetch_service(
    conn: Connection[Any], business_id: str, service_id: str
) -> dict[str, Any]:
    row = (
        conn.execute(
            """
            select id, duration_minutes
            from public.services
            where id = %s and business_id = %s
            """,
            (service_id, business_id),
        )
    ).fetchone()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado"
        )
    return row


def _fetch_timezone(conn: Connection[Any], business_id: str) -> str:
    row = (
        conn.execute(
            "select timezone from public.businesses where id = %s", (business_id,)
        )
    ).fetchone()
    return row["timezone"] if row else "UTC"


def _fetch_staff(
    conn: Connection[Any], business_id: str, staff_id: str | None
) -> list[dict[str, Any]]:
    if staff_id:
        rows = (
            conn.execute(
                """
                select id, display_name
                from public.staff_members
                where business_id = %s and id = %s and is_active
                """,
                (business_id, staff_id),
            )
        ).fetchall()
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Empleado no encontrado"
            )
        return list(rows)

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


def _merge_intervals(
    intervals: list[tuple[datetime, datetime]],
) -> list[tuple[datetime, datetime]]:
    """Une intervalos solapados para consultar la agenda de una sola vez."""
    if not intervals:
        return []
    ordered = sorted(intervals)
    merged = [ordered[0]]
    for start, end in ordered[1:]:
        last_start, last_end = merged[-1]
        if start <= last_end:
            merged[-1] = (last_start, max(last_end, end))
        else:
            merged.append((start, end))
    return merged


def compute_availability(
    conn: Connection[Any],
    business_id: str,
    service_id: str,
    day_value: str,
    staff_id: str | None = None,
    now: datetime | None = None,
) -> AvailabilityResponse:
    """Devuelve los huecos libres del día para el servicio indicado."""
    service = _fetch_service(conn, business_id, service_id)
    duration = timedelta(minutes=service["duration_minutes"])

    timezone_name = _fetch_timezone(conn, business_id)
    tz = get_timezone(timezone_name)
    reference = (now or datetime.now(tz)).astimezone(tz)

    day = date.fromisoformat(day_value)
    weekday = weekday_sunday_zero(day)
    day_start_utc, day_end_utc = day_bounds_utc(day, tz)

    staff_rows = _fetch_staff(conn, business_id, staff_id)
    if not staff_rows:
        return AvailabilityResponse(
            date=day.isoformat(),
            timezone=timezone_name,
            service_id=service_id,
            service_duration_minutes=service["duration_minutes"],
            staff=[],
        )

    staff_ids = [row["id"] for row in staff_rows]

    schedule_rows = (
        conn.execute(
            """
            select staff_id, start_time, end_time
            from public.staff_schedules
            where staff_id = any(%s) and weekday = %s and is_active
            order by start_time
            """,
            (staff_ids, weekday),
        )
    ).fetchall()

    busy_rows = (
        conn.execute(
            """
            select staff_id, starts_at, ends_at
            from public.appointments
            where staff_id = any(%s)
              and status = any(%s)
              and starts_at < %s
              and ends_at > %s
            """,
            (staff_ids, list(ACTIVE_STATUSES), day_end_utc, day_start_utc),
        )
    ).fetchall()

    block_rows = (
        conn.execute(
            """
            select staff_id, starts_at, ends_at
            from public.staff_blocks
            where staff_id = any(%s)
              and starts_at < %s
              and ends_at > %s
            """,
            (staff_ids, day_end_utc, day_start_utc),
        )
    ).fetchall()

    busy_by_staff: dict[str, list[tuple[datetime, datetime]]] = {}
    for row in list(busy_rows) + list(block_rows):
        busy_by_staff.setdefault(row["staff_id"], []).append(
            (row["starts_at"], row["ends_at"])
        )

    schedule_by_staff: dict[str, list[tuple[Any, Any]]] = {}
    for row in schedule_rows:
        schedule_by_staff.setdefault(row["staff_id"], []).append(
            (row["start_time"], row["end_time"])
        )

    result: list[StaffAvailability] = []
    for staff in staff_rows:
        busy = _merge_intervals(busy_by_staff.get(staff["id"], []))
        slots: list[SlotRead] = []

        for start_time, end_time in schedule_by_staff.get(staff["id"], []):
            cursor = datetime.combine(day, start_time, tzinfo=tz)
            limit = datetime.combine(day, end_time, tzinfo=tz)

            while cursor + duration <= limit:
                slot_end = cursor + duration
                overlaps = any(
                    busy_start < slot_end and busy_end > cursor
                    for busy_start, busy_end in busy
                )
                if cursor > reference and not overlaps:
                    slots.append(
                        SlotRead(
                            starts_at=cursor.isoformat(),
                            ends_at=slot_end.isoformat(),
                        )
                    )
                cursor += timedelta(minutes=SLOT_STEP_MINUTES)

        result.append(
            StaffAvailability(
                staff_id=staff["id"], staff_name=staff["display_name"], slots=slots
            )
        )

    return AvailabilityResponse(
        date=day.isoformat(),
        timezone=timezone_name,
        service_id=service_id,
        service_duration_minutes=service["duration_minutes"],
        staff=result,
    )
