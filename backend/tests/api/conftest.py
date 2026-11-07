"""Fixtures de las pruebas de API: Postgres real, JWT propio y datos base."""

from __future__ import annotations

import asyncio
import json
import sys
import time
from collections.abc import Iterator
from datetime import date
from typing import Any

import jwt
import psycopg
import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.main import create_app
from tests.database_support import start_embedded_postgres

# psycopg async necesita un selector loop; en Windows el default es Proactor.
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

JWT_SECRET = "secret-de-pruebas-para-la-api-de-agenda-0123456789"

OWNER_ID = "11111111-1111-1111-1111-111111111111"
STAFF_USER_ID = "33333333-3333-3333-3333-333333333333"
OUTSIDER_ID = "22222222-2222-2222-2222-222222222222"

BUSINESS_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
STAFF_MEMBER_ID = "44444444-4444-4444-4444-444444444444"
OTHER_STAFF_ID = "44444444-4444-4444-4444-666666666666"
SERVICE_ID = "51111111-1111-1111-1111-111111111111"
CLIENT_ID = "c1111111-1111-1111-1111-111111111111"
OTHER_CLIENT_ID = "c2222222-2222-2222-2222-222222222222"

# Día de prueba: 15 de marzo de 2027 (America/Managua, UTC-6).
TEST_DAY = date(2027, 3, 15)
TEST_WEEKDAY = (TEST_DAY.weekday() + 1) % 7


def make_token(user_id: str) -> str:
    """Token HS256 equivalente al que emite Supabase."""
    payload = {
        "sub": user_id,
        "email": f"{user_id[:8]}@example.com",
        "role": "authenticated",
        "aud": "authenticated",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


@pytest.fixture(scope="session")
def postgres_uri() -> Iterator[str]:
    """Postgres embebido con las migraciones aplicadas."""
    server, uri = start_embedded_postgres()
    try:
        yield uri
    finally:
        server.cleanup()


@pytest.fixture(scope="session")
def seeded(postgres_uri: str) -> str:
    """Un negocio, un empleado con horario y datos mínimos."""
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        for user_id, email, name in (
            (OWNER_ID, "dueno@example.com", "Dueño"),
            (STAFF_USER_ID, "empleado@example.com", "Empleado"),
            (OUTSIDER_ID, "ajeno@example.com", "Ajeno"),
        ):
            conn.execute(
                "insert into auth.users (id, email, raw_user_meta_data) "
                "values (%s, %s, %s)",
                (user_id, email, json.dumps({"full_name": name})),
            )

        conn.execute(
            """
            insert into public.businesses
                (id, owner_id, name, slug, timezone, currency)
            values (%s, %s, 'Barbería Test', 'barberia-test', 'America/Managua', 'NIO')
            """,
            (BUSINESS_ID, OWNER_ID),
        )
        conn.execute(
            """
            insert into public.business_members (business_id, profile_id, role)
            values (%s, %s, 'staff')
            """,
            (BUSINESS_ID, STAFF_USER_ID),
        )
        conn.execute(
            """
            insert into public.staff_members (id, business_id, profile_id, display_name)
            values (%s, %s, %s, 'Carlos'),
                   (%s, %s, null, 'María')
            """,
            (
                STAFF_MEMBER_ID,
                BUSINESS_ID,
                STAFF_USER_ID,
                OTHER_STAFF_ID,
                BUSINESS_ID,
            ),
        )
        conn.execute(
            """
            insert into public.staff_schedules
                (business_id, staff_id, weekday, start_time, end_time)
            values (%s, %s, %s, '09:00', '12:00')
            """,
            (BUSINESS_ID, STAFF_MEMBER_ID, TEST_WEEKDAY),
        )
        conn.execute(
            """
            insert into public.services (id, business_id, name, duration_minutes, price)
            values (%s, %s, 'Corte', 30, 150)
            """,
            (SERVICE_ID, BUSINESS_ID),
        )
        conn.execute(
            """
            insert into public.clients (id, business_id, full_name, phone, notes)
            values (%s, %s, 'Cliente Uno', '50588880000', 'Prefiere las mañanas'),
                   (%s, %s, 'Cliente Dos', '50588880001', null)
            """,
            (CLIENT_ID, BUSINESS_ID, OTHER_CLIENT_ID, BUSINESS_ID),
        )

    return postgres_uri


@pytest.fixture(scope="session")
def app_settings(seeded: str) -> Settings:
    """Configuración apuntando al Postgres de prueba."""
    return Settings(
        app_env="dev",
        log_level="WARNING",
        cors_origins=["http://localhost:3000"],
        supabase_url="",
        supabase_jwt_secret=JWT_SECRET,
        database_url=seeded,
    )


@pytest.fixture
def client(app_settings: Settings) -> Iterator[TestClient]:
    """Cliente HTTP con el ciclo de vida completo (abre el pool)."""
    with TestClient(create_app(app_settings)) as test_client:
        yield test_client


@pytest.fixture(autouse=True)
def clean_appointments(postgres_uri: str) -> Iterator[None]:
    """Cada prueba empieza sin citas ni bloqueos."""
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute("delete from public.appointments")
        conn.execute("delete from public.staff_blocks")
    yield


@pytest.fixture
def owner_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(OWNER_ID)}"}


@pytest.fixture
def staff_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(STAFF_USER_ID)}"}


@pytest.fixture
def outsider_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(OUTSIDER_ID)}"}


@pytest.fixture
def business_url() -> str:
    return f"/api/v1/businesses/{BUSINESS_ID}"
