"""Disponibilidad: huecos libres por servicio, empleado y fecha."""

from __future__ import annotations

from datetime import datetime, time
from zoneinfo import ZoneInfo

import psycopg
from fastapi.testclient import TestClient
from psycopg.rows import dict_row

from app.services.availability import compute_availability
from tests.api.conftest import (
    BUSINESS_ID,
    CLIENT_ID,
    OTHER_TEST_DAY,
    SERVICE_ID,
    STAFF_MEMBER_ID,
    TEST_DAY,
    TEST_WEEKDAY,
)

DAY = TEST_DAY.isoformat()


def test_devuelve_huecos_del_horario(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.get(
        f"{business_url}/availability?service_id={SERVICE_ID}&date={DAY}"
        f"&staff_id={STAFF_MEMBER_ID}",
        headers=owner_headers,
    )

    assert response.status_code == 200
    body = response.json()
    assert body["timezone"] == "America/Managua"
    assert body["service_duration_minutes"] == 30

    carlos = body["staff"][0]
    assert carlos["staff_name"] == "Carlos"
    # 09:00 a 12:00, turnos de 30 minutos cada 15 => 11 huecos (09:00 … 11:30).
    assert len(carlos["slots"]) == 11
    assert carlos["slots"][0]["starts_at"].startswith(f"{DAY}T09:00:00")


def test_no_ofrece_huecos_que_ya_empezaron(seeded: str) -> None:
    """Al pedir el día en curso, los huecos que ya pasaron no se ofrecen."""
    ahora = datetime.combine(TEST_DAY, time(10, 20), tzinfo=ZoneInfo("America/Managua"))

    with psycopg.connect(seeded, row_factory=dict_row) as conn:
        body = compute_availability(
            conn,
            business_id=BUSINESS_ID,
            service_id=SERVICE_ID,
            day_value=DAY,
            staff_id=STAFF_MEMBER_ID,
            now=ahora,
        )

    huecos = [slot.starts_at for slot in body.staff[0].slots]
    # De 09:00 a 12:00 quedan los de 10:30 en adelante.
    assert len(huecos) == 5
    assert huecos[0] == datetime.combine(
        TEST_DAY, time(10, 30), tzinfo=ZoneInfo("America/Managua")
    )
    assert all(inicio > ahora for inicio in huecos)


def test_sin_horario_no_hay_huecos(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    otro_dia = OTHER_TEST_DAY.isoformat()  # martes: el empleado no tiene horario
    assert (TEST_DAY.weekday() + 1) % 7 == TEST_WEEKDAY

    body = client.get(
        f"{business_url}/availability?service_id={SERVICE_ID}&date={otro_dia}"
        f"&staff_id={STAFF_MEMBER_ID}",
        headers=owner_headers,
    ).json()

    assert body["staff"][0]["slots"] == []


def test_una_cita_ocupa_el_hueco(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    client.post(
        f"{business_url}/appointments",
        headers=owner_headers,
        json={
            "client_id": CLIENT_ID,
            "service_id": SERVICE_ID,
            "staff_id": STAFF_MEMBER_ID,
            "starts_at": f"{DAY}T09:00:00-06:00",
        },
    )

    body = client.get(
        f"{business_url}/availability?service_id={SERVICE_ID}&date={DAY}"
        f"&staff_id={STAFF_MEMBER_ID}",
        headers=owner_headers,
    ).json()

    huecos = [slot["starts_at"] for slot in body["staff"][0]["slots"]]
    # 09:00 y 09:15 se solapan con la cita de 09:00 a 09:30.
    assert not any("T09:00:00" in inicio for inicio in huecos)
    assert not any("T09:15:00" in inicio for inicio in huecos)
    assert any("T09:30:00" in inicio for inicio in huecos)


def test_un_bloqueo_quita_los_huecos(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    client.post(
        f"{business_url}/staff/{STAFF_MEMBER_ID}/blocks",
        headers=owner_headers,
        json={
            "starts_at": f"{DAY}T09:00:00-06:00",
            "ends_at": f"{DAY}T10:00:00-06:00",
            "kind": "descanso",
        },
    )

    body = client.get(
        f"{business_url}/availability?service_id={SERVICE_ID}&date={DAY}"
        f"&staff_id={STAFF_MEMBER_ID}",
        headers=owner_headers,
    ).json()

    huecos = [slot["starts_at"] for slot in body["staff"][0]["slots"]]
    assert not any("T09:" in inicio for inicio in huecos)
    assert any("T10:00:00" in inicio for inicio in huecos)


def test_servicio_inexistente(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.get(
        f"{business_url}/availability"
        "?service_id=00000000-0000-0000-0000-000000000000&date=2027-03-15",
        headers=owner_headers,
    )

    assert response.status_code == 404


def test_el_ajeno_no_consulta_disponibilidad(
    client: TestClient, outsider_headers: dict[str, str], business_url: str
) -> None:
    response = client.get(
        f"{business_url}/availability?service_id={SERVICE_ID}&date={DAY}",
        headers=outsider_headers,
    )

    assert response.status_code == 404
