"""Endpoints de facturación: planes, entitlements, verificación y RTDN."""

from __future__ import annotations

import logging
from typing import Annotated, Any
from uuid import UUID

from fastapi import (
    APIRouter,
    Depends,
    Header,
    HTTPException,
    Query,
    Request,
    status,
)
from psycopg import Connection

from app.api.deps import get_current_user
from app.core.db import get_connection
from app.core.security import AuthenticatedUser
from app.schemas.billing import (
    EntitlementsRead,
    PlanRead,
    UsageRead,
    VerifyPurchaseRequest,
)
from app.services import billing, plans
from app.services.access import require_member, require_owner
from app.services.entitlements import (
    LIMIT_APPOINTMENTS,
    LIMIT_LOCATIONS,
    LIMIT_MESSAGES,
    LIMIT_ONLINE_BOOKINGS,
    LIMIT_STAFF,
    load_entitlements,
)

logger = logging.getLogger(__name__)

router = APIRouter(tags=["billing"])

ConnectionDep = Annotated[Connection[Any], Depends(get_connection)]
CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_user)]


def _to_plan_read(plan: plans.PlanLimit) -> PlanRead:
    return PlanRead(
        id=plan.id,
        name=plan.name,
        play_product_id=plan.play_product_id,
        max_staff=plan.max_staff,
        max_locations=plan.max_locations,
        max_appointments_per_month=plan.max_appointments_per_month,
        max_online_bookings_per_month=plan.max_online_bookings_per_month,
        max_messages_per_month=plan.max_messages_per_month,
        features=plan.features,
    )


@router.get("/billing/plans", response_model=list[PlanRead], summary="Catálogo de planes")
def list_plans(conn: ConnectionDep) -> list[PlanRead]:
    """Planes con sus límites. Los precios los entrega Google Play a la app."""
    return [_to_plan_read(plan) for plan in plans.list_plans(conn)]


@router.get(
    "/businesses/{business_id}/entitlements",
    response_model=EntitlementsRead,
    summary="Plan activo y consumo del negocio",
)
def get_entitlements(
    business_id: UUID, conn: ConnectionDep, user: CurrentUser
) -> EntitlementsRead:
    require_member(conn, user.id, str(business_id))
    entitlements = load_entitlements(conn, str(business_id))

    return EntitlementsRead(
        business_id=business_id,
        plan=_to_plan_read(entitlements.plan),
        status=entitlements.subscription.status,
        source=entitlements.subscription.source,
        auto_renewing=entitlements.subscription.auto_renewing,
        current_period_end=(
            entitlements.subscription.current_period_end.isoformat()
            if entitlements.subscription.current_period_end
            else None
        ),
        product_id=entitlements.subscription.product_id,
        usage=UsageRead(
            staff_count=entitlements.usage.staff_count,
            appointments_this_month=entitlements.usage.appointments_this_month,
            messages_this_month=entitlements.usage.messages_this_month,
            online_bookings_this_month=entitlements.usage.online_bookings_this_month,
        ),
        remaining={
            LIMIT_STAFF: entitlements.remaining(LIMIT_STAFF),
            LIMIT_LOCATIONS: entitlements.remaining(LIMIT_LOCATIONS),
            LIMIT_APPOINTMENTS: entitlements.remaining(LIMIT_APPOINTMENTS),
            LIMIT_ONLINE_BOOKINGS: entitlements.remaining(LIMIT_ONLINE_BOOKINGS),
            LIMIT_MESSAGES: entitlements.remaining(LIMIT_MESSAGES),
        },
        upgrade_to=entitlements.upgrade_to,
    )


@router.post(
    "/billing/verify",
    response_model=EntitlementsRead,
    summary="Verificar una compra de Google Play",
)
def verify_purchase(
    payload: VerifyPurchaseRequest, request: Request, conn: ConnectionDep, user: CurrentUser
) -> EntitlementsRead:
    """Verifica la compra con Play, guarda la suscripción y la confirma.

    Solo el dueño del negocio puede activar un plan.
    """
    require_owner(conn, user.id, str(payload.business_id))

    client = getattr(request.app.state, "play_client", None)
    if client is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="La verificación de compras no está configurada",
        )

    billing.verify_purchase(
        conn,
        client,
        business_id=str(payload.business_id),
        product_id=payload.product_id,
        purchase_token=payload.purchase_token,
    )

    return get_entitlements(payload.business_id, conn, user)


@router.post(
    "/billing/rtdn",
    summary="Notificaciones en tiempo real de Google Play (Pub/Sub)",
    include_in_schema=True,
)
def receive_rtdn(
    body: dict[str, Any],
    request: Request,
    conn: ConnectionDep,
    token: Annotated[
        str | None,
        Query(description="Secreto compartido (Pub/Sub no envía cabeceras propias)"),
    ] = None,
    x_agendapro_token: Annotated[
        str | None, Header(alias="X-Citurno-Token")
    ] = None,
) -> dict[str, str]:
    """Procesa renovaciones, cancelaciones, pausas, gracia y reembolsos.

    El secreto puede venir en `?token=` (lo que sí permite configurar la
    suscripción push de Pub/Sub) o en la cabecera `X-Citurno-Token`, útil
    para pruebas manuales.
    """
    settings = request.app.state.settings
    expected = settings.google_pubsub_rtdn_token

    if expected:
        provided = token or x_agendapro_token
        if provided != expected:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token de RTDN inválido",
            )

    notification = billing.decode_pubsub_message(body)
    client = getattr(request.app.state, "play_client", None)
    result = billing.handle_rtdn(conn, client, notification)
    return {"result": result}
