"""Entitlements: plan activo, límites y consumo del negocio.

Los límites se aplican SIEMPRE aquí (backend). La app solo refleja el estado
para mostrar bloqueos amables.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any

from fastapi import HTTPException, status
from psycopg import Connection

from app.services.plans import PlanLimit, get_plan, next_plan
from app.services.subscriptions import SubscriptionSnapshot, grants_paid_plan, now_utc

# Recursos limitados por plan.
LIMIT_STAFF = "staff"
LIMIT_LOCATIONS = "locations"
LIMIT_APPOINTMENTS = "appointments_per_month"
LIMIT_MESSAGES = "messages_per_month"


@dataclass(frozen=True, slots=True)
class UsageSnapshot:
    """Consumo actual del negocio."""

    staff_count: int
    appointments_this_month: int
    messages_this_month: int


@dataclass(frozen=True, slots=True)
class Entitlements:
    """Plan efectivo del negocio y su consumo."""

    plan: PlanLimit
    subscription: SubscriptionSnapshot
    usage: UsageSnapshot
    upgrade_to: str | None

    @property
    def is_free(self) -> bool:
        return self.plan.id == "free"

    def remaining(self, kind: str) -> int | None:
        """Cupo restante para un recurso; `None` si es ilimitado."""
        limit = self._limit_for(kind)
        if limit is None:
            return None
        used = self._used_for(kind)
        return max(limit - used, 0)

    def _limit_for(self, kind: str) -> int | None:
        return {
            LIMIT_STAFF: self.plan.max_staff,
            LIMIT_LOCATIONS: self.plan.max_locations,
            LIMIT_APPOINTMENTS: self.plan.max_appointments_per_month,
            LIMIT_MESSAGES: self.plan.max_messages_per_month,
        }[kind]

    def _used_for(self, kind: str) -> int:
        return {
            LIMIT_STAFF: self.usage.staff_count,
            LIMIT_LOCATIONS: self.usage.staff_count,  # se ajusta en la Fase 4
            LIMIT_APPOINTMENTS: self.usage.appointments_this_month,
            LIMIT_MESSAGES: self.usage.messages_this_month,
        }[kind]


def _month_bounds(now: datetime) -> tuple[datetime, datetime]:
    start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    if start.month == 12:
        end = start.replace(year=start.year + 1, month=1)
    else:
        end = start.replace(month=start.month + 1)
    return start, end


def _load_subscription(conn: Connection[Any], business_id: str) -> SubscriptionSnapshot:
    row = conn.execute(
        """
        select plan, status, source, current_period_end, auto_renewing,
               product_id, grace_until, latest_event_type
        from public.subscriptions
        where business_id = %s
        order by current_period_end desc nulls last, created_at desc
        limit 1
        """,
        (business_id,),
    ).fetchone()

    if row is None:
        return SubscriptionSnapshot(plan="free", status="active", source="manual")

    return SubscriptionSnapshot(
        plan=row["plan"],
        status=row["status"],
        source=row["source"],
        current_period_end=row["current_period_end"],
        auto_renewing=row["auto_renewing"],
        product_id=row["product_id"],
        grace_until=row["grace_until"],
        latest_event_type=row["latest_event_type"],
    )


def _sync_usage_counter(
    conn: Connection[Any],
    business_id: str,
    start: datetime,
    end: datetime,
    appointments: int,
) -> int:
    """Mantiene `usage_counters` al día y devuelve los mensajes del mes."""
    row = conn.execute(
        """
        insert into public.usage_counters (
            business_id, period_start, period_end, appointments_count, messages_count
        )
        values (%s, %s::date, %s::date, %s, 0)
        on conflict (business_id, period_start) do update
            set appointments_count = excluded.appointments_count
        returning messages_count
        """,
        (business_id, start.date(), end.date(), appointments),
    ).fetchone()
    return row["messages_count"] if row else 0


def load_entitlements(conn: Connection[Any], business_id: str | None) -> Entitlements:
    """Calcula el plan efectivo y el consumo del negocio."""
    if not business_id:
        plan = get_plan(conn, "free")
        return Entitlements(
            plan=plan,
            subscription=SubscriptionSnapshot(plan="free", status="active", source="manual"),
            usage=UsageSnapshot(0, 0, 0),
            upgrade_to=None,
        )

    subscription = _load_subscription(conn, business_id)

    if grants_paid_plan(subscription):
        plan = get_plan(conn, subscription.plan)
    else:
        plan = get_plan(conn, "free")

    staff_row = conn.execute(
        "select count(*) as total from public.staff_members "
        "where business_id = %s and is_active",
        (business_id,),
    ).fetchone()

    start, end = _month_bounds(now_utc())
    appointments_row = conn.execute(
        """
        select count(*) as total
        from public.appointments
        where business_id = %s and created_at >= %s and created_at < %s
        """,
        (business_id, start, end),
    ).fetchone()
    appointments_used = appointments_row["total"] if appointments_row else 0
    messages_used = _sync_usage_counter(
        conn, business_id, start, end, appointments_used
    )

    upgrade = next_plan(conn, plan.id)

    return Entitlements(
        plan=plan,
        subscription=subscription,
        usage=UsageSnapshot(
            staff_count=staff_row["total"] if staff_row else 0,
            appointments_this_month=appointments_used,
            messages_this_month=messages_used,
        ),
        upgrade_to=upgrade.id if upgrade else None,
    )


def plan_limit_error(entitlements: Entitlements, kind: str) -> HTTPException:
    """Error 402 con datos para que la app ofrezca mejorar de plan."""
    return HTTPException(
        status_code=status.HTTP_402_PAYMENT_REQUIRED,
        detail={
            "code": "plan_limit_reached",
            "limit": kind,
            "plan": entitlements.plan.id,
            "upgrade_to": entitlements.upgrade_to,
            "message": "Alcanzaste el límite de tu plan actual",
        },
    )


def ensure_capacity(entitlements: Entitlements, kind: str) -> None:
    """Responde 402 si el negocio ya agotó el cupo del plan."""
    remaining = entitlements.remaining(kind)
    if remaining is not None and remaining <= 0:
        raise plan_limit_error(entitlements, kind)
