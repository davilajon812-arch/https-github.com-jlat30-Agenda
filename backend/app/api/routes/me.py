"""Ruta de prueba de autenticación: devuelve el usuario del token."""

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.core.security import AuthenticatedUser
from app.schemas.auth import CurrentUserResponse

router = APIRouter(prefix="/me", tags=["auth"])


@router.get("", response_model=CurrentUserResponse, summary="Usuario actual")
async def read_current_user(
    user: AuthenticatedUser = Depends(get_current_user),
) -> CurrentUserResponse:
    """Valida el JWT de Supabase y devuelve la identidad del usuario."""
    return CurrentUserResponse(id=user.id, email=user.email, role=user.role)
