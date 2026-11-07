"""Validación de los tokens JWT emitidos por Supabase Auth."""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any

import jwt
from jwt import PyJWKClient

from app.core.config import Settings

logger = logging.getLogger(__name__)


class InvalidTokenError(Exception):
    """El token de acceso no es válido, expiró o no se puede verificar."""


@dataclass(frozen=True, slots=True)
class AuthenticatedUser:
    """Usuario autenticado extraído de los claims del JWT."""

    id: str
    email: str | None
    role: str
    claims: dict[str, Any] = field(default_factory=dict)


class SupabaseTokenVerifier:
    """Verifica tokens de Supabase usando secreto HS256 o el JWKS del proyecto."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._jwks_client: PyJWKClient | None = None

        if not settings.supabase_jwt_secret and settings.supabase_url:
            # Proyectos con llaves asimétricas publican su JWKS en Auth.
            self._jwks_client = PyJWKClient(settings.jwks_url, cache_keys=True)

    @property
    def is_configured(self) -> bool:
        """Indica si existe información suficiente para verificar tokens."""
        return bool(self._settings.supabase_jwt_secret or self._jwks_client)

    def verify(self, token: str) -> AuthenticatedUser:
        """Valida el token y devuelve el usuario autenticado."""
        if not token:
            raise InvalidTokenError("Token vacío")

        claims = self._decode(token)

        subject = claims.get("sub")
        if not subject:
            raise InvalidTokenError("El token no identifica a un usuario")

        return AuthenticatedUser(
            id=str(subject),
            email=claims.get("email"),
            role=str(claims.get("role") or "authenticated"),
            claims=claims,
        )

    def _decode(self, token: str) -> dict[str, Any]:
        audience = self._settings.supabase_jwt_audience
        options: dict[str, Any] = {"verify_aud": True}

        try:
            if self._settings.supabase_jwt_secret:
                return jwt.decode(
                    token,
                    self._settings.supabase_jwt_secret,
                    algorithms=["HS256"],
                    audience=audience,
                    options=options,
                )

            if self._jwks_client is None:
                raise InvalidTokenError("Supabase Auth no está configurado en el backend")

            signing_key = self._jwks_client.get_signing_key_from_jwt(token)
            return jwt.decode(
                token,
                signing_key.key,
                algorithms=["RS256", "ES256"],
                audience=audience,
                options=options,
            )
        except jwt.ExpiredSignatureError as exc:
            raise InvalidTokenError("El token expiró") from exc
        except jwt.InvalidTokenError as exc:
            raise InvalidTokenError("Token inválido") from exc
        except InvalidTokenError:
            raise
        except Exception as exc:  # errores de red al descargar el JWKS
            logger.warning("No se pudo obtener el JWKS de Supabase: %s", exc)
            raise InvalidTokenError("No se pudo verificar el token") from exc
