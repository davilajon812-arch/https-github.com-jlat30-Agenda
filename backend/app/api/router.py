"""Router raíz de la versión 1 de la API."""

from fastapi import APIRouter

from app.api.routes import (
    account,
    appointments,
    availability,
    billing,
    clients,
    internal,
    me,
    public,
    services,
    staff,
)

api_router = APIRouter()
api_router.include_router(me.router)
api_router.include_router(account.router)
api_router.include_router(services.router)
api_router.include_router(clients.router)
api_router.include_router(staff.router)
api_router.include_router(appointments.router)
api_router.include_router(availability.router)
api_router.include_router(public.router)
api_router.include_router(billing.router)
api_router.include_router(internal.router)
