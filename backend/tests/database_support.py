"""Utilidades compartidas por las pruebas que necesitan Postgres.

`tests/rls` las usa para validar las políticas y `tests/api` para probar los
endpoints contra un esquema real.
"""

from __future__ import annotations

import tempfile
from pathlib import Path
from typing import Any

import psycopg

MIGRATIONS_DIR = Path(__file__).resolve().parent.parent / "supabase" / "migrations"

# Réplica mínima del esquema auth de Supabase para pruebas locales.
AUTH_STUB = """
create schema if not exists auth;

create table if not exists auth.users (
    id uuid primary key,
    instance_id uuid default '00000000-0000-0000-0000-000000000000',
    aud text default 'authenticated',
    role text default 'authenticated',
    email text,
    encrypted_password text,
    email_confirmed_at timestamptz default now(),
    raw_app_meta_data jsonb default '{}'::jsonb,
    raw_user_meta_data jsonb default '{}'::jsonb,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

create or replace function auth.uid()
returns uuid
language sql
stable
as $$
    select coalesce(
        nullif(current_setting('request.jwt.claim.sub', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
    )::uuid;
$$;

do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'anon') then
        create role anon nologin;
    end if;
    if not exists (select 1 from pg_roles where rolname = 'authenticated') then
        create role authenticated nologin;
    end if;
    if not exists (select 1 from pg_roles where rolname = 'service_role') then
        create role service_role nologin bypassrls;
    end if;
end;
$$;

grant usage on schema public to anon, authenticated, service_role;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
"""


def apply_migrations(conn: psycopg.Connection[Any]) -> None:
    """Aplica todas las migraciones en orden."""
    for migration in sorted(MIGRATIONS_DIR.glob("*.sql")):
        conn.execute(migration.read_text(encoding="utf-8"))


def start_embedded_postgres() -> tuple[Any, str]:
    """Levanta un Postgres temporal con el esquema auth simulado.

    Devuelve el servidor (para limpiarlo) y la cadena de conexión.
    """
    import pgserver

    data_dir = tempfile.mkdtemp(prefix="agendapro-test-")
    server = pgserver.get_server(data_dir)
    uri = server.get_uri()

    with psycopg.connect(uri, autocommit=True) as conn:
        conn.execute(AUTH_STUB)
        apply_migrations(conn)

    return server, uri
