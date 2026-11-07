"""Middleware que valida el JWT de Supabase y deja el usuario en `request.state`."""

from __future__ import annotations

import logging

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import ASGIApp

from app.core.security import InvalidTokenError, SupabaseTokenVerifier

logger = logging.getLogger(__name__)


class SupabaseAuthMiddleware(BaseHTTPMiddleware):
    """Extrae el token Bearer y, si es válido, adjunta el usuario a la petición.

    No bloquea la petición: las rutas protegidas usan la dependencia
    `get_current_user`, que exige un usuario presente en `request.state`.
    """

    def __init__(self, app: ASGIApp, verifier: SupabaseTokenVerifier) -> None:
        super().__init__(app)
        self._verifier = verifier

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        request.state.user = None
        request.state.auth_error = None

        header = request.headers.get("authorization", "")
        if header.lower().startswith("bearer "):
            token = header.split(" ", 1)[1].strip()
            try:
                request.state.user = self._verifier.verify(token)
            except InvalidTokenError as exc:
                request.state.auth_error = str(exc)
                logger.info("Token rechazado en %s: %s", request.url.path, exc)

        return await call_next(request)
