"""Empleados, horarios semanales y bloqueos."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from psycopg import Connection
from psycopg.errors import UniqueViolation

from app.api.deps import get_current_user
from app.core.db import get_connection
from app.core.security import AuthenticatedUser
from app.core.timeutils import parse_datetime
from app.schemas.staff import (
    BlockCreate,
    BlockRead,
    ScheduleReplace,
    StaffCreate,
    StaffRead,
    StaffScheduleRead,
    StaffUpdate,
)
from app.services.access import (
    BUSINESS_STAFF_ROLES,
    require_member,
    require_owner,
    require_roles,
)

router = APIRouter(prefix="/businesses/{business_id}/staff", tags=["staff"])

STAFF_COLUMNS = (
    "id, business_id, profile_id, display_name, phone, color, is_active, "
    "created_at, updated_at"
)

Connection = Annotated[Connection[Any], Depends(get_connection)]
CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_user)]


@router.get("", response_model=list[StaffRead], summary="Listar empleados")
def list_staff(
    business_id: UUID,
    conn: Connection,
    user: CurrentUser,
    include_inactive: Annotated[bool, Query()] = False,
) -> list[dict[str, Any]]:
    require_member(conn, user.id, str(business_id))

    query = f"select {STAFF_COLUMNS} from public.staff_members where business_id = %s"
    params: list[Any] = [str(business_id)]
    if not include_inactive:
        query += " and is_active"
    query += " order by display_name"

    return list((conn.execute(query, params)).fetchall())


@router.post(
    "",
    response_model=StaffRead,
    status_code=status.HTTP_201_CREATED,
    summary="Crear empleado",
)
def create_staff(
    business_id: UUID, payload: StaffCreate, conn: Connection, user: CurrentUser
) -> dict[str, Any]:
    require_owner(conn, user.id, str(business_id))

    try:
        row = (
            conn.execute(
                f"""
                insert into public.staff_members
                    (business_id, profile_id, display_name, phone, color, is_active)
                values (%s, %s, %s, %s, %s, %s)
                returning {STAFF_COLUMNS}
                """,
                (
                    str(business_id),
                    str(payload.profile_id) if payload.profile_id else None,
                    payload.display_name.strip(),
                    payload.phone,
                    payload.color,
                    payload.is_active,
                ),
            )
        ).fetchone()
    except UniqueViolation as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ese usuario ya es empleado del negocio",
        ) from exc

    assert row is not None
    return row


@router.patch("/{staff_id}", response_model=StaffRead, summary="Actualizar empleado")
def update_staff(
    business_id: UUID,
    staff_id: UUID,
    payload: StaffUpdate,
    conn: Connection,
    user: CurrentUser,
) -> dict[str, Any]:
    require_owner(conn, user.id, str(business_id))

    changes = payload.model_dump(exclude_unset=True)
    if "profile_id" in changes and changes["profile_id"] is not None:
        changes["profile_id"] = str(changes["profile_id"])

    if not changes:
        return _fetch_staff(conn, business_id, staff_id)

    assignments = ", ".join(f"{column} = %s" for column in changes)
    values = [*changes.values(), str(staff_id), str(business_id)]

    row = (
        conn.execute(
            f"""
            update public.staff_members
            set {assignments}
            where id = %s and business_id = %s
            returning {STAFF_COLUMNS}
            """,
            values,
        )
    ).fetchone()
    if row is None:
        raise _not_found()
    return row


@router.delete(
    "/{staff_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Desactivar empleado",
)
def delete_staff(
    business_id: UUID, staff_id: UUID, conn: Connection, user: CurrentUser
) -> None:
    require_owner(conn, user.id, str(business_id))

    row = (
        conn.execute(
            """
            update public.staff_members set is_active = false
            where id = %s and business_id = %s
            returning id
            """,
            (str(staff_id), str(business_id)),
        )
    ).fetchone()
    if row is None:
        raise _not_found()


@router.get(
    "/{staff_id}/schedule",
    response_model=list[StaffScheduleRead],
    summary="Horario semanal",
)
def get_schedule(
    business_id: UUID, staff_id: UUID, conn: Connection, user: CurrentUser
) -> list[dict[str, Any]]:
    require_member(conn, user.id, str(business_id))
    _fetch_staff(conn, business_id, staff_id)

    rows = (
        conn.execute(
            """
            select id, business_id, staff_id, weekday, start_time, end_time,
                   location_id
            from public.staff_schedules
            where staff_id = %s and is_active
            order by weekday, start_time
            """,
            (str(staff_id),),
        )
    ).fetchall()
    return list(rows)


@router.put(
    "/{staff_id}/schedule",
    response_model=list[StaffScheduleRead],
    summary="Reemplazar horario semanal",
)
def replace_schedule(
    business_id: UUID,
    staff_id: UUID,
    payload: ScheduleReplace,
    conn: Connection,
    user: CurrentUser,
) -> list[dict[str, Any]]:
    require_owner(conn, user.id, str(business_id))
    _fetch_staff(conn, business_id, staff_id)

    for slot in payload.slots:
        if slot.end_time <= slot.start_time:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="La hora de fin debe ser posterior a la de inicio",
            )

    conn.execute(
        "delete from public.staff_schedules where staff_id = %s", (str(staff_id),)
    )

    for slot in payload.slots:
        conn.execute(
            """
            insert into public.staff_schedules
                (business_id, staff_id, location_id, weekday, start_time, end_time)
            values (%s, %s, %s, %s, %s, %s)
            """,
            (
                str(business_id),
                str(staff_id),
                str(slot.location_id) if slot.location_id else None,
                slot.weekday,
                slot.start_time,
                slot.end_time,
            ),
        )

    return get_schedule(business_id, staff_id, conn, user)


@router.get(
    "/{staff_id}/blocks", response_model=list[BlockRead], summary="Listar bloqueos"
)
def list_blocks(
    business_id: UUID,
    staff_id: UUID,
    conn: Connection,
    user: CurrentUser,
    starts_from: Annotated[datetime | None, Query()] = None,
    starts_to: Annotated[datetime | None, Query()] = None,
) -> list[dict[str, Any]]:
    require_member(conn, user.id, str(business_id))
    _fetch_staff(conn, business_id, staff_id)

    query = """
        select id, business_id, staff_id, starts_at, ends_at, kind, reason
        from public.staff_blocks
        where staff_id = %s
    """
    params: list[Any] = [str(staff_id)]
    if starts_from is not None:
        query += " and ends_at >= %s"
        params.append(starts_from)
    if starts_to is not None:
        query += " and starts_at <= %s"
        params.append(starts_to)
    query += " order by starts_at"

    return list((conn.execute(query, params)).fetchall())


@router.post(
    "/{staff_id}/blocks",
    response_model=BlockRead,
    status_code=status.HTTP_201_CREATED,
    summary="Crear bloqueo",
)
def create_block(
    business_id: UUID,
    staff_id: UUID,
    payload: BlockCreate,
    conn: Connection,
    user: CurrentUser,
) -> dict[str, Any]:
    require_member(conn, user.id, str(business_id))
    _require_staff_writer(conn, user.id, business_id)

    _fetch_staff(conn, business_id, staff_id)

    starts_at = parse_datetime(payload.starts_at, "starts_at")
    ends_at = parse_datetime(payload.ends_at, "ends_at")
    if ends_at <= starts_at:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="ends_at debe ser posterior a starts_at",
        )

    row = (
        conn.execute(
            """
            insert into public.staff_blocks
                (business_id, staff_id, starts_at, ends_at, kind, reason)
            values (%s, %s, %s, %s, %s, %s)
            returning id, business_id, staff_id, starts_at, ends_at, kind, reason
            """,
            (
                str(business_id),
                str(staff_id),
                starts_at,
                ends_at,
                payload.kind,
                payload.reason,
            ),
        )
    ).fetchone()
    assert row is not None
    return row


@router.delete(
    "/{staff_id}/blocks/{block_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar bloqueo",
)
def delete_block(
    business_id: UUID,
    staff_id: UUID,
    block_id: UUID,
    conn: Connection,
    user: CurrentUser,
) -> None:
    _require_staff_writer(conn, user.id, business_id)

    row = (
        conn.execute(
            "delete from public.staff_blocks where id = %s and staff_id = %s returning id",
            (str(block_id), str(staff_id)),
        )
    ).fetchone()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Bloqueo no encontrado"
        )


def _require_staff_writer(
    conn: Connection[Any], user_id: str, business_id: UUID
) -> str:
    """Dueño y empleados pueden gestionar bloqueos de su negocio."""
    return require_roles(conn, user_id, str(business_id), BUSINESS_STAFF_ROLES)


def _fetch_staff(
    conn: Connection[Any], business_id: UUID, staff_id: UUID
) -> dict[str, Any]:
    row = (
        conn.execute(
            f"select {STAFF_COLUMNS} from public.staff_members "
            "where id = %s and business_id = %s",
            (str(staff_id), str(business_id)),
        )
    ).fetchone()
    if row is None:
        raise _not_found()
    return row


def _not_found() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND, detail="Empleado no encontrado"
    )
