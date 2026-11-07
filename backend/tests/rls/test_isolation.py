"""Un usuario no puede leer ni escribir datos de otro negocio."""

from __future__ import annotations

import uuid

import psycopg
import pytest

from tests.rls.conftest import (
    APPOINTMENT_A,
    BUSINESS_A,
    BUSINESS_B,
    CLIENT_A,
    CLIENT_B,
    SERVICE_A,
    STAFF_A,
    SUBSCRIPTION_A,
    USAGE_A,
    USER_A,
    USER_B,
    act_as,
    ids,
)

pytestmark = pytest.mark.rls


def test_el_dueno_solo_ve_su_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_A):
        rows = conn.execute("select id from public.businesses").fetchall()

    assert ids(rows) == [uuid.UUID(BUSINESS_A)]


def test_el_dueno_b_no_ve_el_negocio_a(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_B):
        rows = conn.execute(
            "select id from public.businesses where id = %s", (BUSINESS_A,)
        ).fetchall()

    assert rows == []


def test_los_clientes_estan_aislados_por_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_B):
        rows = conn.execute("select id from public.clients").fetchall()
        ajeno = conn.execute(
            "select id from public.clients where id = %s", (CLIENT_A,)
        ).fetchall()

    assert ids(rows) == [uuid.UUID(CLIENT_B)]
    assert ajeno == []


def test_el_empleado_ve_las_citas_de_su_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, STAFF_A):
        rows = conn.execute("select id from public.appointments").fetchall()

    assert ids(rows) == [uuid.UUID(APPOINTMENT_A)]


def test_otro_negocio_no_ve_las_citas(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_B):
        rows = conn.execute("select id from public.appointments").fetchall()

    assert rows == []


def test_no_se_puede_leer_la_suscripcion_de_otro_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_B):
        rows = conn.execute(
            "select id from public.subscriptions where id = %s",
            (SUBSCRIPTION_A,),
        ).fetchall()

    assert rows == []


def test_no_se_pueden_leer_los_contadores_de_otro_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_B):
        rows = conn.execute(
            "select id from public.usage_counters where id = %s", (USAGE_A,)
        ).fetchall()

    assert rows == []


def test_el_dueno_ve_las_suscripciones_de_su_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_A):
        rows = conn.execute("select id from public.subscriptions").fetchall()

    assert ids(rows) == [uuid.UUID(SUBSCRIPTION_A)]


def test_el_empleado_no_puede_editar_el_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, STAFF_A):
        with conn.transaction(force_rollback=True):
            cursor = conn.execute(
                "update public.businesses set name = 'Hackeado' where id = %s",
                (BUSINESS_A,),
            )

    assert cursor.rowcount == 0


def test_el_dueno_puede_editar_su_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_A):
        with conn.transaction(force_rollback=True):
            cursor = conn.execute(
                "update public.businesses set name = 'Barbería A2' where id = %s",
                (BUSINESS_A,),
            )

    assert cursor.rowcount == 1


def test_el_empleado_puede_crear_citas_en_su_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, STAFF_A):
        with conn.transaction(force_rollback=True):
            cursor = conn.execute(
                """
                insert into public.appointments (
                    business_id, client_id, service_id, staff_id,
                    starts_at, ends_at, status
                )
                values (%s, %s, %s, %s, now() + interval '1 hour',
                        now() + interval '90 minutes', 'pendiente')
                """,
                (BUSINESS_A, CLIENT_A, SERVICE_A, STAFF_A),
            )

    assert cursor.rowcount == 1


def test_no_se_puede_crear_citas_en_otro_negocio(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_B):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            conn.execute(
                """
                insert into public.appointments (
                    business_id, client_id, service_id, staff_id,
                    starts_at, ends_at, status
                )
                values (%s, %s, %s, %s, now(), now() + interval '30 minutes',
                        'pendiente')
                """,
                (BUSINESS_A, CLIENT_A, SERVICE_A, STAFF_A),
            )


def test_la_cita_debe_usar_datos_del_mismo_negocio(seeded_db) -> None:
    """Aunque la RLS lo permitiera, no se mezclan datos entre negocios."""
    conn, _ = seeded_db

    with act_as(conn, USER_B):
        with pytest.raises(psycopg.errors.CheckViolation):
            conn.execute(
                """
                insert into public.appointments (
                    business_id, client_id, service_id, staff_id,
                    starts_at, ends_at, status
                )
                values (%s, %s, %s, %s, now(), now() + interval '30 minutes',
                        'pendiente')
                """,
                (BUSINESS_B, CLIENT_A, SERVICE_A, STAFF_A),
            )


def test_no_se_puede_escribir_una_suscripcion_desde_la_app(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_A):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            conn.execute(
                """
                insert into public.subscriptions (business_id, plan, status, source)
                values (%s, 'pro', 'active', 'manual')
                """,
                (BUSINESS_A,),
            )


def test_el_usuario_b_no_ve_el_perfil_del_negocio_a(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_B):
        rows = conn.execute(
            "select id from public.profiles where id = %s", (USER_A,)
        ).fetchall()

    assert rows == []


def test_los_miembros_se_ven_entre_si(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, STAFF_A):
        rows = conn.execute(
            "select id from public.profiles where id in (%s, %s, %s)",
            (USER_A, STAFF_A, USER_B),
        ).fetchall()

    assert set(ids(rows)) == {uuid.UUID(USER_A), uuid.UUID(STAFF_A)}


def test_el_negocio_b_existe_solo_para_su_dueno(seeded_db) -> None:
    conn, _ = seeded_db

    with act_as(conn, USER_B):
        rows = conn.execute("select id from public.businesses").fetchall()

    assert ids(rows) == [uuid.UUID(BUSINESS_B)]
