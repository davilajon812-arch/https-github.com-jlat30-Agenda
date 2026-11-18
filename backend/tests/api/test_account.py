"""Eliminación de la cuenta y datos asociados."""

from __future__ import annotations

import json

import psycopg
from fastapi.testclient import TestClient

from app.api.routes import account as account_module
from tests.api.conftest import make_token

# Usuario exclusivo de estas pruebas: no comparte negocio con los del conftest,
# así el borrado no afecta a los datos de sesión que usan las demás pruebas.
DELETE_USER_ID = "99999999-9999-9999-9999-999999999999"
DELETE_BUSINESS_ID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"


def _borrar_restos(postgres_uri: str) -> None:
    """Deja el negocio de prueba limpio, sin importar el orden de ejecución."""
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            "delete from public.appointments where business_id = %s",
            (DELETE_BUSINESS_ID,),
        )
        conn.execute(
            "delete from public.clients where business_id = %s", (DELETE_BUSINESS_ID,)
        )
        conn.execute(
            "delete from public.businesses where id = %s", (DELETE_BUSINESS_ID,)
        )


def _seed_owner(postgres_uri: str) -> None:
    """Deja un negocio con un cliente y una cita listo para borrarse."""
    _borrar_restos(postgres_uri)
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        conn.execute(
            "insert into auth.users (id, email, raw_user_meta_data) "
            "values (%s, %s, %s) on conflict (id) do nothing",
            (
                DELETE_USER_ID,
                "borrar@example.com",
                json.dumps({"full_name": "Borrar"}),
            ),
        )
        conn.execute(
            """
            insert into public.businesses
                (id, owner_id, name, slug, timezone, currency)
            values (%s, %s, 'Negocio A Borrar', 'negocio-a-borrar',
                    'America/Managua', 'NIO')
            """,
            (DELETE_BUSINESS_ID, DELETE_USER_ID),
        )
        # El trigger `on_business_created` ya crea la membresía del dueño y la
        # suscripción Gratis.
        cliente = conn.execute(
            """
            insert into public.clients (business_id, full_name, phone)
            values (%s, 'Cliente A Borrar', '50588889999')
            returning id
            """,
            (DELETE_BUSINESS_ID,),
        ).fetchone()[0]
        conn.execute(
            """
            insert into public.appointments
                (business_id, client_id, starts_at, ends_at, status)
            values (%s, %s, now() + interval '1 day',
                    now() + interval '1 day 30 minutes', 'pendiente')
            """,
            (DELETE_BUSINESS_ID, cliente),
        )


def _enable_service_role(client: TestClient, monkeypatch) -> None:
    """Simula la service_role sin dejarla configurada para otras pruebas."""
    monkeypatch.setattr(
        client.app.state.settings, "supabase_url", "https://proyecto.supabase.co"
    )
    monkeypatch.setattr(
        client.app.state.settings, "supabase_service_role_key", "service-role-prueba"
    )


def _auth_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(DELETE_USER_ID)}"}


def _count(postgres_uri: str, sql: str, params: tuple[object, ...]) -> int:
    with psycopg.connect(postgres_uri, autocommit=True) as conn:
        return conn.execute(sql, params).fetchone()[0]


def test_sin_service_role_no_elimina_nada(
    client: TestClient, owner_headers: dict[str, str]
) -> None:
    response = client.delete("/api/v1/account", headers=owner_headers)

    assert response.status_code == 503
    assert client.get("/api/v1/me", headers=owner_headers).status_code == 200


def test_requiere_autenticacion(client: TestClient) -> None:
    assert client.delete("/api/v1/account").status_code == 401


def test_elimina_negocio_clientes_y_citas(
    client: TestClient, postgres_uri: str, monkeypatch
) -> None:
    _seed_owner(postgres_uri)
    _enable_service_role(client, monkeypatch)
    borrados: list[str] = []
    monkeypatch.setattr(
        account_module,
        "_delete_supabase_user",
        lambda base_url, key, user_id: borrados.append(user_id),
    )

    response = client.delete("/api/v1/account", headers=_auth_headers())

    assert response.status_code == 200
    assert response.json() == {"status": "deleted"}
    assert borrados == [DELETE_USER_ID]

    for tabla, columna in (
        ("businesses", "id"),
        ("clients", "business_id"),
        ("appointments", "business_id"),
    ):
        assert (
            _count(
                postgres_uri,
                f"select count(*) from public.{tabla} where {columna} = %s",
                (DELETE_BUSINESS_ID,),
            )
            == 0
        ), tabla


def test_si_supabase_falla_no_se_borran_los_datos(
    client: TestClient, postgres_uri: str, monkeypatch
) -> None:
    _seed_owner(postgres_uri)
    _enable_service_role(client, monkeypatch)

    def _explota(*_args: object) -> None:
        from fastapi import HTTPException

        raise HTTPException(status_code=502, detail="No se pudo eliminar la cuenta")

    monkeypatch.setattr(account_module, "_delete_supabase_user", _explota)

    response = client.delete("/api/v1/account", headers=_auth_headers())

    assert response.status_code == 502
    # La transacción se revirtió: el negocio sigue ahí.
    assert (
        _count(
            postgres_uri,
            "select count(*) from public.businesses where id = %s",
            (DELETE_BUSINESS_ID,),
        )
        == 1
    )


def test_un_usuario_sin_negocios_puede_eliminar_su_cuenta(
    client: TestClient, postgres_uri: str, monkeypatch
) -> None:
    _borrar_restos(postgres_uri)
    _enable_service_role(client, monkeypatch)
    borrados: list[str] = []
    monkeypatch.setattr(
        account_module,
        "_delete_supabase_user",
        lambda base_url, key, user_id: borrados.append(user_id),
    )

    response = client.delete("/api/v1/account", headers=_auth_headers())

    assert response.status_code == 200
    assert borrados == [DELETE_USER_ID]
