"""CRUD de clientes con búsqueda e historial de visitas."""

from __future__ import annotations

from typing import Annotated, Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from psycopg import Connection
from psycopg.errors import UniqueViolation

from app.api.deps import get_current_user
from app.core.db import get_connection
from app.core.security import AuthenticatedUser
from app.schemas.clients import (
    ClientCreate,
    ClientHistory,
    ClientRead,
    ClientUpdate,
    ClientVisit,
)
from app.services.access import BUSINESS_STAFF_ROLES, require_member, require_roles

router = APIRouter(prefix="/businesses/{business_id}/clients", tags=["clients"])

CLIENT_COLUMNS = "id, business_id, full_name, phone, notes, created_at, updated_at"

Connection = Annotated[Connection[Any], Depends(get_connection)]
CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_user)]


@router.get("", response_model=list[ClientRead], summary="Listar y buscar clientes")
def list_clients(
    business_id: UUID,
    conn: Connection,
    user: CurrentUser,
    search: Annotated[str | None, Query(max_length=80)] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
) -> list[dict[str, Any]]:
    require_member(conn, user.id, str(business_id))

    query = f"select {CLIENT_COLUMNS} from public.clients where business_id = %s"
    params: list[Any] = [str(business_id)]

    if search and search.strip():
        term = f"%{search.strip()}%"
        query += " and (full_name ilike %s or phone like %s)"
        params.extend([term, term])

    query += " order by full_name limit %s"
    params.append(limit)

    return list((conn.execute(query, params)).fetchall())


@router.post(
    "",
    response_model=ClientRead,
    status_code=status.HTTP_201_CREATED,
    summary="Crear cliente",
)
def create_client(
    business_id: UUID, payload: ClientCreate, conn: Connection, user: CurrentUser
) -> dict[str, Any]:
    require_roles(conn, user.id, str(business_id), BUSINESS_STAFF_ROLES)

    try:
        row = (
            conn.execute(
                f"""
                insert into public.clients (business_id, full_name, phone, notes)
                values (%s, %s, %s, %s)
                returning {CLIENT_COLUMNS}
                """,
                (
                    str(business_id),
                    payload.full_name.strip(),
                    payload.phone.strip(),
                    payload.notes,
                ),
            )
        ).fetchone()
    except UniqueViolation as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un cliente con ese teléfono",
        ) from exc

    assert row is not None
    return row


@router.patch("/{client_id}", response_model=ClientRead, summary="Actualizar cliente")
def update_client(
    business_id: UUID,
    client_id: UUID,
    payload: ClientUpdate,
    conn: Connection,
    user: CurrentUser,
) -> dict[str, Any]:
    require_roles(conn, user.id, str(business_id), BUSINESS_STAFF_ROLES)

    changes = payload.model_dump(exclude_unset=True)
    if not changes:
        return _fetch_client(conn, business_id, client_id)

    assignments = ", ".join(f"{column} = %s" for column in changes)
    values = [*changes.values(), str(client_id), str(business_id)]

    try:
        row = (
            conn.execute(
                f"""
                update public.clients
                set {assignments}
                where id = %s and business_id = %s
                returning {CLIENT_COLUMNS}
                """,
                values,
            )
        ).fetchone()
    except UniqueViolation as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un cliente con ese teléfono",
        ) from exc

    if row is None:
        raise _not_found()
    return row


@router.delete(
    "/{client_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar cliente sin citas",
)
def delete_client(
    business_id: UUID, client_id: UUID, conn: Connection, user: CurrentUser
) -> None:
    require_roles(conn, user.id, str(business_id), BUSINESS_STAFF_ROLES)

    has_appointments = (
        conn.execute(
            "select 1 from public.appointments where client_id = %s limit 1",
            (str(client_id),),
        )
    ).fetchone()
    if has_appointments is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El cliente tiene citas registradas; no se puede eliminar",
        )

    row = (
        conn.execute(
            "delete from public.clients where id = %s and business_id = %s returning id",
            (str(client_id), str(business_id)),
        )
    ).fetchone()
    if row is None:
        raise _not_found()


@router.get(
    "/{client_id}/history",
    response_model=ClientHistory,
    summary="Historial de visitas",
)
def client_history(
    business_id: UUID, client_id: UUID, conn: Connection, user: CurrentUser
) -> ClientHistory:
    require_member(conn, user.id, str(business_id))

    client = _fetch_client(conn, business_id, client_id)

    rows = (
        conn.execute(
            """
            select a.id, a.starts_at, a.ends_at, a.status,
                   s.name as service_name,
                   st.display_name as staff_name,
                   a.price::float8 as price
            from public.appointments a
            left join public.services s on s.id = a.service_id
            left join public.staff_members st on st.id = a.staff_id
            where a.business_id = %s and a.client_id = %s
            order by a.starts_at desc
            limit 50
            """,
            (str(business_id), str(client_id)),
        )
    ).fetchall()

    visits = [
        ClientVisit(
            appointment_id=row["id"],
            starts_at=row["starts_at"],
            ends_at=row["ends_at"],
            status=row["status"],
            service_name=row["service_name"],
            staff_name=row["staff_name"],
            price=row["price"],
        )
        for row in rows
    ]

    completed = [visit for visit in visits if visit.status == "completada"]
    total_spent = sum(visit.price or 0 for visit in completed)
    last_visit = next(
        (visit.starts_at for visit in visits if visit.status == "completada"), None
    )

    return ClientHistory(
        client=ClientRead.model_validate(client),
        visits=visits,
        last_visit_at=last_visit,
        total_visits=len(completed),
        total_spent=round(total_spent, 2),
    )


def _fetch_client(
    conn: Connection[Any], business_id: UUID, client_id: UUID
) -> dict[str, Any]:
    row = (
        conn.execute(
            f"select {CLIENT_COLUMNS} from public.clients "
            "where id = %s and business_id = %s",
            (str(client_id), str(business_id)),
        )
    ).fetchone()
    if row is None:
        raise _not_found()
    return row


def _not_found() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND, detail="Cliente no encontrado"
    )
