"""Límite de negocios según el plan: Gratis uno, Pro varios."""

from __future__ import annotations

import json

import psycopg
import pytest

from tests.api.conftest import BUSINESS_ID, OWNER_ID

# Usuario exclusivo de estas pruebas para no tocar el negocio de sesión.
LIMIT_USER_ID = "88888888-8888-8888-8888-888888888888"


def _seed_user(postgres_uri: str) -> None:
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            "delete from public.appointments where business_id in "
            "(select id from public.businesses where owner_id = %s)",
            (LIMIT_USER_ID,),
        )
        conn.execute("delete from public.businesses where owner_id = %s", (LIMIT_USER_ID,))
        conn.execute(
            "insert into auth.users (id, email, raw_user_meta_data) "
            "values (%s, %s, %s) on conflict (id) do nothing",
            (LIMIT_USER_ID, "limite@example.com", json.dumps({"full_name": "Limite"})),
        )


def _create_business(postgres_uri: str, slug: str) -> None:
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            """
            insert into public.businesses
                (owner_id, name, slug, timezone, currency)
            values (%s, %s, %s, 'America/Managua', 'NIO')
            """,
            (LIMIT_USER_ID, slug, slug),
        )


def _set_plan(postgres_uri: str, plan: str, status: str = "active") -> None:
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            """
            update public.subscriptions
            set plan = %s, status = %s, source = 'manual',
                current_period_end = now() + interval '30 days'
            where business_id in (
                select id from public.businesses where owner_id = %s
            )
            """,
            (plan, status, LIMIT_USER_ID),
        )


def test_el_primer_negocio_siempre_se_permite(postgres_uri: str, seeded: str) -> None:
    _seed_user(postgres_uri)

    _create_business(postgres_uri, "primer-negocio")

    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        total = conn.execute(
            "select count(*) from public.businesses where owner_id = %s",
            (LIMIT_USER_ID,),
        ).fetchone()[0]
    assert total == 1


def test_el_plan_gratis_bloquea_el_segundo_negocio(
    postgres_uri: str, seeded: str
) -> None:
    _seed_user(postgres_uri)
    _create_business(postgres_uri, "negocio-gratis")
    _set_plan(postgres_uri, "free")

    with pytest.raises(psycopg.errors.CheckViolation) as error:
        _create_business(postgres_uri, "segundo-gratis")

    assert "plan_limit_reached" in str(error.value)


def test_el_plan_pro_permite_varios_negocios(postgres_uri: str, seeded: str) -> None:
    _seed_user(postgres_uri)
    _create_business(postgres_uri, "negocio-pro")
    _set_plan(postgres_uri, "pro")

    _create_business(postgres_uri, "segundo-pro")

    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        total = conn.execute(
            "select count(*) from public.businesses where owner_id = %s",
            (LIMIT_USER_ID,),
        ).fetchone()[0]
    assert total == 2


def test_una_suscripcion_expirada_no_permite_el_segundo_negocio(
    postgres_uri: str, seeded: str
) -> None:
    _seed_user(postgres_uri)
    _create_business(postgres_uri, "negocio-expirado")
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            """
            update public.subscriptions
            set plan = 'pro', status = 'expired', source = 'manual',
                current_period_end = now() - interval '1 day'
            where business_id in (
                select id from public.businesses where owner_id = %s
            )
            """,
            (LIMIT_USER_ID,),
        )

    with pytest.raises(psycopg.errors.CheckViolation):
        _create_business(postgres_uri, "segundo-expirado")


def test_el_negocio_de_sesion_no_se_ve_afectado(
    postgres_uri: str, seeded: str
) -> None:
    """El negocio del conftest sigue existiendo con su dueño original."""
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        dueno = conn.execute(
            "select owner_id from public.businesses where id = %s", (BUSINESS_ID,)
        ).fetchone()[0]
    assert str(dueno) == OWNER_ID
