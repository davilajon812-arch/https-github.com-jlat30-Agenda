"""Reglas de facturación: verificación de compras, RTDN y auditoría."""

from __future__ import annotations

import json
import logging
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException, status
from psycopg import Connection

from app.services import plans as plans_service
from app.services.google_play import GooglePlayClient, PlayError, PlaySubscription
from app.services.subscriptions import SubscriptionSnapshot, now_utc

logger = logging.getLogger(__name__)

# Tipos de notificación RTDN de Google Play.
RTDN_TYPES = {
    1: "SUBSCRIPTION_RECOVERED",
    2: "SUBSCRIPTION_RENEWED",
    3: "SUBSCRIPTION_CANCELED",
    4: "SUBSCRIPTION_PURCHASED",
    5: "SUBSCRIPTION_ON_HOLD",
    6: "SUBSCRIPTION_IN_GRACE_PERIOD",
    7: "SUBSCRIPTION_RESTARTED",
    8: "SUBSCRIPTION_PRICE_CHANGE_CONFIRMED",
    9: "SUBSCRIPTION_DEFERRED",
    10: "SUBSCRIPTION_PAUSED",
    11: "SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED",
    12: "SUBSCRIPTION_REVOKED",
    13: "SUBSCRIPTION_EXPIRED",
    20: "SUBSCRIPTION_PENDING_PURCHASE_CANCELED",
}

# Respaldo: si no se puede consultar Play, el estado se deduce del tipo.
RTDN_FALLBACK_STATUS = {
    "SUBSCRIPTION_RECOVERED": "active",
    "SUBSCRIPTION_RENEWED": "active",
    "SUBSCRIPTION_PURCHASED": "active",
    "SUBSCRIPTION_RESTARTED": "active",
    "SUBSCRIPTION_CANCELED": "canceled",
    "SUBSCRIPTION_ON_HOLD": "grace",
    "SUBSCRIPTION_IN_GRACE_PERIOD": "grace",
    "SUBSCRIPTION_PAUSED": "paused",
    "SUBSCRIPTION_REVOKED": "expired",
    "SUBSCRIPTION_EXPIRED": "expired",
    "SUBSCRIPTION_PENDING_PURCHASE_CANCELED": "canceled",
}


def log_event(
    conn: Connection[Any],
    *,
    event_type: str,
    business_id: str | None = None,
    product_id: str | None = None,
    purchase_token: str | None = None,
    payload: dict[str, Any] | None = None,
    source: str = "play",
) -> None:
    """Guarda un evento de facturación para auditoría."""
    conn.execute(
        """
        insert into public.billing_events
            (business_id, source, event_type, product_id, purchase_token, payload)
        values (%s, %s, %s, %s, %s, %s)
        """,
        (
            business_id,
            source,
            event_type,
            product_id,
            purchase_token,
            json.dumps(payload or {}, default=str),
        ),
    )


def _period_bounds(purchase: PlaySubscription) -> tuple[datetime, datetime]:
    """Inicio y fin del periodo vigente (fin viene de Play)."""
    end = purchase.expires_at or (now_utc() + timedelta(days=30))
    start = end - timedelta(days=30)
    return start, end


def apply_purchase(
    conn: Connection[Any],
    *,
    business_id: str,
    plan_id: str,
    purchase: PlaySubscription,
    purchase_token: str,
    event_type: str,
    source: str = "play",
) -> None:
    """Crea o actualiza la suscripción del negocio con el estado de Play."""
    start, end = _period_bounds(purchase)
    grace_until = (
        now_utc() + timedelta(days=7) if purchase.status == "grace" else None
    )

    existing = conn.execute(
        """
        select id from public.subscriptions
        where business_id = %s
        order by (source = %s) desc, (plan = 'free') desc, created_at desc
        limit 1
        """,
        (business_id, source),
    ).fetchone()

    values = (
        plan_id,
        purchase.status,
        purchase.product_id,
        purchase_token,
        start,
        end,
        purchase.auto_renewing,
        now_utc(),
        purchase.order_id,
        purchase.obfuscated_account_id,
        event_type,
        purchase.raw_state,
        now_utc() if purchase.acknowledged else None,
        grace_until,
        now_utc() if purchase.status in ("canceled", "expired") else None,
    )

    if existing:
        conn.execute(
            """
            update public.subscriptions
            set plan = %s, status = %s, product_id = %s, purchase_token = %s,
                current_period_start = %s, current_period_end = %s,
                auto_renewing = %s, last_event_at = %s, google_order_id = %s,
                external_account_id = %s, latest_event_type = %s, raw_status = %s,
                acknowledged_at = coalesce(%s, acknowledged_at),
                grace_until = %s, canceled_at = %s, source = %s
            where id = %s
            """,
            (*values, source, existing["id"]),
        )
    else:
        conn.execute(
            """
            insert into public.subscriptions (
                business_id, plan, status, product_id, purchase_token,
                current_period_start, current_period_end, auto_renewing,
                last_event_at, google_order_id, external_account_id,
                latest_event_type, raw_status, acknowledged_at, grace_until,
                canceled_at, source
            )
            values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (business_id, *values, source),
        )


def verify_purchase(
    conn: Connection[Any],
    client: GooglePlayClient,
    *,
    business_id: str,
    product_id: str,
    purchase_token: str,
) -> SubscriptionSnapshot:
    """Valida la compra con Play, guarda la suscripción y la confirma."""
    plan = plans_service.plan_for_product(conn, product_id)
    if plan is None:
        log_event(
            conn,
            event_type="verify_rejected",
            business_id=business_id,
            product_id=product_id,
            purchase_token=purchase_token,
            payload={"reason": "producto desconocido"},
        )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El producto no corresponde a ningún plan",
        )

    try:
        purchase = client.get_subscription(product_id, purchase_token)
    except PlayError as exc:
        log_event(
            conn,
            event_type="verify_failed",
            business_id=business_id,
            product_id=product_id,
            purchase_token=purchase_token,
            payload={"error": str(exc)},
        )
        raise HTTPException(status_code=exc.status_code, detail=str(exc)) from exc

    if purchase.status not in ("active", "grace"):
        log_event(
            conn,
            event_type="verify_rejected",
            business_id=business_id,
            product_id=product_id,
            purchase_token=purchase_token,
            payload={"status": purchase.status, "raw": purchase.raw_state},
        )
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"La suscripción no está vigente ({purchase.raw_state})",
        )

    apply_purchase(
        conn,
        business_id=business_id,
        plan_id=plan.id,
        purchase=purchase,
        purchase_token=purchase_token,
        event_type="verify_ok",
    )

    # Acknowledge solo después de guardar: si falla, Play reembolsa a los 3 días.
    acknowledged = purchase.acknowledged
    if not purchase.acknowledged:
        try:
            client.acknowledge(product_id, purchase_token)
            acknowledged = True
            conn.execute(
                "update public.subscriptions set acknowledged_at = now() "
                "where purchase_token = %s",
                (purchase_token,),
            )
        except PlayError as exc:
            logger.warning("No se pudo confirmar la compra: %s", exc)

    log_event(
        conn,
        event_type="purchase_verified",
        business_id=business_id,
        product_id=product_id,
        purchase_token=purchase_token,
        payload={
            "plan": plan.id,
            "status": purchase.status,
            "acknowledged": acknowledged,
            "expires_at": purchase.expires_at,
        },
    )

    return SubscriptionSnapshot(
        plan=plan.id,
        status=purchase.status,
        source="play",
        current_period_end=purchase.expires_at,
        auto_renewing=purchase.auto_renewing,
        product_id=product_id,
        latest_event_type="verify_ok",
    )


def handle_rtdn(
    conn: Connection[Any],
    client: GooglePlayClient | None,
    notification: dict[str, Any],
) -> str:
    """Procesa una notificación RTDN y actualiza la suscripción.

    Devuelve una etiqueta con el resultado para registrarla en la respuesta.
    """
    subscription = notification.get("subscriptionNotification") or {}
    notification_type = int(subscription.get("notificationType") or 0)
    purchase_token = subscription.get("purchaseToken")
    product_id = subscription.get("subscriptionId")
    event_name = RTDN_TYPES.get(notification_type, f"UNKNOWN_{notification_type}")

    if not purchase_token:
        log_event(conn, event_type="rtdn_invalid", payload=notification)
        return "ignored"

    row = conn.execute(
        """
        select id, business_id, plan, product_id, current_period_end, auto_renewing
        from public.subscriptions
        where purchase_token = %s
        limit 1
        """,
        (purchase_token,),
    ).fetchone()

    if row is None:
        # Compra de un negocio que aún no verificó: se registra para auditoría.
        log_event(
            conn,
            event_type=f"rtdn_{event_name}",
            product_id=product_id,
            purchase_token=purchase_token,
            payload={"reason": "token desconocido", "notification": notification},
        )
        return "unknown_token"

    business_id = row["business_id"]

    # Play es la fuente de verdad: se reconsulta el estado real.
    purchase: PlaySubscription | None = None
    if client is not None:
        try:
            purchase = client.get_subscription(
                product_id or row["product_id"] or "", purchase_token
            )
        except PlayError as exc:
            logger.warning("RTDN sin verificación en línea: %s", exc)

    if purchase is None:
        fallback_status = RTDN_FALLBACK_STATUS.get(event_name)
        if fallback_status is None:
            log_event(
                conn,
                event_type=f"rtdn_{event_name}",
                business_id=business_id,
                product_id=product_id,
                purchase_token=purchase_token,
                payload={"notification": notification, "applied": False},
            )
            return "logged"

        plan_id = row["plan"]
        conn.execute(
            """
            update public.subscriptions
            set status = %s, last_event_at = now(), latest_event_type = %s,
                grace_until = case when %s = 'grace'
                    then now() + interval '7 days' else grace_until end,
                canceled_at = case when %s in ('canceled', 'expired')
                    then now() else canceled_at end
            where id = %s
            """,
            (fallback_status, event_name, fallback_status, fallback_status, row["id"]),
        )
    else:
        plan_id = plans_service.plan_for_product(conn, purchase.product_id)
        apply_purchase(
            conn,
            business_id=business_id,
            plan_id=plan_id.id if plan_id else row["plan"],
            purchase=purchase,
            purchase_token=purchase_token,
            event_type=f"rtdn_{event_name}",
        )

    log_event(
        conn,
        event_type=f"rtdn_{event_name}",
        business_id=business_id,
        product_id=product_id,
        purchase_token=purchase_token,
        payload={
            "notification": notification,
            "applied": True,
            "verified": purchase is not None,
        },
    )
    return "applied"


def decode_pubsub_message(body: dict[str, Any]) -> dict[str, Any]:
    """Extrae y decodifica el mensaje base64 de una notificación Pub/Sub."""
    import base64

    message = body.get("message") or {}
    data = message.get("data")
    if not data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Notificación sin datos",
        )

    try:
        decoded = base64.b64decode(data).decode("utf-8")
        parsed = json.loads(decoded)
    except Exception as exc:  # base64 o JSON inválidos
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Notificación mal formada",
        ) from exc

    if not isinstance(parsed, dict):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Notificación mal formada"
        )
    return parsed


def utc_now() -> datetime:
    """Alias para mantener legible el código de las tareas programadas."""
    return datetime.now(tz=timezone.utc)
