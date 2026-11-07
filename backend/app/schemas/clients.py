"""Esquemas de clientes del negocio."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ClientBase(BaseModel):
    full_name: str = Field(min_length=1, max_length=120)
    phone: str = Field(
        min_length=6,
        max_length=20,
        description="Teléfono con código de país, solo dígitos y '+'.",
    )
    notes: str | None = None


class ClientCreate(ClientBase):
    pass


class ClientUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=120)
    phone: str | None = Field(default=None, min_length=6, max_length=20)
    notes: str | None = None


class ClientRead(ClientBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    created_at: datetime
    updated_at: datetime


class ClientVisit(BaseModel):
    """Cita pasada de un cliente (historial de visitas)."""

    appointment_id: UUID
    starts_at: datetime
    ends_at: datetime
    status: str
    service_name: str | None = None
    staff_name: str | None = None
    price: float | None = None


class ClientHistory(BaseModel):
    client: ClientRead
    visits: list[ClientVisit]
    last_visit_at: datetime | None = None
    total_visits: int = 0
    total_spent: float = 0
