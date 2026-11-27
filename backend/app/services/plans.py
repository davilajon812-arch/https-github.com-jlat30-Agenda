"""Catálogo de planes: límites y funciones de cada uno."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from psycopg import Connection

# Respaldo si la tabla `plans` no está disponible (pruebas sin migraciones).
FALLBACK_PLANS: dict[str, dict[str, Any]] = {
    "free": {
        "name": "Gratis",
        "play_product_id": None,
        "max_staff": 1,
        "max_locations": None,
        "max_appointments_per_month": 100,
        "max_online_bookings_per_month": 50,
        "max_messages_per_month": None,
        "features": {
            "reminders": False,
            "advanced_reports": False,
            "custom_branding": False,
            "ads": True,
        },
        "sort_order": 1,
    },
    "pro": {
        "name": "Pro",
        "play_product_id": "turnia_pro_mensual",
        "max_staff": None,
        "max_locations": None,
        "max_appointments_per_month": None,
        "max_online_bookings_per_month": None,
        "max_messages_per_month": None,
        "features": {
            "reminders": True,
            "advanced_reports": True,
            "custom_branding": True,
            "ads": False,
        },
        "sort_order": 2,
    },
}

PLAN_ORDER = ("free", "pro")


@dataclass(frozen=True, slots=True)
class PlanLimit:
    """Límites de un plan. `None` significa ilimitado."""

    id: str
    name: str
    play_product_id: str | None
    max_staff: int | None
    max_locations: int | None
    max_appointments_per_month: int | None
    max_online_bookings_per_month: int | None
    max_messages_per_month: int | None
    features: dict[str, Any] = field(default_factory=dict)
    sort_order: int = 0


def _to_limit(plan_id: str, row: dict[str, Any]) -> PlanLimit:
    return PlanLimit(
        id=plan_id,
        name=row["name"],
        play_product_id=row.get("play_product_id"),
        max_staff=row.get("max_staff"),
        max_locations=row.get("max_locations"),
        max_appointments_per_month=row.get("max_appointments_per_month"),
        max_online_bookings_per_month=row.get("max_online_bookings_per_month"),
        max_messages_per_month=row.get("max_messages_per_month"),
        features=row.get("features") or {},
        sort_order=row.get("sort_order") or 0,
    )


def list_plans(conn: Connection[Any] | None) -> list[PlanLimit]:
    """Planes activos ordenados de menor a mayor alcance."""
    rows: list[dict[str, Any]] = []
    if conn is not None:
        try:
            rows = list(
                conn.execute(
                    """
                    select id, name, play_product_id, max_staff, max_locations,
                           max_appointments_per_month,
                           max_online_bookings_per_month,
                           max_messages_per_month,
                           features, sort_order
                    from public.plans
                    where is_active
                    order by sort_order
                    """
                ).fetchall()
            )
        except Exception:  # tabla ausente: se usa el respaldo
            rows = []

    if not rows:
        return [
            _to_limit(plan_id, FALLBACK_PLANS[plan_id]) for plan_id in PLAN_ORDER
        ]
    return [_to_limit(row["id"], row) for row in rows]


def get_plan(conn: Connection[Any] | None, plan_id: str) -> PlanLimit:
    """Plan por id, con respaldo en la configuración por defecto."""
    for plan in list_plans(conn):
        if plan.id == plan_id:
            return plan
    return _to_limit("free", FALLBACK_PLANS["free"])


def plan_for_product(conn: Connection[Any] | None, product_id: str) -> PlanLimit | None:
    """Plan asociado a un producto de Google Play."""
    for plan in list_plans(conn):
        if plan.play_product_id and plan.play_product_id == product_id:
            return plan
    return None


def next_plan(conn: Connection[Any] | None, plan_id: str) -> PlanLimit | None:
    """Siguiente plan superior (para invitar a mejorar)."""
    plans = list_plans(conn)
    ids = [plan.id for plan in plans]
    if plan_id not in ids:
        return plans[0] if plans else None
    index = ids.index(plan_id)
    return plans[index + 1] if index + 1 < len(plans) else None
