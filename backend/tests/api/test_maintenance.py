"""Tareas programadas: reconciliación y contadores mensuales."""

from __future__ import annotations

import psycopg
from fastapi.testclient import TestClient

from app.jobs import daily_maintenance
from app.services.google_play import FakeGooglePlayClient
from tests.api.conftest import BUSINESS_ID

PRO = "citurno_pro_mensual"


def test_expira_suscripciones_vencidas(postgres_uri: str) -> None:
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            """
            update public.subscriptions
            set plan = 'pro', status = 'active', source = 'play',
                purchase_token = 'tok-viejo',
                current_period_end = now() - interval '1 day'
            where business_id = %s
            """,
            (BUSINESS_ID,),
        )

    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        expiradas = daily_maintenance.expire_stale(conn)

    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        estado = conn.execute(
            "select status from public.subscriptions where business_id = %s "
            "order by created_at desc limit 1",
            (BUSINESS_ID,),
        ).fetchone()[0]

    assert expiradas >= 1
    assert estado == "expired"


def test_abre_el_contador_del_mes(postgres_uri: str) -> None:
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            "delete from public.usage_counters where business_id = %s",
            (BUSINESS_ID,),
        )
        creados = daily_maintenance.reopen_month(conn, daily_maintenance.now_utc())

    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        contador = conn.execute(
            "select appointments_count, messages_count from public.usage_counters "
            "where business_id = %s and period_start = date_trunc('month', now())::date",
            (BUSINESS_ID,),
        ).fetchone()

    assert creados >= 1
    assert contador == (0, 0)


def test_reconcilia_contra_play(postgres_uri: str) -> None:
    cliente = FakeGooglePlayClient(known_tokens={})
    cliente.add_token("tok-recon", PRO, days=45)

    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            """
            update public.subscriptions
            set plan = 'pro', status = 'active', source = 'play',
                product_id = %s, purchase_token = 'tok-recon',
                current_period_end = now() + interval '1 day'
            where business_id = %s
            """,
            (PRO, BUSINESS_ID),
        )

    with psycopg.connect(postgres_uri, autocommit=True, row_factory=psycopg.rows.dict_row) as conn:
        reporte = daily_maintenance.reconcile(conn, cliente)

    assert reporte.checked >= 1
    assert reporte.updated >= 1
    assert reporte.errors == []


def test_endpoint_interno_exige_token(client: TestClient) -> None:
    sin_token = client.post("/api/v1/internal/maintenance/daily")
    con_token = client.post(
        "/api/v1/internal/maintenance/daily",
        headers={"X-Maintenance-Token": "token-de-mantenimiento"},
    )

    assert sin_token.status_code == 401
    assert con_token.status_code == 200
    assert "checked" in con_token.json()
