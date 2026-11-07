"""Esquemas de disponibilidad."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class SlotRead(BaseModel):
    """Hueco libre ofrecido al negocio."""

    starts_at: datetime
    ends_at: datetime


class StaffAvailability(BaseModel):
    staff_id: UUID
    staff_name: str
    slots: list[SlotRead]


class AvailabilityResponse(BaseModel):
    date: str = Field(description="Día consultado en la zona horaria del negocio")
    timezone: str
    service_id: UUID
    service_duration_minutes: int
    staff: list[StaffAvailability]
