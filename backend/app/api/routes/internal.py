"""Endpoints internos para tareas programadas."""

from __future__ import annotations

import logging
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from psycopg import Connection

from app.core.db import get_connection
from app.jobs import daily_maintenance

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/internal", tags=["internal"])


@router.post("/maintenance/daily", summary="Ejecutar el mantenimiento diario")
def run_daily_maintenance(
    request: Request,
    conn: Annotated[Connection[Any], Depends(get_connection)],
    x_maintenance_token: Annotated[
        str | None, Header(alias="X-Maintenance-Token")
    ] = None,
) -> dict[str, Any]:
    """Alternativa al cron cuando no se puede ejecutar un comando.

    Requiere `MAINTENANCE_TOKEN`; si no está configurado responde 503 para no
    dejar la tarea abierta.
    """
    expected = request.app.state.settings.maintenance_token
    if not expected:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="MAINTENANCE_TOKEN no está configurado",
        )
    if x_maintenance_token != expected:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido"
        )

    client = getattr(request.app.state, "play_client", None)
    report = daily_maintenance.reconcile(conn, client)
    return report.as_dict()
