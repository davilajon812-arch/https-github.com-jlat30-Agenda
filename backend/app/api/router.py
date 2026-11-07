"""Router raíz de la versión 1 de la API."""

from fastapi import APIRouter

from app.api.routes import me

api_router = APIRouter()
api_router.include_router(me.router)
