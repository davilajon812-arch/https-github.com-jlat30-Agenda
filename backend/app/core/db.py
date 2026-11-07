"""Conexión a Postgres con un pool compartido por la aplicación."""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from typing import Any

from fastapi import HTTPException, Request, status
from psycopg import AsyncConnection
from psycopg.rows import dict_row
from psycopg_pool import AsyncConnectionPool

logger = logging.getLogger(__name__)


class DatabaseUnavailableError(RuntimeError):
    """No hay cadena de conexión configurada."""


async def open_pool(
    database_url: str, min_size: int = 1, max_size: int = 8
) -> AsyncConnectionPool:
    """Abre el pool de conexiones (se llama al iniciar la app)."""
    if not database_url:
        raise DatabaseUnavailableError("DATABASE_URL no está configurada")

    pool = AsyncConnectionPool(
        conninfo=database_url,
        min_size=min_size,
        max_size=max_size,
        kwargs={"row_factory": dict_row, "autocommit": False},
        open=False,
    )
    await pool.open(wait=True, timeout=15)
    logger.info("Pool de Postgres abierto (min=%s, max=%s)", min_size, max_size)
    return pool


async def get_connection(request: Request) -> AsyncIterator[AsyncConnection[Any]]:
    """Dependencia que entrega una conexión del pool y cierra su transacción."""
    pool: AsyncConnectionPool | None = getattr(request.app.state, "db_pool", None)
    if pool is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Base de datos no configurada",
        )

    async with pool.connection() as conn:
        yield conn


async def close_pool(pool: AsyncConnectionPool | None) -> None:
    """Cierra el pool al apagar la aplicación."""
    if pool is not None:
        await pool.close()
