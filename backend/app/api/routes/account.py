"""Eliminación de la cuenta y de todos los datos asociados.

Obligatorio para publicar en Google Play (política de eliminación de cuentas).
El usuario no puede borrarse a sí mismo con el SDK de Supabase, así que el
borrado se hace aquí con la `service_role`.
"""

from __future__ import annotations

import logging
from typing import Annotated, Any

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request, status
from psycopg import Connection

from app.api.deps import get_current_user
from app.core.db import get_connection
from app.core.security import AuthenticatedUser

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/account", tags=["account"])


def _delete_supabase_user(base_url: str, service_role_key: str, user_id: str) -> None:
    """Borra el usuario de Supabase Auth (la cascada borra public.profiles)."""
    try:
        response = httpx.delete(
            f"{base_url.rstrip('/')}/auth/v1/admin/users/{user_id}",
            headers={
                "apikey": service_role_key,
                "Authorization": f"Bearer {service_role_key}",
            },
            timeout=15,
        )
    except httpx.HTTPError as exc:
        logger.exception("No se pudo borrar el usuario %s de Supabase", user_id)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No se pudo eliminar la cuenta, intenta de nuevo",
        ) from exc

    if response.status_code not in (200, 204):
        logger.error(
            "Supabase rechazó el borrado de %s: %s %s",
            user_id,
            response.status_code,
            response.text,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No se pudo eliminar la cuenta, intenta de nuevo",
        )


@router.delete("", summary="Eliminar la cuenta y sus datos")
def delete_account(
    request: Request,
    conn: Annotated[Connection[Any], Depends(get_connection)],
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> dict[str, str]:
    """Borra los negocios que el usuario posee y después su cuenta.

    El orden importa: `businesses.owner_id` es `on delete restrict`, así que el
    perfil no se puede borrar mientras el usuario siga siendo dueño de un
    negocio; y `appointments.client_id` es `restrict`, así que las citas van
    antes que los clientes.

    Los borrados se confirman ANTES de llamar a Supabase Auth: si siguieran en
    una transacción abierta, la cascada a `public.profiles` chocaría con
    `businesses.owner_id` porque la otra conexión no vería el borrado. Si el
    borrado de la cuenta falla, los datos del negocio ya no están y reintentar
    el endpoint termina el trabajo.
    """
    settings = request.app.state.settings
    if not settings.supabase_service_role_key or not settings.supabase_url:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="La eliminación de cuenta no está configurada",
        )

    owned = [
        row["id"]
        for row in conn.execute(
            "select id from public.businesses where owner_id = %s", (user.id,)
        ).fetchall()
    ]

    if owned:
        conn.execute(
            "delete from public.appointments where business_id = any(%s)", (owned,)
        )
        # Cascada: clients, services, staff, horarios, bloqueos, locations,
        # subscriptions, billing_events y business_members.
        conn.execute("delete from public.businesses where id = any(%s)", (owned,))
        conn.commit()

    _delete_supabase_user(
        settings.supabase_url, settings.supabase_service_role_key, user.id
    )

    logger.info("Cuenta eliminada: %s (%s negocios)", user.id, len(owned))
    return {"status": "deleted"}
