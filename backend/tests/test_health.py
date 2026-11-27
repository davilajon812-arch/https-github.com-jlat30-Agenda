"""Pruebas del endpoint de estado."""

from fastapi.testclient import TestClient


def test_health_responde_ok(client: TestClient) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["service"] == "Citurno API"
    assert body["environment"] == "dev"


def test_health_no_requiere_token(client: TestClient) -> None:
    assert client.get("/health").status_code == 200


def test_cors_permite_origen_configurado(client: TestClient) -> None:
    response = client.get(
        "/health", headers={"Origin": "http://localhost:3000"}
    )

    assert response.headers["access-control-allow-origin"] == "http://localhost:3000"
