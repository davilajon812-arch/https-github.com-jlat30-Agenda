"""Pruebas del middleware de autenticación con JWT de Supabase."""

from __future__ import annotations

import time
from typing import Any

import jwt
from fastapi.testclient import TestClient

from tests.conftest import TEST_JWT_SECRET


def _token(**overrides: Any) -> str:
    payload: dict[str, Any] = {
        "sub": "11111111-1111-1111-1111-111111111111",
        "email": "dueno@barberia.com",
        "role": "authenticated",
        "aud": "authenticated",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,
    }
    payload.update(overrides)
    return jwt.encode(payload, TEST_JWT_SECRET, algorithm="HS256")


def test_me_sin_token_devuelve_401(client: TestClient) -> None:
    response = client.get("/api/v1/me")

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


def test_me_con_token_valido_devuelve_usuario(client: TestClient) -> None:
    response = client.get(
        "/api/v1/me", headers={"Authorization": f"Bearer {_token()}"}
    )

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == "11111111-1111-1111-1111-111111111111"
    assert body["email"] == "dueno@barberia.com"
    assert body["role"] == "authenticated"


def test_me_con_token_expirado_devuelve_401(client: TestClient) -> None:
    expired = _token(exp=int(time.time()) - 60)

    response = client.get("/api/v1/me", headers={"Authorization": f"Bearer {expired}"})

    assert response.status_code == 401


def test_me_con_firma_invalida_devuelve_401(client: TestClient) -> None:
    forged = jwt.encode(
        {"sub": "x", "aud": "authenticated", "exp": int(time.time()) + 100},
        "otro-secreto-invalido-de-32-bytes-o-mas",
        algorithm="HS256",
    )

    response = client.get("/api/v1/me", headers={"Authorization": f"Bearer {forged}"})

    assert response.status_code == 401


def test_me_con_audiencia_incorrecta_devuelve_401(client: TestClient) -> None:
    wrong_aud = _token(aud="anon")

    response = client.get(
        "/api/v1/me", headers={"Authorization": f"Bearer {wrong_aud}"}
    )

    assert response.status_code == 401
