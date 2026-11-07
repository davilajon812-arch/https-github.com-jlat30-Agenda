"""Conexion a Postgres con un pool compartido por la aplicacion.

Se usa psycopg sincrono: FastAPI ejecuta los endpoints `def` en un hilo del
threadpool, asi el mismo codigo funciona en Linux (Render) y en Windows, donde
el event loop Proactor no es compatible con psycopg async.
"""

from __future__ import annotations

import logging
from collections.abc import Iterator
from typing import Any

from fastapi import HTTPException, Request, status
from psycopg import Connection
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

logger = logging.getLogger(__name__)


class DatabaseUnavailableError(RuntimeError):
    """No hay cadena de conexion configurada."""


def open_pool(
    database_url: str, min_size: int = 1, max_size: int = 8
) -> ConnectionPool:
    """Abre el pool de conexiones (se llama al iniciar la app)."""
    if not database_url:
        raise DatabaseUnavailableError("DATABASE_URL no esta configurada")

    pool = ConnectionPool(
        conninfo=database_url,
        min_size=min_size,
        max_size=max_size,
        kwargs={"row_factory": dict_row, "autocommit": False},
        open=False,
    )
    pool.open(wait=True, timeout=15)
    logger.info("Pool de Postgres abierto (min=%s, max=%s)", min_size, max_size)
    return pool


def get_connection(request: Request) -> Iterator[Connection[Any]]:
    """Dependencia que entrega una conexion del pool y cierra su transaccion."""
    pool: ConnectionPool | None = getattr(request.app.state, "db_pool", None)
    if pool is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Base de datos no configurada",
        )

    with pool.connection() as conn:
        yield conn


def close_pool(pool: ConnectionPool | None) -> None:
    """Cierra el pool al apagar la aplicacion."""
    if pool is not None:
        pool.close()
