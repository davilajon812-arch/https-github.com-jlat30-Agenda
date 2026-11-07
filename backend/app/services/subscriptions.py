"""Estado de la suscripción y reglas de acceso al plan de pago."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone

# Estados que conservan el plan de pago mientras esté vigente.
GRANTING_STATUSES = ("active", "grace")


@dataclass(frozen=True, slots=True)
class SubscriptionSnapshot:
    """Estado de una suscripción leído de la base de datos."""

    plan: str
    status: str
    source: str
    current_period_end: datetime | None = None
    auto_renewing: bool = False
    product_id: str | None = None
    grace_until: datetime | None = None
    latest_event_type: str | None = None


def now_utc() -> datetime:
    """Ahora en UTC (las fechas de Play vienen en UTC)."""
    return datetime.now(tz=timezone.utc)


def grants_paid_plan(snapshot: SubscriptionSnapshot) -> bool:
    """Indica si la suscripción todavía da acceso a su plan de pago.

    Cancelar o pausar la renovación no quita el acceso hasta que termine el
    periodo ya pagado.
    """
    if snapshot.plan == "free":
        return False
    if snapshot.status in GRANTING_STATUSES:
        return True
    if snapshot.status in ("canceled", "paused") and snapshot.current_period_end:
        return snapshot.current_period_end > now_utc()
    return False
