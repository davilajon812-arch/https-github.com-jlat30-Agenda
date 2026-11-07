"""Utilidades de fecha y hora con zona horaria."""

from __future__ import annotations

from datetime import date, datetime, time
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import HTTPException, status


def parse_datetime(value: str, field: str = "fecha") -> datetime:
    """Convierte un ISO 8601 a datetime con zona horaria (obligatoria)."""
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=f"{field} no es una fecha ISO 8601 válida",
        ) from exc

    if parsed.tzinfo is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=f"{field} debe incluir zona horaria (por ejemplo -06:00)",
        )
    return parsed


def parse_date(value: str) -> date:
    """Convierte `YYYY-MM-DD` a date."""
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="La fecha debe tener el formato YYYY-MM-DD",
        ) from exc


def get_timezone(name: str) -> ZoneInfo:
    """Zona horaria IANA del negocio, con respaldo en UTC."""
    try:
        return ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError):
        return ZoneInfo("UTC")


def weekday_sunday_zero(value: date) -> int:
    """Día de la semana con 0 = domingo (igual que `staff_schedules.weekday`)."""
    return (value.weekday() + 1) % 7


def day_bounds_utc(day: date, tz: ZoneInfo) -> tuple[datetime, datetime]:
    """Inicio y fin del día local convertidos a UTC."""
    start_local = datetime.combine(day, time.min, tzinfo=tz)
    end_local = datetime.combine(day, time.max, tzinfo=tz)
    return start_local.astimezone(ZoneInfo("UTC")), end_local.astimezone(
        ZoneInfo("UTC")
    )
