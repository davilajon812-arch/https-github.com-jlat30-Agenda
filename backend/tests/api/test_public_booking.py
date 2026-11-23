"""Enlace público de reservas: agendar, consultar y cancelar sin cuenta."""

from __future__ import annotations

import psycopg
import pytest
from fastapi.testclient import TestClient

from app.core.ratelimit import BOOKING_LIMITER, READ_LIMITER
from tests.api.conftest import (
    BUSINESS_ID,
    OTHER_STAFF_ID,
    SERVICE_ID,
    STAFF_MEMBER_ID,
    TEST_DAY,
    TEST_WEEKDAY,
)

DAY = TEST_DAY.isoformat()
SLUG = "barberia-test"
BASE = f"/api/v1/public/{SLUG}"


@pytest.fixture(autouse=True)
def reset_limiters() -> None:
    """Cada prueba arranca con los contadores de abuso en cero."""
    BOOKING_LIMITER.reset()
    READ_LIMITER.reset()


def _enable(seeded: str, enabled: bool = True) -> None:
    with psycopg.connect(seeded, autocommit=True) as conn:
        conn.execute(
            "update public.businesses set public_booking_enabled = %s where id = %s",
            (enabled, BUSINESS_ID),
        )


def _booking_payload(
    hour: int = 9,
    phone: str = "50577770000",
    minute: int = 0,
    staff_id: str | None = STAFF_MEMBER_ID,
) -> dict[str, object]:
    return {
        "service_id": SERVICE_ID,
        "staff_id": staff_id,
        "starts_at": f"{DAY}T{hour:02d}:{minute:02d}:00-06:00",
        "client_name": "Marta Ruiz",
        "client_phone": phone,
    }


def test_devuelve_negocio_servicios_y_personal(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)

    response = client.get(BASE)

    assert response.status_code == 200
    body = response.json()
    assert body["business"]["name"] == "Barbería Test"
    assert body["business"]["currency"] == "NIO"
    assert [service["name"] for service in body["services"]] == ["Corte"]
    assert {person["display_name"] for person in body["staff"]} == {"Carlos", "María"}
    assert body["days_ahead"] > 0


def test_expone_direccion_y_horario_de_atencion(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)
    with psycopg.connect(seeded, autocommit=True) as conn:
        conn.execute(
            "update public.businesses set address = %s where id = %s",
            ("Frente al parque central, Managua", BUSINESS_ID),
        )

    body = client.get(BASE).json()

    assert body["business"]["address"] == "Frente al parque central, Managua"
    assert body["bookable"] is True
    # Carlos trabaja los lunes de 09:00 a 12:00; María no tiene horario.
    assert body["hours"] == [
        {"weekday": TEST_WEEKDAY, "opens_at": "09:00", "closes_at": "12:00"}
    ]


def test_sin_horarios_el_negocio_no_es_reservable(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)
    with psycopg.connect(seeded, autocommit=True) as conn:
        conn.execute(
            "update public.staff_schedules set is_active = false where business_id = %s",
            (BUSINESS_ID,),
        )

    body = client.get(BASE).json()

    assert body["bookable"] is False
    assert body["hours"] == []


def test_sin_empleado_elegido_reparte_al_menos_ocupado(
    client: TestClient, seeded: str
) -> None:
    """Dos empleados libres: la segunda cita va al que tenía la agenda vacía."""
    _enable(seeded)
    with psycopg.connect(seeded, autocommit=True) as conn:
        # María también atiende los lunes.
        conn.execute(
            """
            insert into public.staff_schedules
                (business_id, staff_id, weekday, start_time, end_time)
            values (%s, %s, %s, '09:00', '12:00')
            """,
            (BUSINESS_ID, OTHER_STAFF_ID, TEST_WEEKDAY),
        )

    first = client.post(
        f"{BASE}/appointments", json=_booking_payload(hour=9, staff_id=None)
    )
    second = client.post(
        f"{BASE}/appointments",
        json=_booking_payload(hour=10, phone="50577770001", staff_id=None),
    )

    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json()["staff_name"] != second.json()["staff_name"]


def test_el_empleado_elegido_se_respeta(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)

    body = client.post(f"{BASE}/appointments", json=_booking_payload()).json()

    assert body["staff_name"] == "Carlos"


def test_el_enlace_apagado_da_404(client: TestClient, seeded: str) -> None:
    _enable(seeded, enabled=False)

    response = client.get(BASE)

    assert response.status_code == 404


def test_slug_inexistente_da_404(client: TestClient, seeded: str) -> None:
    assert client.get("/api/v1/public/no-existe").status_code == 404


def test_huecos_del_dia_sin_cuenta(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)

    response = client.get(
        f"{BASE}/availability?service_id={SERVICE_ID}&date={DAY}"
        f"&staff_id={STAFF_MEMBER_ID}"
    )

    assert response.status_code == 200
    slots = response.json()["staff"][0]["slots"]
    assert slots
    assert slots[0]["starts_at"].startswith(f"{DAY}T09:00:00")


def test_reserva_crea_cliente_y_cita_confirmada(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)

    response = client.post(f"{BASE}/appointments", json=_booking_payload())

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["status"] == "confirmada"
    assert body["service_name"] == "Corte"
    assert body["staff_name"] == "Carlos"
    assert body["price"] == 150
    assert body["cancellable"] is True
    assert len(body["token"]) >= 16

    with psycopg.connect(seeded) as conn:
        row = conn.execute(
            """
            select a.booked_online, a.created_by, c.full_name, c.phone
            from public.appointments a
            join public.clients c on c.id = a.client_id
            where a.public_token = %s
            """,
            (body["token"],),
        ).fetchone()

    assert row == (True, None, "Marta Ruiz", "50577770000")


def test_reserva_reutiliza_el_cliente_del_mismo_telefono(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)

    client.post(f"{BASE}/appointments", json=_booking_payload(hour=9))
    client.post(f"{BASE}/appointments", json=_booking_payload(hour=10))

    with psycopg.connect(seeded) as conn:
        total = conn.execute(
            "select count(*) from public.clients where phone = '50577770000'"
        ).fetchone()[0]

    assert total == 1


def test_un_horario_ocupado_se_rechaza(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)

    assert client.post(
        f"{BASE}/appointments", json=_booking_payload(hour=9)
    ).status_code == 201

    second = client.post(
        f"{BASE}/appointments", json=_booking_payload(hour=9, phone="50577770001")
    )

    assert second.status_code == 409
    assert "no está disponible" in second.json()["detail"]


def test_no_se_puede_reservar_fuera_del_horario(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)
    payload = _booking_payload()
    payload["starts_at"] = f"{DAY}T20:00:00-06:00"

    response = client.post(f"{BASE}/appointments", json=payload)

    assert response.status_code == 409


def test_el_limite_del_plan_gratis_frena_las_reservas(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)
    with psycopg.connect(seeded, autocommit=True) as conn:
        conn.execute(
            "delete from public.subscriptions where business_id = %s", (BUSINESS_ID,)
        )
        conn.execute("update public.plans set max_appointments_per_month = 0 where id = 'free'")

    response = client.post(f"{BASE}/appointments", json=_booking_payload())

    assert response.status_code == 402
    assert response.json()["detail"]["code"] == "plan_limit_reached"


def test_consulta_y_cancela_con_el_token(client: TestClient, seeded: str) -> None:
    _enable(seeded)
    token = client.post(f"{BASE}/appointments", json=_booking_payload()).json()["token"]

    consulta = client.get(f"{BASE}/appointments/{token}")
    assert consulta.status_code == 200
    assert consulta.json()["token"] == token

    cancelada = client.post(f"{BASE}/appointments/{token}/cancel")
    assert cancelada.status_code == 200
    assert cancelada.json()["status"] == "cancelada"
    assert cancelada.json()["cancellable"] is False

    # La segunda cancelación ya no aplica.
    assert client.post(f"{BASE}/appointments/{token}/cancel").status_code == 409


def test_token_inventado_da_404(client: TestClient, seeded: str) -> None:
    _enable(seeded)

    assert client.get(f"{BASE}/appointments/inventado").status_code == 404


def test_el_mismo_telefono_no_acapara_el_dia(client: TestClient, seeded: str) -> None:
    _enable(seeded)

    for hour in (9, 10, 11):
        assert client.post(
            f"{BASE}/appointments", json=_booking_payload(hour=hour)
        ).status_code == 201

    cuarta = client.post(
        f"{BASE}/appointments", json=_booking_payload(hour=11, minute=30)
    )
    assert cuarta.status_code == 429


def test_el_rate_limit_frena_las_reservas_seguidas(
    client: TestClient, seeded: str
) -> None:
    _enable(seeded)
    BOOKING_LIMITER.reset()

    codes = [
        client.post(f"{BASE}/appointments", json=_booking_payload()).status_code
        for _ in range(8)
    ]

    assert 429 in codes


def test_la_pagina_publica_responde_html(client: TestClient, seeded: str) -> None:
    _enable(seeded)

    response = client.get(f"/r/{SLUG}")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/html")
    assert "Barbería Test" in response.text
    assert "Confirmar cita" in response.text


def test_la_pagina_trae_tarjeta_para_compartir(client: TestClient, seeded: str) -> None:
    """Sin Open Graph, el enlace se ve como texto pelado en WhatsApp."""
    _enable(seeded)

    page = client.get(f"/r/{SLUG}").text

    assert 'property="og:title"' in page
    assert "Barbería Test" in page
    assert 'property="og:image"' in page
    assert "/og-cover.png" in page
    assert f'rel="canonical" href="http://testserver/r/{SLUG}"' in page


def test_la_imagen_para_compartir_se_sirve(client: TestClient) -> None:
    response = client.get("/og-cover.png")

    assert response.status_code == 200
    assert response.headers["content-type"] == "image/png"
    assert response.content[:8] == b"\x89PNG\r\n\x1a\n"


def test_la_pagina_avisa_si_el_enlace_no_existe(client: TestClient, seeded: str) -> None:
    response = client.get("/r/enlace-que-no-existe")

    assert response.status_code == 200
    assert "Reservar cita" in response.text


def test_la_fecha_de_prueba_es_dia_laborable() -> None:
    """La agenda de prueba solo existe si TEST_DAY cae en el día configurado."""
    assert (TEST_DAY.weekday() + 1) % 7 == TEST_WEEKDAY
