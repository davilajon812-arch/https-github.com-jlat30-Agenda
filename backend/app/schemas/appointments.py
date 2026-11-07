"""Esquemas de citas."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

APPOINTMENT_STATUSES = (
    "pendiente",
    "confirmada",
    "completada",
    "cancelada",
    "no_asistio",
)


class AppointmentCreate(BaseModel):
    client_id: UUID
    service_id: UUID | None = None
    staff_id: UUID | None = None
    location_id: UUID | None = None
    starts_at: str = Field(description="ISO 8601 con zona horaria")
    ends_at: str | None = Field(
        default=None,
        description="Si se omite, se calcula con la duración del servicio",
    )
    price: float | None = Field(default=None, ge=0)
    notes: str | None = None


class AppointmentUpdate(BaseModel):
    service_id: UUID | None = None
    staff_id: UUID | None = None
    location_id: UUID | None = None
    starts_at: str | None = None
    ends_at: str | None = None
    price: float | None = Field(default=None, ge=0)
    notes: str | None = None


class AppointmentStatusUpdate(BaseModel):
    status: str = Field(pattern="^(pendiente|confirmada|completada|cancelada|no_asistio)$")
    reason: str | None = None


class AppointmentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    client_id: UUID
    client_name: str | None = None
    client_phone: str | None = None
    service_id: UUID | None = None
    service_name: str | None = None
    staff_id: UUID | None = None
    staff_name: str | None = None
    location_id: UUID | None = None
    starts_at: datetime
    ends_at: datetime
    status: str
    price: float | None = None
    notes: str | None = None
