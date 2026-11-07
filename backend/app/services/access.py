"""Control de acceso por negocio: el usuario debe ser miembro activo."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from psycopg import Connection

BUSINESS_ADMIN_ROLES = ("owner",)
BUSINESS_STAFF_ROLES = ("owner", "staff")


def get_business_role(
    conn: Connection[Any], user_id: str, business_id: str
) -> str | None:
    """Rol del usuario en el negocio (owner, staff) o None si no es miembro."""
    row = (
        conn.execute(
            """
            select m.role
            from public.business_members m
            where m.business_id = %s
              and m.profile_id = %s
              and m.is_active
            """,
            (business_id, user_id),
        )
    ).fetchone()
    return row["role"] if row else None


def require_member(
    conn: Connection[Any], user_id: str, business_id: str
) -> str:
    """Exige que el usuario pertenezca al negocio y devuelve su rol."""
    role = get_business_role(conn, user_id, business_id)
    if role is None:
        # 404 para no revelar la existencia de negocios ajenos.
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Negocio no encontrado"
        )
    return role


def require_roles(
    conn: Connection[Any], user_id: str, business_id: str, roles: tuple[str, ...]
) -> str:
    """Exige uno de los roles indicados."""
    role = require_member(conn, user_id, business_id)
    if role not in roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tu rol no permite esta acción",
        )
    return role


def require_owner(
    conn: Connection[Any], user_id: str, business_id: str
) -> str:
    """Exige el rol de dueño del negocio."""
    return require_roles(conn, user_id, business_id, BUSINESS_ADMIN_ROLES)
