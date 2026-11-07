"""Empleados, horarios y bloqueos vía API."""

from __future__ import annotations

from fastapi.testclient import TestClient

from tests.api.conftest import STAFF_MEMBER_ID, TEST_WEEKDAY


def test_lista_empleados_con_su_horario(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    empleados = client.get(f"{business_url}/staff", headers=owner_headers).json()

    assert [e["display_name"] for e in empleados] == ["Carlos", "María"]

    horario = client.get(
        f"{business_url}/staff/{STAFF_MEMBER_ID}/schedule", headers=owner_headers
    ).json()
    assert len(horario) == 1
    assert horario[0]["weekday"] == TEST_WEEKDAY
    assert horario[0]["start_time"] == "09:00:00"


def test_solo_el_dueno_crea_empleados(
    client: TestClient, staff_headers: dict[str, str], business_url: str
) -> None:
    response = client.post(
        f"{business_url}/staff", headers=staff_headers, json={"display_name": "Nuevo"}
    )

    assert response.status_code == 403


def test_el_dueno_crea_empleado(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.post(
        f"{business_url}/staff",
        headers=owner_headers,
        json={"display_name": "Ana", "color": "#FF5733"},
    )

    assert response.status_code == 201
    assert response.json()["display_name"] == "Ana"


def test_reemplaza_el_horario_semanal(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.put(
        f"{business_url}/staff/{STAFF_MEMBER_ID}/schedule",
        headers=owner_headers,
        json={
            "slots": [
                {"weekday": 1, "start_time": "08:00", "end_time": "12:00"},
                {"weekday": 1, "start_time": "14:00", "end_time": "18:00"},
            ]
        },
    )

    assert response.status_code == 200
    assert len(response.json()) == 2

    # Se restaura el horario original para no afectar otras pruebas.
    client.put(
        f"{business_url}/staff/{STAFF_MEMBER_ID}/schedule",
        headers=owner_headers,
        json={
            "slots": [
                {"weekday": TEST_WEEKDAY, "start_time": "09:00", "end_time": "12:00"}
            ]
        },
    )


def test_horario_invalido(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.put(
        f"{business_url}/staff/{STAFF_MEMBER_ID}/schedule",
        headers=owner_headers,
        json={"slots": [{"weekday": 1, "start_time": "18:00", "end_time": "09:00"}]},
    )

    assert response.status_code == 422


def test_crear_y_eliminar_bloqueo(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    creado = client.post(
        f"{business_url}/staff/{STAFF_MEMBER_ID}/blocks",
        headers=owner_headers,
        json={
            "starts_at": "2027-03-15T09:00:00-06:00",
            "ends_at": "2027-03-15T12:00:00-06:00",
            "kind": "descanso",
            "reason": "Trámite",
        },
    )
    assert creado.status_code == 201

    listado = client.get(
        f"{business_url}/staff/{STAFF_MEMBER_ID}/blocks", headers=owner_headers
    ).json()
    assert len(listado) == 1
    assert listado[0]["kind"] == "descanso"

    borrado = client.delete(
        f"{business_url}/staff/{STAFF_MEMBER_ID}/blocks/{creado.json()['id']}",
        headers=owner_headers,
    )
    assert borrado.status_code == 204
