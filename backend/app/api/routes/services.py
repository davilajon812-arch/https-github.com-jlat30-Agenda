"""CRUD de servicios del negocio."""

from __future__ import annotations

from typing import Annotated, Any
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from psycopg import Connection

from app.api.deps import get_current_user
from app.core.db import get_connection
from app.core.security import AuthenticatedUser
from app.schemas.services import ServiceCreate, ServiceRead, ServiceUpdate
from app.services.access import BUSINESS_STAFF_ROLES, require_member, require_roles

router = APIRouter(prefix="/businesses/{business_id}/services", tags=["services"])

SERVICE_COLUMNS = """
    id, business_id, name, description, duration_minutes,
    price::float8 as price, is_active, created_at, updated_at
"""

Connection = Annotated[Connection[Any], Depends(get_connection)]
CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_user)]


@router.get("", response_model=list[ServiceRead], summary="Listar servicios")
def list_services(
    business_id: UUID,
    conn: Connection,
    user: CurrentUser,
    include_inactive: Annotated[bool, Query()] = False,
) -> list[dict[str, Any]]:
    require_member(conn, user.id, str(business_id))

    query = f"select {SERVICE_COLUMNS} from public.services where business_id = %s"
    params: list[Any] = [str(business_id)]
    if not include_inactive:
        query += " and is_active"
    query += " order by name"

    return list((conn.execute(query, params)).fetchall())


@router.post(
    "",
    response_model=ServiceRead,
    status_code=status.HTTP_201_CREATED,
    summary="Crear servicio",
)
def create_service(
    business_id: UUID, payload: ServiceCreate, conn: Connection, user: CurrentUser
) -> dict[str, Any]:
    require_roles(conn, user.id, str(business_id), BUSINESS_STAFF_ROLES)

    row = (
        conn.execute(
            f"""
            insert into public.services
                (business_id, name, description, duration_minutes, price, is_active)
            values (%s, %s, %s, %s, %s, %s)
            returning {SERVICE_COLUMNS}
            """,
            (
                str(business_id),
                payload.name.strip(),
                payload.description,
                payload.duration_minutes,
                payload.price,
                payload.is_active,
            ),
        )
    ).fetchone()
    assert row is not None
    return row


@router.patch(
    "/{service_id}", response_model=ServiceRead, summary="Actualizar servicio"
)
def update_service(
    business_id: UUID,
    service_id: UUID,
    payload: ServiceUpdate,
    conn: Connection,
    user: CurrentUser,
) -> dict[str, Any]:
    require_roles(conn, user.id, str(business_id), BUSINESS_STAFF_ROLES)

    changes = payload.model_dump(exclude_unset=True)
    if not changes:
        row = (
            conn.execute(
                f"select {SERVICE_COLUMNS} from public.services "
                "where id = %s and business_id = %s",
                (str(service_id), str(business_id)),
            )
        ).fetchone()
        if row is None:
            raise _not_found()
        return row

    assignments = ", ".join(f"{column} = %s" for column in changes)
    values = [*changes.values(), str(service_id), str(business_id)]

    row = (
        conn.execute(
            f"""
            update public.services
            set {assignments}
            where id = %s and business_id = %s
            returning {SERVICE_COLUMNS}
            """,
            values,
        )
    ).fetchone()
    if row is None:
        raise _not_found()
    return row


@router.delete(
    "/{service_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Desactivar servicio",
)
def delete_service(
    business_id: UUID, service_id: UUID, conn: Connection, user: CurrentUser
) -> None:
    """Desactiva el servicio: las citas históricas lo siguen referenciando."""
    require_roles(conn, user.id, str(business_id), BUSINESS_STAFF_ROLES)

    row = (
        conn.execute(
            """
            update public.services set is_active = false
            where id = %s and business_id = %s
            returning id
            """,
            (str(service_id), str(business_id)),
        )
    ).fetchone()
    if row is None:
        raise _not_found()


def _not_found() -> Exception:
    from fastapi import HTTPException

    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado"
    )
