"""Reglas de negocio de las citas: duración, choques de horario y estados."""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any
from uuid import UUID

from fastapi import HTTPException, status
from psycopg import Connection

from app.core.timeutils import parse_datetime

ACTIVE_STATUSES = ("pendiente", "confirmada", "completada")
FINAL_STATUSES = ("completada", "cancelada", "no_asistio")


def fetch_service_duration(
    conn: Connection[Any], business_id: str, service_id: UUID
) -> int | None:
    """Duración del servicio si pertenece al negocio."""
    row = (
        conn.execute(
            """
            select duration_minutes
            from public.services
            where id = %s and business_id = %s
            """,
            (str(service_id), business_id),
        )
    ).fetchone()
    return row["duration_minutes"] if row else None


def ensure_client_belongs(
    conn: Connection[Any], business_id: str, client_id: UUID
) -> None:
    row = (
        conn.execute(
            "select 1 from public.clients where id = %s and business_id = %s",
            (str(client_id), business_id),
        )
    ).fetchone()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado"
        )


def ensure_staff_belongs(
    conn: Connection[Any], business_id: str, staff_id: UUID
) -> None:
    row = (
        conn.execute(
            "select 1 from public.staff_members where id = %s and business_id = %s",
            (str(staff_id), business_id),
        )
    ).fetchone()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Empleado no encontrado"
        )


def find_conflict(
    conn: Connection[Any],
    business_id: str,
    staff_id: str | None,
    starts_at: datetime,
    ends_at: datetime,
    exclude_id: str | None = None,
) -> dict[str, Any] | None:
    """Cita activa del mismo empleado que se solapa con el rango dado."""
    if staff_id is None:
        return None

    row = (
        conn.execute(
            """
            select id, starts_at, ends_at
            from public.appointments
            where business_id = %s
              and staff_id = %s
              and status = any(%s)
              and starts_at < %s
              and ends_at > %s
              and (%s::uuid is null or id <> %s::uuid)
            limit 1
            """,
            (
                business_id,
                staff_id,
                list(ACTIVE_STATUSES),
                ends_at,
                starts_at,
                exclude_id,
                exclude_id,
            ),
        )
    ).fetchone()
    return row


def ensure_no_conflict(
    conn: Connection[Any],
    business_id: str,
    staff_id: str | None,
    starts_at: datetime,
    ends_at: datetime,
    exclude_id: str | None = None,
) -> None:
    """Responde 409 si el empleado ya tiene una cita en ese horario."""
    conflict = find_conflict(
        conn, business_id, staff_id, starts_at, ends_at, exclude_id
    )
    if conflict is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El empleado ya tiene una cita en ese horario",
        )


def ensure_block_free(
    conn: Connection[Any],
    staff_id: str | None,
    starts_at: datetime,
    ends_at: datetime,
) -> None:
    """Responde 409 si la cita cae dentro de una ausencia programada."""
    if staff_id is None:
        return

    row = (
        conn.execute(
            """
            select 1
            from public.staff_blocks
            where staff_id = %s and starts_at < %s and ends_at > %s
            limit 1
            """,
            (staff_id, ends_at, starts_at),
        )
    ).fetchone()
    if row is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El empleado tiene un bloqueo en ese horario",
        )


def resolve_range(
    starts_at_raw: str, ends_at_raw: str | None, duration_minutes: int | None
) -> tuple[datetime, datetime]:
    """Calcula el rango de la cita a partir del servicio."""
    starts_at = parse_datetime(starts_at_raw, "starts_at")

    if ends_at_raw:
        ends_at = parse_datetime(ends_at_raw, "ends_at")
    else:
        if not duration_minutes:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="Indica ends_at o un servicio con duración",
            )
        ends_at = starts_at + timedelta(minutes=duration_minutes)

    if ends_at <= starts_at:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="ends_at debe ser posterior a starts_at",
        )
    return starts_at, ends_at


def validate_transition(current: str, new: str) -> None:
    """Evita reabrir citas ya cerradas."""
    if current == new:
        return
    if current in FINAL_STATUSES and new not in FINAL_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"No se puede pasar de '{current}' a '{new}'",
        )
