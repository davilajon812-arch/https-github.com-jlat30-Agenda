"""Infraestructura para probar las políticas de Row Level Security.

Dos modos:
* `SUPABASE_DB_URL` definido: usa la base de Supabase indicada (las migraciones
  deben estar aplicadas) y limpia los datos de prueba al terminar.
* Sin esa variable: levanta un Postgres embebido (paquete `pgserver`), crea un
  esquema `auth` mínimo compatible con Supabase y aplica las migraciones. Así
  las políticas se prueban en local y en CI sin depender de la nube.
"""

from __future__ import annotations

import json
import logging
import os
import uuid
from collections.abc import Iterator
from contextlib import contextmanager
from typing import Any

import psycopg
import pytest

# pgserver registra cada comando; con WARNING se evita ruido en las pruebas.
logging.getLogger("pgserver").setLevel(logging.WARNING)

from tests.database_support import (
    AUTH_STUB,
    apply_migrations,
    start_embedded_postgres,
)

USER_A = "11111111-1111-1111-1111-111111111111"
USER_B = "22222222-2222-2222-2222-222222222222"
STAFF_A = "33333333-3333-3333-3333-333333333333"
# Empleado de agenda (staff_members) enlazado al perfil STAFF_A.
STAFF_MEMBER_A = "44444444-4444-4444-4444-444444444444"
STAFF_MEMBER_B = "44444444-4444-4444-4444-555555555555"
SCHEDULE_A = "55555555-5555-5555-5555-111111111111"
BLOCK_A = "66666666-6666-6666-6666-111111111111"

BUSINESS_A = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
BUSINESS_B = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

CLIENT_A = "c1111111-1111-1111-1111-111111111111"
CLIENT_B = "c2222222-2222-2222-2222-222222222222"
SERVICE_A = "51111111-1111-1111-1111-111111111111"
APPOINTMENT_A = "a1111111-1111-1111-1111-111111111111"
SUBSCRIPTION_A = "b1111111-1111-1111-1111-111111111111"
USAGE_A = "d1111111-1111-1111-1111-111111111111"



@pytest.fixture(scope="session")
def database() -> Iterator[tuple[psycopg.Connection[Any], str]]:
    """Conexión a la base de pruebas y su modo (local o supabase)."""
    remote_url = os.getenv("SUPABASE_DB_URL")
    if remote_url:
        with psycopg.connect(remote_url, autocommit=True) as conn:
            yield conn, "supabase"
        return

    pgserver = pytest.importorskip(
        "pgserver", reason="instala pgserver para pruebas locales"
    )
    server, uri = start_embedded_postgres()
    try:
        with psycopg.connect(uri, autocommit=True) as conn:
            yield conn, "local"
    finally:
        server.cleanup()


def _cleanup(conn: psycopg.Connection[Any]) -> None:
    # Orden explícito para respetar las claves foráneas con ON DELETE RESTRICT.
    conn.execute(
        "delete from public.appointments where business_id in (%s, %s)",
        (BUSINESS_A, BUSINESS_B),
    )
    conn.execute(
        "delete from public.clients where business_id in (%s, %s)",
        (BUSINESS_A, BUSINESS_B),
    )
    conn.execute(
        "delete from public.staff_members where business_id in (%s, %s)",
        (BUSINESS_A, BUSINESS_B),
    )
    conn.execute(
        "delete from public.businesses where id in (%s, %s)",
        (BUSINESS_A, BUSINESS_B),
    )
    conn.execute(
        "delete from auth.users where id in (%s, %s, %s)",
        (USER_A, USER_B, STAFF_A),
    )
    conn.execute(
        "delete from public.profiles where id in (%s, %s, %s)",
        (USER_A, USER_B, STAFF_A),
    )


def _seed(conn: psycopg.Connection[Any]) -> None:
    users = [
        (USER_A, "dueno-a@example.com", "Dueño A"),
        (USER_B, "dueno-b@example.com", "Dueño B"),
        (STAFF_A, "empleado-a@example.com", "Empleado A"),
    ]
    for user_id, email, name in users:
        conn.execute(
            """
            insert into auth.users (id, email, raw_user_meta_data)
            values (%s, %s, %s)
            """,
            (user_id, email, json.dumps({"full_name": name})),
        )

    conn.execute(
        """
        insert into public.businesses (id, owner_id, name, slug, industry)
        values (%s, %s, 'Barbería A', 'barberia-a', 'barberia'),
               (%s, %s, 'Salón B', 'salon-b', 'salon_belleza')
        """,
        (BUSINESS_A, USER_A, BUSINESS_B, USER_B),
    )

    # Empleado del negocio A (el dueño lo agrega el trigger).
    conn.execute(
        """
        insert into public.business_members (business_id, profile_id, role)
        values (%s, %s, 'staff')
        """,
        (BUSINESS_A, STAFF_A),
    )

    # Empleados de agenda: uno con cuenta (STAFF_A) y uno del negocio B.
    conn.execute(
        """
        insert into public.staff_members (id, business_id, profile_id, display_name)
        values (%s, %s, %s, 'Empleado A'),
               (%s, %s, null, 'Empleado B')
        """,
        (STAFF_MEMBER_A, BUSINESS_A, STAFF_A, STAFF_MEMBER_B, BUSINESS_B),
    )

    conn.execute(
        """
        insert into public.staff_schedules (id, business_id, staff_id, weekday, start_time, end_time)
        values (%s, %s, %s, 1, '09:00', '18:00')
        """,
        (SCHEDULE_A, BUSINESS_A, STAFF_MEMBER_A),
    )

    conn.execute(
        """
        insert into public.staff_blocks (id, business_id, staff_id, starts_at, ends_at, kind)
        values (%s, %s, %s, now() + interval '10 days', now() + interval '12 days', 'vacacion')
        """,
        (BLOCK_A, BUSINESS_A, STAFF_MEMBER_A),
    )

    conn.execute(
        """
        insert into public.clients (id, business_id, full_name, phone)
        values (%s, %s, 'Cliente A', '50588880000'),
               (%s, %s, 'Cliente B', '50588880001')
        """,
        (CLIENT_A, BUSINESS_A, CLIENT_B, BUSINESS_B),
    )

    conn.execute(
        """
        insert into public.services (id, business_id, name, duration_minutes, price)
        values (%s, %s, 'Corte', 30, 150)
        """,
        (SERVICE_A, BUSINESS_A),
    )

    conn.execute(
        """
        insert into public.appointments (
            id, business_id, client_id, service_id, staff_id,
            starts_at, ends_at, status, price
        )
        values (%s, %s, %s, %s, %s, now(), now() + interval '30 minutes',
                'pendiente', 150)
        """,
        (APPOINTMENT_A, BUSINESS_A, CLIENT_A, SERVICE_A, STAFF_MEMBER_A),
    )

    conn.execute(
        """
        insert into public.subscriptions (
            id, business_id, plan, status, source, current_period_end
        )
        values (%s, %s, 'free', 'active', 'manual', now() + interval '30 days')
        """,
        (SUBSCRIPTION_A, BUSINESS_A),
    )

    conn.execute(
        """
        insert into public.usage_counters (
            id, business_id, period_start, period_end
        )
        values (%s, %s, date_trunc('month', now())::date,
                (date_trunc('month', now()) + interval '1 month')::date)
        """,
        (USAGE_A, BUSINESS_A),
    )


@pytest.fixture(scope="session")
def seeded_db(
    database: tuple[psycopg.Connection[Any], str],
) -> Iterator[tuple[psycopg.Connection[Any], str]]:
    """Base con dos negocios de prueba, un empleado y datos iniciales."""
    conn, mode = database
    _cleanup(conn)
    _seed(conn)
    try:
        yield conn, mode
    finally:
        _cleanup(conn)


@contextmanager
def act_as(conn: psycopg.Connection[Any], user_id: str) -> Iterator[None]:
    """Ejecuta el bloque como el usuario autenticado `user_id`.

    Cambia el rol de la sesión (no abre transacción) para que un error de RLS
    esperado no invalide la conexión. Cualquier escritura que deba deshacerse
    se envuelve en `conn.transaction(force_rollback=True)`.
    """
    claims = {
        "sub": user_id,
        "role": "authenticated",
        "aud": "authenticated",
        "email": f"{user_id}@example.com",
    }
    conn.execute("set role authenticated")
    try:
        conn.execute(
            "select set_config('request.jwt.claims', %s, false)",
            (json.dumps(claims),),
        )
        conn.execute(
            "select set_config('request.jwt.claim.sub', %s, false)", (user_id,)
        )
        yield
    finally:
        conn.execute("reset role")
        conn.execute("select set_config('request.jwt.claims', '', false)")
        conn.execute("select set_config('request.jwt.claim.sub', '', false)")


def ids(rows: list[tuple[Any, ...]]) -> list[uuid.UUID]:
    """Extrae la primera columna de cada fila como UUID."""
    return [row[0] for row in rows]
