"""Punto de entrada de la API de AgendaPro."""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from psycopg_pool import ConnectionPool

from app.api.router import api_router
from app.api.routes import health
from app.core.billing_client import build_play_client
from app.core.config import Settings, get_settings
from app.core.db import DatabaseUnavailableError, close_pool, open_pool
from app.core.logging import configure_logging
from app.core.security import SupabaseTokenVerifier
from app.middleware.auth import SupabaseAuthMiddleware
from app.middleware.request_logging import RequestLoggingMiddleware

logger = logging.getLogger(__name__)


def create_app(app_settings: Settings | None = None) -> FastAPI:
    """Crea la aplicación FastAPI (permite inyectar configuración en pruebas)."""
    settings = app_settings or get_settings()
    configure_logging(settings.log_level)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        pool: ConnectionPool | None = None
        try:
            pool = open_pool(
                settings.database_url,
                settings.database_pool_min_size,
                settings.database_pool_max_size,
            )
        except DatabaseUnavailableError:
            logger.warning(
                "DATABASE_URL sin configurar: los endpoints con base de datos "
                "responderán 503."
            )
        except Exception as exc:  # la API igual arranca: /health debe responder
            logger.error("No se pudo abrir el pool de Postgres: %s", exc)

        app.state.db_pool = pool
        try:
            yield
        finally:
            close_pool(pool)

    application = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="API de agenda de citas para negocios de servicios.",
        docs_url="/docs" if not settings.is_production else None,
        redoc_url="/redoc" if not settings.is_production else None,
        lifespan=lifespan,
    )

    application.state.settings = settings
    application.state.token_verifier = SupabaseTokenVerifier(settings)
    application.state.play_client = build_play_client(settings)

    if not application.state.token_verifier.is_configured:
        logger.warning(
            "Supabase Auth sin configurar: define SUPABASE_URL o SUPABASE_JWT_SECRET "
            "para validar tokens."
        )

    application.add_middleware(
        SupabaseAuthMiddleware, verifier=application.state.token_verifier
    )
    application.add_middleware(RequestLoggingMiddleware)
    # CORS se agrega al final para ser el middleware más externo.
    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    application.include_router(health.router)
    application.include_router(api_router, prefix=settings.api_v1_prefix)

    return application


app = create_app()
