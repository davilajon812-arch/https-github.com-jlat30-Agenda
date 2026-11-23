"""API pública de reservas: sin token, limitada por IP.

La usa la página que se comparte con los clientes del negocio. Nada de aquí
expone datos internos: solo los servicios, el personal y los huecos libres.
"""

from __future__ import annotations

from typing import Annotated, Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from psycopg import Connection

from app.core.db import get_connection
from app.core.countries import dial_code
from app.core.ratelimit import BOOKING_LIMITER, READ_LIMITER
from app.schemas.availability import AvailabilityResponse
from app.schemas.public import (
    PublicAppointment,
    PublicBookingCreate,
    PublicBusiness,
    PublicBusinessResponse,
    PublicDayHours,
    PublicService,
    PublicStaff,
)
from app.services import public_booking as booking
from app.services.availability import compute_availability

router = APIRouter(prefix="/public/{slug}", tags=["public"])

ConnectionDep = Annotated[Connection[Any], Depends(get_connection)]


def _client_key(request: Request, slug: str) -> str:
    """IP del visitante (Render la deja en X-Forwarded-For)."""
    forwarded = request.headers.get("x-forwarded-for", "")
    ip = forwarded.split(",")[0].strip() if forwarded else ""
    if not ip and request.client is not None:
        ip = request.client.host
    return f"{ip or 'desconocida'}:{slug}"


def _throttle(limiter: Any, request: Request, slug: str) -> None:
    if not limiter.allow(_client_key(request, slug)):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Demasiados intentos. Espera un minuto y vuelve a probar.",
        )


@router.get(
    "",
    response_model=PublicBusinessResponse,
    summary="Negocio, servicios y personal para el enlace público",
)
def get_business(
    slug: str, request: Request, conn: ConnectionDep
) -> PublicBusinessResponse:
    _throttle(READ_LIMITER, request, slug)

    business = booking.load_business(conn, slug)
    business_id = str(business["id"])

    return PublicBusinessResponse(
        business=PublicBusiness(
            **business, dial_code=dial_code(business.get("country_code"))
        ),
        services=[
            PublicService(**row) for row in booking.list_services(conn, business_id)
        ],
        staff=[PublicStaff(**row) for row in booking.list_staff(conn, business_id)],
        hours=[
            PublicDayHours(**row) for row in booking.business_hours(conn, business_id)
        ],
        bookable=booking.is_bookable(conn, business_id),
        days_ahead=booking.DAYS_AHEAD,
    )


@router.get(
    "/availability",
    response_model=AvailabilityResponse,
    summary="Huecos libres del día",
)
def get_availability(
    slug: str,
    request: Request,
    conn: ConnectionDep,
    service_id: Annotated[UUID, Query()],
    date: Annotated[str, Query(description="Fecha local YYYY-MM-DD")],
    staff_id: Annotated[UUID | None, Query()] = None,
) -> AvailabilityResponse:
    _throttle(READ_LIMITER, request, slug)

    business = booking.load_business(conn, slug)
    return compute_availability(
        conn,
        business_id=str(business["id"]),
        service_id=str(service_id),
        day_value=date,
        staff_id=str(staff_id) if staff_id else None,
    )


@router.post(
    "/appointments",
    response_model=PublicAppointment,
    status_code=status.HTTP_201_CREATED,
    summary="Reservar una cita",
)
def create_appointment(
    slug: str,
    payload: PublicBookingCreate,
    request: Request,
    conn: ConnectionDep,
) -> dict[str, Any]:
    _throttle(BOOKING_LIMITER, request, slug)

    business = booking.load_business(conn, slug)
    return booking.book(conn, business, payload)


@router.get(
    "/appointments/{token}",
    response_model=PublicAppointment,
    summary="Consultar una cita por su token",
)
def get_appointment(
    slug: str, token: str, request: Request, conn: ConnectionDep
) -> dict[str, Any]:
    _throttle(READ_LIMITER, request, slug)

    business = booking.load_business(conn, slug)
    return booking.fetch_by_token(conn, str(business["id"]), token)


@router.post(
    "/appointments/{token}/cancel",
    response_model=PublicAppointment,
    summary="Cancelar la propia cita",
)
def cancel_appointment(
    slug: str, token: str, request: Request, conn: ConnectionDep
) -> dict[str, Any]:
    _throttle(BOOKING_LIMITER, request, slug)

    business = booking.load_business(conn, slug)
    return booking.cancel(conn, str(business["id"]), token)
