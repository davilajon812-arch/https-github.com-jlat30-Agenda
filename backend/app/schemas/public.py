"""Esquemas del enlace público de reservas (sin cuenta)."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class PublicBusiness(BaseModel):
    """Datos del negocio que ve el cliente final."""

    name: str
    slug: str
    industry: str | None = None
    currency: str
    timezone: str
    phone: str | None = None
    address: str | None = None


class PublicDayHours(BaseModel):
    """Horario de atención de un día, ya agregado de todo el personal."""

    weekday: int = Field(ge=0, le=6, description="0 = domingo")
    opens_at: str = Field(description="Hora local HH:MM")
    closes_at: str = Field(description="Hora local HH:MM")


class PublicService(BaseModel):
    id: UUID
    name: str
    description: str | None = None
    duration_minutes: int
    price: float | None = None


class PublicStaff(BaseModel):
    id: UUID
    display_name: str


class PublicBusinessResponse(BaseModel):
    """Todo lo que la página necesita para pintar el primer paso."""

    business: PublicBusiness
    services: list[PublicService]
    staff: list[PublicStaff]
    hours: list[PublicDayHours] = Field(
        default_factory=list,
        description="Días con atención; vacío si aún no hay horarios cargados",
    )
    bookable: bool = Field(
        description="false si ningún empleado tiene horario: no hay nada que reservar"
    )
    days_ahead: int = Field(description="Días hacia adelante que se pueden reservar")


class PublicBookingCreate(BaseModel):
    """Reserva hecha por el cliente final."""

    service_id: UUID
    staff_id: UUID | None = None
    starts_at: datetime
    client_name: str = Field(min_length=2, max_length=120)
    client_phone: str = Field(min_length=6, max_length=32)
    notes: str | None = Field(default=None, max_length=500)

    @field_validator("client_name")
    @classmethod
    def _clean_name(cls, value: str) -> str:
        cleaned = " ".join(value.split())
        if len(cleaned) < 2:
            raise ValueError("Escribe tu nombre")
        return cleaned

    @field_validator("client_phone")
    @classmethod
    def _clean_phone(cls, value: str) -> str:
        digits = "".join(char for char in value if char.isdigit())
        if len(digits) < 8:
            raise ValueError("El teléfono debe tener al menos 8 dígitos")
        return digits


class PublicAppointment(BaseModel):
    """Cita vista por el cliente desde su enlace."""

    token: str
    business_name: str
    business_phone: str | None = None
    business_address: str | None = None
    service_name: str | None = None
    staff_name: str | None = None
    starts_at: datetime
    ends_at: datetime
    status: str
    price: float | None = None
    currency: str
    timezone: str
    cancellable: bool
