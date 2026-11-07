"""Huecos libres para agendar (lógica de disponibilidad en el backend)."""

from __future__ import annotations

from typing import Annotated, Any
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from psycopg import Connection

from app.api.deps import get_current_user
from app.core.db import get_connection
from app.core.security import AuthenticatedUser
from app.schemas.availability import AvailabilityResponse
from app.services.access import require_member
from app.services.availability import compute_availability

router = APIRouter(prefix="/businesses/{business_id}/availability", tags=["availability"])


@router.get(
    "", response_model=AvailabilityResponse, summary="Huecos libres del día"
)
def get_availability(
    business_id: UUID,
    conn: Annotated[Connection[Any], Depends(get_connection)],
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
    service_id: Annotated[UUID, Query()],
    date: Annotated[str, Query(description="Fecha local YYYY-MM-DD")],
    staff_id: Annotated[UUID | None, Query()] = None,
) -> AvailabilityResponse:
    require_member(conn, user.id, str(business_id))

    return compute_availability(
        conn,
        business_id=str(business_id),
        service_id=str(service_id),
        day_value=date,
        staff_id=str(staff_id) if staff_id else None,
    )
