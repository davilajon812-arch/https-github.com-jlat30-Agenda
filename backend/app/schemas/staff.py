"""Esquemas de empleados, horarios y bloqueos."""

from __future__ import annotations

from datetime import datetime, time
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class StaffBase(BaseModel):
    display_name: str = Field(min_length=1, max_length=120)
    phone: str | None = None
    color: str = Field(default="#0F766E", pattern=r"^#[0-9A-Fa-f]{6}$")
    is_active: bool = True
    profile_id: UUID | None = None


class StaffCreate(StaffBase):
    pass


class StaffUpdate(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=120)
    phone: str | None = None
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    is_active: bool | None = None
    profile_id: UUID | None = None


class StaffRead(StaffBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    created_at: datetime
    updated_at: datetime


class ScheduleSlot(BaseModel):
    """Franja de trabajo semanal (weekday: 0 = domingo ... 6 = sábado)."""

    id: UUID | None = None
    weekday: int = Field(ge=0, le=6)
    start_time: time
    end_time: time
    location_id: UUID | None = None


class ScheduleReplace(BaseModel):
    """Reemplaza el horario semanal completo del empleado."""

    slots: list[ScheduleSlot] = Field(default_factory=list)


class StaffScheduleRead(ScheduleSlot):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    staff_id: UUID


class BlockCreate(BaseModel):
    starts_at: str = Field(description="ISO 8601, por ejemplo 2026-02-10T09:00:00-06:00")
    ends_at: str
    kind: str = Field(default="bloqueo", pattern="^(vacacion|descanso|bloqueo)$")
    reason: str | None = None


class BlockRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    staff_id: UUID
    starts_at: datetime
    ends_at: datetime
    kind: str
    reason: str | None = None
