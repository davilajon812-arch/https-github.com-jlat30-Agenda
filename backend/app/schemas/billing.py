"""Esquemas de facturación y planes."""

from __future__ import annotations

from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class PlanRead(BaseModel):
    """Plan con sus límites (los precios los da Google Play en la app)."""

    id: str
    name: str
    play_product_id: str | None = None
    max_staff: int | None = None
    max_locations: int | None = None
    max_appointments_per_month: int | None = None
    max_online_bookings_per_month: int | None = None
    max_messages_per_month: int | None = None
    features: dict[str, Any] = Field(default_factory=dict)


class UsageRead(BaseModel):
    staff_count: int
    appointments_this_month: int
    messages_this_month: int
    online_bookings_this_month: int = 0


class EntitlementsRead(BaseModel):
    """Plan efectivo del negocio, con consumo y cupos restantes."""

    business_id: UUID
    plan: PlanRead
    status: str
    source: str
    auto_renewing: bool
    current_period_end: str | None = None
    product_id: str | None = None
    usage: UsageRead
    remaining: dict[str, int | None]
    upgrade_to: str | None = None


class VerifyPurchaseRequest(BaseModel):
    business_id: UUID
    product_id: str = Field(min_length=1, max_length=120)
    purchase_token: str = Field(min_length=1, max_length=4096)
