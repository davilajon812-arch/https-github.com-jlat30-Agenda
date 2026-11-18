"""Planes, entitlements y bloqueos por límite."""

from __future__ import annotations

import psycopg
from fastapi.testclient import TestClient

from tests.api.conftest import BUSINESS_ID


def _set_free_plan(postgres_uri: str) -> None:
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            """
            update public.subscriptions
            set plan = 'free', status = 'active', source = 'manual',
                current_period_end = now() + interval '100 years'
            where business_id = %s
            """,
            (BUSINESS_ID,),
        )


def test_lista_los_planes_disponibles(client: TestClient) -> None:
    response = client.get("/api/v1/billing/plans")

    assert response.status_code == 200
    planes = {plan["id"]: plan for plan in response.json()}
    assert set(planes) == {"free", "pro"}
    assert planes["free"]["max_staff"] == 1
    assert planes["free"]["max_appointments_per_month"] == 30
    assert planes["pro"]["max_staff"] is None
    assert planes["pro"]["features"]["advanced_reports"] is True
    assert planes["free"]["play_product_id"] is None


def test_entitlements_del_negocio_en_pro(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.get(f"{business_url}/entitlements", headers=owner_headers)

    assert response.status_code == 200
    body = response.json()
    assert body["plan"]["id"] == "pro"
    assert body["usage"]["staff_count"] == 2
    assert body["remaining"]["staff"] is None


def test_entitlements_en_plan_gratis_muestra_cupos(
    client: TestClient,
    owner_headers: dict[str, str],
    business_url: str,
    postgres_uri: str,
) -> None:
    _set_free_plan(postgres_uri)

    body = client.get(f"{business_url}/entitlements", headers=owner_headers).json()

    assert body["plan"]["id"] == "free"
    assert body["remaining"]["staff"] == 0  # 1 permitido, 2 en uso
    assert body["remaining"]["appointments_per_month"] == 30
    assert body["upgrade_to"] == "pro"


def test_el_ajeno_no_consulta_entitlements(
    client: TestClient, outsider_headers: dict[str, str], business_url: str
) -> None:
    response = client.get(f"{business_url}/entitlements", headers=outsider_headers)

    assert response.status_code == 404


def test_plan_gratis_bloquea_el_segundo_empleado(
    client: TestClient,
    owner_headers: dict[str, str],
    business_url: str,
    postgres_uri: str,
) -> None:
    _set_free_plan(postgres_uri)

    response = client.post(
        f"{business_url}/staff",
        headers=owner_headers,
        json={"display_name": "Ana"},
    )

    assert response.status_code == 402
    detail = response.json()["detail"]
    assert detail["code"] == "plan_limit_reached"
    assert detail["limit"] == "staff"
    assert detail["upgrade_to"] == "pro"


def test_plan_gratis_bloquea_la_cita_numero_31(
    client: TestClient,
    owner_headers: dict[str, str],
    business_url: str,
    postgres_uri: str,
) -> None:
    _set_free_plan(postgres_uri)
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            "update public.plans set max_appointments_per_month = 2 where id = 'free'"
        )

    for hora in ("09:00", "10:00"):
        creada = client.post(
            f"{business_url}/appointments",
            headers=owner_headers,
            json={
                "client_id": "c1111111-1111-1111-1111-111111111111",
                "service_id": "51111111-1111-1111-1111-111111111111",
                "staff_id": "44444444-4444-4444-4444-444444444444",
                "starts_at": f"2027-03-15T{hora}:00-06:00",
            },
        )
        assert creada.status_code == 201

    tercera = client.post(
        f"{business_url}/appointments",
        headers=owner_headers,
        json={
            "client_id": "c1111111-1111-1111-1111-111111111111",
            "service_id": "51111111-1111-1111-1111-111111111111",
            "staff_id": "44444444-4444-4444-4444-444444444444",
            "starts_at": "2027-03-15T11:00:00-06:00",
        },
    )

    assert tercera.status_code == 402
    assert tercera.json()["detail"]["limit"] == "appointments_per_month"


def test_el_plan_pro_no_limita_empleados(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.post(
        f"{business_url}/staff",
        headers=owner_headers,
        json={"display_name": "Sin limite"},
    )

    assert response.status_code == 201
