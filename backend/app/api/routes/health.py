"""Endpoint de estado del servicio."""

from fastapi import APIRouter, Request

from app.core.config import Settings
from app.schemas.common import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse, summary="Estado del servicio")
async def health(request: Request) -> HealthResponse:
    """Devuelve 200 cuando el servicio está en línea (usado por Render)."""
    settings: Settings = request.app.state.settings
    return HealthResponse(
        status="ok",
        service=settings.app_name,
        version=settings.app_version,
        environment=settings.app_env,
    )
