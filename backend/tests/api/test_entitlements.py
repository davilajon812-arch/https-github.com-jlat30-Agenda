"""Planes, entitlements y bloqueos por límite."""

from __future__ import annotations

from datetime import datetime
from zoneinfo import ZoneInfo

import psycopg
from fastapi.testclient import TestClient

from tests.api.conftest import BUSINESS_ID

BUSINESS_TZ = ZoneInfo("America/Managua")


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


def _set_quota(postgres_uri: str, limit: int | None) -> None:
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            "update public.plans set max_appointments_per_month = %s where id = 'free'",
            (limit,),
        )


def _month_day(offset_months: int = 0, hour: int = 9) -> str:
    """Un día 15 del mes actual (o del que se indique), en hora del negocio."""
    now = datetime.now(BUSINESS_TZ)
    month = now.month - 1 + offset_months
    year = now.year + month // 12
    month = month % 12 + 1
    return datetime(year, month, 15, hour, 0, tzinfo=BUSINESS_TZ).isoformat()


def _book(client: TestClient, headers: dict[str, str], url: str, starts_at: str):
    return client.post(
        f"{url}/appointments",
        headers=headers,
        json={
            "client_id": "c1111111-1111-1111-1111-111111111111",
            "service_id": "51111111-1111-1111-1111-111111111111",
            "staff_id": "44444444-4444-4444-4444-444444444444",
            "starts_at": starts_at,
        },
    )


def test_lista_los_planes_disponibles(client: TestClient) -> None:
    response = client.get("/api/v1/billing/plans")

    assert response.status_code == 200
    planes = {plan["id"]: plan for plan in response.json()}
    assert set(planes) == {"free", "pro"}
    assert planes["free"]["max_staff"] == 1
    assert planes["free"]["max_appointments_per_month"] == 100
    assert planes["pro"]["max_staff"] is None
    assert planes["pro"]["features"]["advanced_reports"] is True
    assert planes["free"]["play_product_id"] is None
    # El plan Gratis se financia con anuncios; Pro no los muestra.
    assert planes["free"]["features"]["ads"] is True
    assert planes["pro"]["features"]["ads"] is False


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
    assert body["remaining"]["appointments_per_month"] == 100
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


def test_plan_gratis_bloquea_al_agotar_el_cupo(
    client: TestClient,
    owner_headers: dict[str, str],
    business_url: str,
    postgres_uri: str,
) -> None:
    _set_free_plan(postgres_uri)
    _set_quota(postgres_uri, 2)

    for hora in (9, 10):
        assert _book(client, owner_headers, business_url, _month_day(hour=hora)).status_code == 201

    tercera = _book(client, owner_headers, business_url, _month_day(hour=11))

    assert tercera.status_code == 402
    assert tercera.json()["detail"]["limit"] == "appointments_per_month"


def test_una_cita_cancelada_devuelve_el_cupo(
    client: TestClient,
    owner_headers: dict[str, str],
    business_url: str,
    postgres_uri: str,
) -> None:
    """Cancelar no puede gastar cupo: es un error que el negocio no cometió."""
    _set_free_plan(postgres_uri)
    _set_quota(postgres_uri, 1)

    creada = _book(client, owner_headers, business_url, _month_day(hour=9))
    assert creada.status_code == 201
    assert _book(client, owner_headers, business_url, _month_day(hour=10)).status_code == 402

    cancelada = client.post(
        f"{business_url}/appointments/{creada.json()['id']}/status",
        headers=owner_headers,
        json={"status": "cancelada", "reason": "El cliente avisó"},
    )
    assert cancelada.status_code == 200

    # Con la cita cancelada, el cupo vuelve a estar libre.
    assert _book(client, owner_headers, business_url, _month_day(hour=10)).status_code == 201


def test_una_cita_de_otro_mes_no_consume_el_cupo_actual(
    client: TestClient,
    owner_headers: dict[str, str],
    business_url: str,
    postgres_uri: str,
) -> None:
    """Agendar con antelación no debe descontar del mes en curso."""
    _set_free_plan(postgres_uri)
    _set_quota(postgres_uri, 1)

    assert _book(client, owner_headers, business_url, _month_day(1, hour=9)).status_code == 201
    assert _book(client, owner_headers, business_url, _month_day(0, hour=10)).status_code == 201


def test_el_plan_pro_no_limita_empleados(
    client: TestClient, owner_headers: dict[str, str], business_url: str
) -> None:
    response = client.post(
        f"{business_url}/staff",
        headers=owner_headers,
        json={"display_name": "Sin limite"},
    )

    assert response.status_code == 201
