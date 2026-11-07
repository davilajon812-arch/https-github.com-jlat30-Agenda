"""Dependencias reutilizables de las rutas."""

from __future__ import annotations

from fastapi import HTTPException, Request, status

from app.core.security import AuthenticatedUser


def get_current_user(request: Request) -> AuthenticatedUser:
    """Devuelve el usuario autenticado o responde 401."""
    user: AuthenticatedUser | None = getattr(request.state, "user", None)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Autenticación requerida",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


def get_optional_user(request: Request) -> AuthenticatedUser | None:
    """Devuelve el usuario si el token es válido; si no, `None`."""
    return getattr(request.state, "user", None)
