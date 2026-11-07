"""Clientes: búsqueda, teléfono único e historial de visitas."""

from __future__ import annotations

from fastapi.testclient import TestClient

from tests.api.conftest import CLIENT_ID, SERVICE_ID, STAFF_MEMBER_ID


def test_busca_clientes_por_nombre_y_telefono(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    por_nombre = client.get(
        f"{business_url}/clients?search=uno", headers=owner_headers
    ).json()
    por_telefono = client.get(
        f"{business_url}/clients?search=88880000", headers=owner_headers
    ).json()

    assert [c["full_name"] for c in por_nombre] == ["Cliente Uno"]
    assert [c["full_name"] for c in por_telefono] == ["Cliente Uno"]


def test_no_permite_telefono_repetido(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.post(
        f"{business_url}/clients",
        headers=owner_headers,
        json={"full_name": "Otro", "phone": "50588880000"},
    )

    assert response.status_code == 409


def test_el_ajeno_no_puede_crear_clientes(
    client: TestClient, outsider_headers: dict[str, str], business_url: str
) -> None:
    response = client.post(
        f"{business_url}/clients",
        headers=outsider_headers,
        json={"full_name": "Intruso", "phone": "50577770000"},
    )

    assert response.status_code == 404


def test_historial_de_visitas(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    cita = client.post(
        f"{business_url}/appointments",
        headers=owner_headers,
        json={
            "client_id": CLIENT_ID,
            "service_id": SERVICE_ID,
            "staff_id": STAFF_MEMBER_ID,
            "starts_at": "2027-03-15T09:00:00-06:00",
            "price": 150,
        },
    ).json()
    client.post(
        f"{business_url}/appointments/{cita['id']}/status",
        headers=owner_headers,
        json={"status": "completada"},
    )

    historial = client.get(
        f"{business_url}/clients/{CLIENT_ID}/history", headers=owner_headers
    ).json()

    assert historial["client"]["full_name"] == "Cliente Uno"
    assert len(historial["visits"]) == 1
    assert historial["visits"][0]["service_name"] == "Corte"
    assert historial["visits"][0]["staff_name"] == "Carlos"
    assert historial["total_visits"] == 1
    assert historial["total_spent"] == 150


def test_no_elimina_cliente_con_citas(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    client.post(
        f"{business_url}/appointments",
        headers=owner_headers,
        json={
            "client_id": CLIENT_ID,
            "service_id": SERVICE_ID,
            "starts_at": "2027-03-15T10:00:00-06:00",
        },
    )

    response = client.delete(f"{business_url}/clients/{CLIENT_ID}", headers=owner_headers)

    assert response.status_code == 409
