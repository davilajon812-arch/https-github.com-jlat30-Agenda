"""Citas: creación, choques de horario, agenda y estados."""

from __future__ import annotations

from fastapi.testclient import TestClient

from tests.api.conftest import CLIENT_ID, SERVICE_ID, STAFF_MEMBER_ID


def _appointment(**overrides: object) -> dict[str, object]:
    payload: dict[str, object] = {
        "client_id": CLIENT_ID,
        "service_id": SERVICE_ID,
        "staff_id": STAFF_MEMBER_ID,
        "starts_at": "2027-03-15T09:00:00-06:00",
    }
    payload.update(overrides)
    return payload


def test_crea_cita_y_calcula_fin_con_el_servicio(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.post(
        f"{business_url}/appointments",
        headers=owner_headers,
        json=_appointment(price=150),
    )

    assert response.status_code == 201
    cita = response.json()
    assert cita["status"] == "pendiente"
    assert cita["client_name"] == "Cliente Uno"
    assert cita["service_name"] == "Corte"
    assert cita["staff_name"] == "Carlos"
    assert cita["ends_at"] == "2027-03-15T15:30:00Z"  # 09:30 en UTC-6
    assert cita["price"] == 150


def test_rechaza_choque_de_horario(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    client.post(
        f"{business_url}/appointments", headers=owner_headers, json=_appointment()
    )

    response = client.post(
        f"{business_url}/appointments",
        headers=owner_headers,
        json=_appointment(starts_at="2027-03-15T09:15:00-06:00"),
    )

    assert response.status_code == 409
    assert "horario" in response.json()["detail"]


def test_permite_citas_simultaneas_de_empleados_distintos(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    client.post(
        f"{business_url}/appointments", headers=owner_headers, json=_appointment()
    )
    otro = client.post(
        f"{business_url}/appointments",
        headers=owner_headers,
        json=_appointment(starts_at="2027-03-15T10:00:00-06:00"),
    )

    assert otro.status_code == 201


def test_rechaza_cita_dentro_de_un_bloqueo(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    client.post(
        f"{business_url}/staff/{STAFF_MEMBER_ID}/blocks",
        headers=owner_headers,
        json={
            "starts_at": "2027-03-15T09:00:00-06:00",
            "ends_at": "2027-03-15T11:00:00-06:00",
        },
    )

    response = client.post(
        f"{business_url}/appointments", headers=owner_headers, json=_appointment()
    )

    assert response.status_code == 409
    assert "bloqueo" in response.json()["detail"]


def test_agenda_por_rango(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    client.post(
        f"{business_url}/appointments",
        headers=owner_headers,
        json=_appointment(starts_at="2027-03-15T09:00:00-06:00"),
    )
    client.post(
        f"{business_url}/appointments",
        headers=owner_headers,
        json=_appointment(starts_at="2027-03-16T09:00:00-06:00"),
    )

    un_dia = client.get(
        f"{business_url}/appointments"
        "?from=2027-03-15T00:00:00-06:00&to=2027-03-15T23:59:59-06:00",
        headers=owner_headers,
    ).json()
    semana = client.get(
        f"{business_url}/appointments"
        "?from=2027-03-15T00:00:00-06:00&to=2027-03-21T23:59:59-06:00",
        headers=owner_headers,
    ).json()

    assert len(un_dia) == 1
    assert len(semana) == 2


def test_cambia_estado_y_libera_el_horario(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    cita = client.post(
        f"{business_url}/appointments", headers=owner_headers, json=_appointment()
    ).json()

    confirmada = client.post(
        f"{business_url}/appointments/{cita['id']}/status",
        headers=owner_headers,
        json={"status": "confirmada"},
    )
    assert confirmada.status_code == 200
    assert confirmada.json()["status"] == "confirmada"

    cancelada = client.post(
        f"{business_url}/appointments/{cita['id']}/status",
        headers=owner_headers,
        json={"status": "cancelada", "reason": "El cliente no puede"},
    )
    assert cancelada.json()["status"] == "cancelada"

    # El horario quedó libre otra vez.
    nueva = client.post(
        f"{business_url}/appointments", headers=owner_headers, json=_appointment()
    )
    assert nueva.status_code == 201


def test_no_reabre_una_cita_completada(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    cita = client.post(
        f"{business_url}/appointments", headers=owner_headers, json=_appointment()
    ).json()
    client.post(
        f"{business_url}/appointments/{cita['id']}/status",
        headers=owner_headers,
        json={"status": "completada"},
    )

    response = client.post(
        f"{business_url}/appointments/{cita['id']}/status",
        headers=owner_headers,
        json={"status": "pendiente"},
    )

    assert response.status_code == 409


def test_edita_cita(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    cita = client.post(
        f"{business_url}/appointments", headers=owner_headers, json=_appointment()
    ).json()

    response = client.patch(
        f"{business_url}/appointments/{cita['id']}",
        headers=owner_headers,
        json={"starts_at": "2027-03-15T11:00:00-06:00", "notes": "Trae referencia"},
    )

    assert response.status_code == 200
    actualizada = response.json()
    assert actualizada["notes"] == "Trae referencia"
    assert actualizada["starts_at"].startswith("2027-03-15T17:00:00")


def test_el_ajeno_no_ve_la_agenda(
    client: TestClient, outsider_headers: dict[str, str], business_url: str
) -> None:
    response = client.get(f"{business_url}/appointments", headers=outsider_headers)

    assert response.status_code == 404
