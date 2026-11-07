"""Configuración compartida de las pruebas del backend."""

from __future__ import annotations

from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.main import create_app

TEST_JWT_SECRET = "test-jwt-secret-para-pruebas-locales-0123456789"


@pytest.fixture
def test_settings() -> Settings:
    """Configuración de pruebas con verificación HS256 y sin red."""
    return Settings(
        app_env="dev",
        log_level="WARNING",
        cors_origins=["http://localhost:3000"],
        supabase_url="",
        supabase_jwt_secret=TEST_JWT_SECRET,
    )


@pytest.fixture
def client(test_settings: Settings) -> Iterator[TestClient]:
    """Cliente HTTP con la app construida a partir de la configuración de prueba."""
    with TestClient(create_app(test_settings)) as test_client:
        yield test_client
