"""Control de acceso por negocio: el usuario debe ser miembro activo."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from psycopg import AsyncConnection

BUSINESS_ADMIN_ROLES = ("owner",)
BUSINESS_STAFF_ROLES = ("owner", "staff")


async def get_business_role(
    conn: AsyncConnection[Any], user_id: str, business_id: str
) -> str | None:
    """Rol del usuario en el negocio (owner, staff) o None si no es miembro."""
    row = await (
        await conn.execute(
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


async def require_member(
    conn: AsyncConnection[Any], user_id: str, business_id: str
) -> str:
    """Exige que el usuario pertenezca al negocio y devuelve su rol."""
    role = await get_business_role(conn, user_id, business_id)
    if role is None:
        # 404 para no revelar la existencia de negocios ajenos.
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Negocio no encontrado"
        )
    return role


async def require_roles(
    conn: AsyncConnection[Any], user_id: str, business_id: str, roles: tuple[str, ...]
) -> str:
    """Exige uno de los roles indicados."""
    role = await require_member(conn, user_id, business_id)
    if role not in roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tu rol no permite esta acción",
        )
    return role


async def require_owner(
    conn: AsyncConnection[Any], user_id: str, business_id: str
) -> str:
    """Exige el rol de dueño del negocio."""
    return await require_roles(conn, user_id, business_id, BUSINESS_ADMIN_ROLES)
