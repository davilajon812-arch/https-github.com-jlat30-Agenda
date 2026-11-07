"""Esquemas de servicios que ofrece el negocio."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ServiceBase(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    description: str | None = None
    duration_minutes: int = Field(default=30, ge=5, le=600)
    price: float = Field(default=0, ge=0)
    is_active: bool = True


class ServiceCreate(ServiceBase):
    pass


class ServiceUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    description: str | None = None
    duration_minutes: int | None = Field(default=None, ge=5, le=600)
    price: float | None = Field(default=None, ge=0)
    is_active: bool | None = None


class ServiceRead(ServiceBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    created_at: datetime
    updated_at: datetime
