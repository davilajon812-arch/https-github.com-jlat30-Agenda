"""CRUD de servicios vía API."""

from __future__ import annotations

from fastapi.testclient import TestClient

from tests.api.conftest import SERVICE_ID


def test_lista_servicios_del_negocio(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.get(f"{business_url}/services", headers=owner_headers)

    assert response.status_code == 200
    servicios = response.json()
    assert [s["name"] for s in servicios] == ["Corte"]
    assert servicios[0]["duration_minutes"] == 30
    assert servicios[0]["price"] == 150


def test_un_ajeno_no_puede_ver_los_servicios(
    client: TestClient, outsider_headers: dict[str, str], business_url: str
) -> None:
    response = client.get(f"{business_url}/services", headers=outsider_headers)

    assert response.status_code == 404


def test_el_empleado_puede_crear_un_servicio(
    client: TestClient, staff_headers: dict[str, str], business_url: str
) -> None:
    response = client.post(
        f"{business_url}/services",
        headers=staff_headers,
        json={"name": "Barba", "duration_minutes": 20, "price": 80},
    )

    assert response.status_code == 201
    assert response.json()["name"] == "Barba"


def test_validacion_de_duracion(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.post(
        f"{business_url}/services",
        headers=owner_headers,
        json={"name": "Rápido", "duration_minutes": 1},
    )

    assert response.status_code == 422


def test_actualizar_servicio(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.patch(
        f"{business_url}/services/{SERVICE_ID}",
        headers=owner_headers,
        json={"price": 200},
    )

    assert response.status_code == 200
    assert response.json()["price"] == 200


def test_borrar_servicio_lo_desactiva(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    created = client.post(
        f"{business_url}/services",
        headers=owner_headers,
        json={"name": "Temporal"},
    ).json()

    delete = client.delete(
        f"{business_url}/services/{created['id']}", headers=owner_headers
    )
    assert delete.status_code == 204

    activos = client.get(f"{business_url}/services", headers=owner_headers).json()
    assert created["id"] not in [item["id"] for item in activos]

    todos = client.get(
        f"{business_url}/services?include_inactive=true", headers=owner_headers
    ).json()
    assert created["id"] in [item["id"] for item in todos]
