"""Verificación de compras de Google Play y notificaciones RTDN."""

from __future__ import annotations

import base64
import json

import psycopg
from fastapi.testclient import TestClient

from app.services.google_play import FakeGooglePlayClient
from tests.api.conftest import BUSINESS_ID

PRO = "agendapro_pro_mensual"


def _verify(client: TestClient, headers: dict[str, str], token: str, product: str = PRO):
    return client.post(
        "/api/v1/billing/verify",
        headers=headers,
        json={
            "business_id": BUSINESS_ID,
            "product_id": product,
            "purchase_token": token,
        },
    )


def _rtdn(client: TestClient, notification: dict, token: str | None = "token-rtdn"):
    body = {
        "message": {
            "data": base64.b64encode(json.dumps(notification).encode()).decode(),
            "messageId": "1",
            "publishTime": "2026-01-01T00:00:00Z",
        },
        "subscription": "projects/test/subscriptions/rtdn",
    }
    # Pub/Sub no permite cabeceras propias: el secreto viaja en la query string.
    url = "/api/v1/billing/rtdn"
    if token:
        url = f"{url}?token={token}"
    return client.post(url, json=body)


def _subscription(postgres_uri: str) -> dict:
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.row_factory = psycopg.rows.dict_row
        return conn.execute(
            "select plan, status, source, purchase_token, current_period_end, "
            "auto_renewing, acknowledged_at, google_order_id "
            "from public.subscriptions where business_id = %s "
            "order by created_at desc limit 1",
            (BUSINESS_ID,),
        ).fetchone()


def test_una_compra_valida_activa_el_plan(
    client: TestClient,
    owner_headers: dict[str, str],
    play_client: FakeGooglePlayClient,
    postgres_uri: str,
) -> None:
    play_client.add_token("tok-pro", PRO)

    response = _verify(client, owner_headers, "tok-pro")

    assert response.status_code == 200
    body = response.json()
    assert body["plan"]["id"] == "pro"
    assert body["status"] == "active"
    assert body["source"] == "play"
    assert body["auto_renewing"] is True
    assert body["current_period_end"] is not None

    stored = _subscription(postgres_uri)
    assert stored["plan"] == "pro"
    assert stored["purchase_token"] == "tok-pro"
    assert stored["acknowledged_at"] is not None
    assert stored["google_order_id"] is not None


def test_la_compra_se_confirma_en_play(
    client: TestClient,
    owner_headers: dict[str, str],
    play_client: FakeGooglePlayClient,
) -> None:
    play_client.add_token("tok-ack", PRO)

    _verify(client, owner_headers, "tok-ack")

    assert "tok-ack" in play_client.acknowledged


def test_el_plan_se_aplica_a_los_limites(
    client: TestClient,
    owner_headers: dict[str, str],
    business_url: str,
    play_client: FakeGooglePlayClient,
) -> None:
    play_client.add_token("tok-limites", PRO)
    _verify(client, owner_headers, "tok-limites")

    body = client.get(f"{business_url}/entitlements", headers=owner_headers).json()

    assert body["plan"]["id"] == "pro"
    assert body["remaining"]["appointments_per_month"] is None
    assert body["upgrade_to"] is None


def test_producto_desconocido_se_rechaza(
    client: TestClient, owner_headers: dict[str, str], play_client: FakeGooglePlayClient
) -> None:
    play_client.add_token("tok-x", "producto_inventado")

    response = _verify(client, owner_headers, "tok-x", product="producto_inventado")

    assert response.status_code == 400


def test_token_desconocido_se_rechaza(
    client: TestClient, owner_headers: dict[str, str], play_client: FakeGooglePlayClient
) -> None:
    response = _verify(client, owner_headers, "token-que-no-existe")

    assert response.status_code == 404


def test_suscripcion_expirada_no_activa_el_plan(
    client: TestClient, owner_headers: dict[str, str], play_client: FakeGooglePlayClient
) -> None:
    play_client.add_token(
        "tok-expirado", PRO, state="SUBSCRIPTION_STATE_EXPIRED", days=-1
    )

    response = _verify(client, owner_headers, "tok-expirado")

    assert response.status_code == 409


def test_solo_el_dueno_activa_el_plan(
    client: TestClient,
    staff_headers: dict[str, str],
    play_client: FakeGooglePlayClient,
) -> None:
    play_client.add_token("tok-staff", PRO)

    response = _verify(client, staff_headers, "tok-staff")

    assert response.status_code == 403


def test_rtdn_registra_la_compra_y_actualiza_el_plan(
    client: TestClient,
    owner_headers: dict[str, str],
    play_client: FakeGooglePlayClient,
    postgres_uri: str,
) -> None:
    play_client.add_token("tok-rtdn", PRO)
    _verify(client, owner_headers, "tok-rtdn")

    response = _rtdn(
        client,
        {
            "version": "1.0",
            "packageName": "com.agendapro.agenda_pro",
            "subscriptionNotification": {
                "version": "1.0",
                "notificationType": 2,
                "purchaseToken": "tok-rtdn",
                "subscriptionId": PRO,
            },
        },
    )

    assert response.status_code == 200
    assert response.json()["result"] == "applied"
    assert _subscription(postgres_uri)["status"] == "active"


def test_rtdn_de_cancelacion_conserva_el_plan_hasta_fin_de_periodo(
    client: TestClient,
    owner_headers: dict[str, str],
    business_url: str,
    play_client: FakeGooglePlayClient,
    postgres_uri: str,
) -> None:
    play_client.add_token("tok-cancel", PRO)
    _verify(client, owner_headers, "tok-cancel")

    # Play reporta la cancelación de la renovación automática.
    play_client.add_token(
        "tok-cancel", PRO, state="SUBSCRIPTION_STATE_CANCELED", auto_renewing=False
    )
    response = _rtdn(
        client,
        {
            "subscriptionNotification": {
                "notificationType": 3,
                "purchaseToken": "tok-cancel",
                "subscriptionId": PRO,
            }
        },
    )

    assert response.json()["result"] == "applied"
    assert _subscription(postgres_uri)["status"] == "canceled"

    # El periodo ya pagado sigue dando acceso al plan.
    body = client.get(f"{business_url}/entitlements", headers=owner_headers).json()
    assert body["plan"]["id"] == "pro"


def test_rtdn_de_reembolso_degrada_el_plan(
    client: TestClient,
    owner_headers: dict[str, str],
    business_url: str,
    play_client: FakeGooglePlayClient,
) -> None:
    play_client.add_token("tok-rev", PRO)
    _verify(client, owner_headers, "tok-rev")

    play_client.add_token("tok-rev", PRO, state="SUBSCRIPTION_STATE_EXPIRED", days=-1)
    _rtdn(
        client,
        {
            "subscriptionNotification": {
                "notificationType": 12,
                "purchaseToken": "tok-rev",
                "subscriptionId": PRO,
            }
        },
    )

    body = client.get(f"{business_url}/entitlements", headers=owner_headers).json()
    assert body["plan"]["id"] == "free"


def test_rtdn_con_token_desconocido_se_registra_sin_romper(
    client: TestClient, play_client: FakeGooglePlayClient
) -> None:
    response = _rtdn(
        client,
        {
            "subscriptionNotification": {
                "notificationType": 4,
                "purchaseToken": "no-existe",
                "subscriptionId": PRO,
            }
        },
    )

    assert response.status_code == 200
    assert response.json()["result"] == "unknown_token"


def test_rtdn_con_token_incorrecto_se_rechaza(
    client: TestClient, play_client: FakeGooglePlayClient
) -> None:
    response = _rtdn(
        client,
        {"subscriptionNotification": {"notificationType": 2, "purchaseToken": "x"}},
        token="otro-token",
    )

    assert response.status_code == 401


def test_rtdn_mal_formado(
    client: TestClient, play_client: FakeGooglePlayClient
) -> None:
    response = client.post(
        "/api/v1/billing/rtdn?token=token-rtdn",
        json={"message": {"data": "!!"}},
    )

    assert response.status_code == 400


def test_rtdn_acepta_el_secreto_por_cabecera(
    client: TestClient, play_client: FakeGooglePlayClient
) -> None:
    """Útil para disparar mantenimientos o pruebas manuales."""
    response = client.post(
        "/api/v1/billing/rtdn",
        headers={"X-Agendapro-Token": "token-rtdn"},
        json={
            "message": {
                "data": base64.b64encode(
                    json.dumps(
                        {
                            "subscriptionNotification": {
                                "notificationType": 2,
                                "purchaseToken": "tok-cabecera",
                            }
                        }
                    ).encode()
                ).decode()
            }
        },
    )

    assert response.status_code == 200
    assert response.json()["result"] == "unknown_token"


def test_cada_evento_queda_auditado(
    client: TestClient,
    owner_headers: dict[str, str],
    play_client: FakeGooglePlayClient,
    postgres_uri: str,
) -> None:
    play_client.add_token("tok-audit", PRO)
    _verify(client, owner_headers, "tok-audit")
    _rtdn(
        client,
        {
            "subscriptionNotification": {
                "notificationType": 2,
                "purchaseToken": "tok-audit",
                "subscriptionId": PRO,
            }
        },
    )

    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        eventos = conn.execute(
            "select event_type from public.billing_events order by created_at"
        ).fetchall()

    tipos = [row[0] for row in eventos]
    assert "purchase_verified" in tipos
    assert "rtdn_SUBSCRIPTION_RENEWED" in tipos
