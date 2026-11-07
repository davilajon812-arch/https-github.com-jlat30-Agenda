"""Mantenimiento diario: reconciliar suscripciones y abrir el mes.

Se ejecuta como comando en el cron de Render:

    python -m app.jobs.daily_maintenance

También es invocable desde el endpoint interno
`POST /internal/maintenance/daily` (protegido con MAINTENANCE_TOKEN).
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any

from psycopg import Connection

from app.core.billing_client import build_play_client
from app.core.config import get_settings
from app.core.db import close_pool, open_pool
from app.core.logging import configure_logging
from app.services import billing, plans
from app.services.google_play import GooglePlayClient, PlayError
from app.services.subscriptions import now_utc

logger = logging.getLogger(__name__)


@dataclass
class MaintenanceReport:
    """Resumen de una corrida (se registra y se devuelve por HTTP)."""

    checked: int = 0
    updated: int = 0
    expired: int = 0
    counters_ready: int = 0
    errors: list[str] = field(default_factory=list)

    def as_dict(self) -> dict[str, Any]:
        return {
            "checked": self.checked,
            "updated": self.updated,
            "expired": self.expired,
            "counters_ready": self.counters_ready,
            "errors": self.errors[:20],
        }


def expire_stale(conn: Connection[Any]) -> int:
    """Marca como expiradas las suscripciones cuyo periodo ya terminó."""
    rows = conn.execute(
        """
        update public.subscriptions
        set status = 'expired', last_event_at = now(),
            latest_event_type = 'period_expired'
        where source <> 'manual'
          and status in ('active', 'grace', 'canceled', 'paused')
          and current_period_end is not null
          and current_period_end < now()
        returning id
        """
    ).fetchall()
    return len(rows)


def reopen_month(conn: Connection[Any], now: datetime) -> int:
    """Crea el contador del mes en curso para todos los negocios."""
    start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    end = (start + timedelta(days=32)).replace(day=1)

    rows = conn.execute(
        """
        insert into public.usage_counters
            (business_id, period_start, period_end, appointments_count, messages_count)
        select b.id, %s::date, %s::date, 0, 0
        from public.businesses b
        on conflict (business_id, period_start) do nothing
        returning id
        """,
        (start.date(), end.date()),
    ).fetchall()
    return len(rows)


def reconcile(
    conn: Connection[Any], client: GooglePlayClient | None
) -> MaintenanceReport:
    """Reconsulta en Play cada suscripción de Play todavía viva."""
    report = MaintenanceReport()

    rows = conn.execute(
        """
        select id, business_id, plan, status, product_id, purchase_token
        from public.subscriptions
        where source = 'play'
          and purchase_token is not null
          and status in ('active', 'grace', 'paused', 'canceled')
        """
    ).fetchall()

    for row in rows:
        report.checked += 1
        if client is None:
            report.errors.append("cliente de Play no configurado")
            break

        try:
            purchase = client.get_subscription(
                row["product_id"] or "", row["purchase_token"]
            )
        except PlayError as exc:
            report.errors.append(f"{row['purchase_token'][:8]}: {exc}")
            continue

        plan = plans.plan_for_product(conn, purchase.product_id)
        billing.apply_purchase(
            conn,
            business_id=row["business_id"],
            plan_id=plan.id if plan else row["plan"],
            purchase=purchase,
            purchase_token=row["purchase_token"],
            event_type="reconciled",
        )
        report.updated += 1

        if purchase.status == "expired":
            report.expired += 1

    report.expired += expire_stale(conn)
    report.counters_ready = reopen_month(conn, now_utc())

    conn.execute(
        """
        insert into public.billing_events (source, event_type, payload)
        values ('play', 'daily_maintenance', %s::jsonb)
        """,
        (json.dumps(report.as_dict()),),
    )

    return report


def run() -> MaintenanceReport:
    """Abre el pool, corre el mantenimiento y lo cierra."""
    settings = get_settings()
    configure_logging(settings.log_level)

    pool = open_pool(
        settings.database_url,
        settings.database_pool_min_size,
        settings.database_pool_max_size,
    )
    client = build_play_client(settings)

    try:
        with pool.connection() as conn:
            report = reconcile(conn, client)
            conn.commit()
    finally:
        close_pool(pool)

    logger.info("Mantenimiento diario: %s", report.as_dict())
    return report


if __name__ == "__main__":
    run()
