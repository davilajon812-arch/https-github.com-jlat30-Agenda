"""Crea el negocio demo con datos para la revisión de Google Play.

Uso:
    cd backend
    .venv\\Scripts\\python.exe scripts\\seed_demo.py
    .venv\\Scripts\\python.exe scripts\\seed_demo.py --email otro@correo.com

El script es idempotente: cada ejecución borra el negocio demo y lo vuelve a
crear con las citas repartidas alrededor de **hoy**, para que la agenda nunca se
vea vacía ni con fechas vencidas cuando el revisor abra la app.

Qué crea:
- Usuario de Supabase Auth ya confirmado (sin verificación por correo).
- Negocio en plan Pro manual (sin cobro) para que no choque con los límites.
- 4 servicios, 3 empleados con horario de lunes a sábado, 10 clientes.
- Citas pasadas completadas, de hoy y de los próximos días confirmadas o
  pendientes, más algunas canceladas y "no asistió" para que el historial y la
  agenda se vean reales.

Vuelve a ejecutarlo antes de cada envío a la tienda: las fechas caducan.
"""

from __future__ import annotations

import argparse
import random
import sys
from datetime import date, datetime, time, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

BACKEND_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND_ROOT))

import httpx  # noqa: E402
import psycopg  # noqa: E402

from app.core.config import get_settings  # noqa: E402

DEMO_SLUG = "barberia-demo"
DEMO_BUSINESS_NAME = "Barbería El Buen Corte"
DEMO_TIMEZONE = "America/Managua"
DEMO_CURRENCY = "NIO"
DEMO_COUNTRY = "NI"

DEFAULT_EMAIL = "demo@agendapro.app"
DEFAULT_PASSWORD = "AgendaDemo2026!"

# Días de agenda: desde dos semanas atrás hasta una semana adelante.
DAYS_BACK = 14
DAYS_AHEAD = 7

# (índice de empleado, hora local). Nunca se solapan entre sí.
SLOTS = ((0, 9), (1, 10), (2, 11), (0, 15))

SERVICES = (
    ("Corte clásico", "Corte a tijera y máquina", 30, 150),
    ("Corte + barba", "Corte y perfilado de barba", 45, 250),
    ("Afeitado tradicional", "Afeitado con navaja y toalla caliente", 20, 100),
    ("Tinte", "Coloración completa", 60, 450),
)

STAFF = (
    ("Carlos Mendoza", "#0F766E"),
    ("María López", "#B45309"),
    ("José Ruiz", "#1D4ED8"),
)

CLIENTS = (
    ("Ana López", "50588881234", "Prefiere las mañanas"),
    ("Luis Martínez", "50587772345", None),
    ("Carmen Rojas", "50586663456", "Alérgica al tinte con amoníaco"),
    ("Pedro Gutiérrez", "50585554567", None),
    ("Sofía Ramírez", "50584445678", "Le gusta el mismo corte siempre"),
    ("Jorge Castillo", "50583336789", None),
    ("María José Vega", "50582227890", "Viene con su hijo"),
    ("Roberto Solís", "50581118901", None),
    ("Karla Méndez", "50580009012", "Paga con transferencia"),
    ("Francisco Blandón", "50589990123", None),
)


def resolve_service_role_key(service_role_key: str) -> str:
    """Lee la service_role de la configuración o del archivo local del repo."""
    key = service_role_key.strip()
    if key:
        return key
    candidate = BACKEND_ROOT.parent / ".supabase-service-role"
    if candidate.exists():
        return candidate.read_text(encoding="utf-8").strip()
    raise SystemExit(
        "Falta SUPABASE_SERVICE_ROLE_KEY: defínela en backend/.env o guarda la "
        "llave en .supabase-service-role junto al repositorio."
    )


def ensure_demo_user(
    supabase_url: str, anon_key: str, service_role_key: str, email: str, password: str
) -> str:
    """Crea el usuario demo si no existe y devuelve su id."""
    admin_headers = {
        "apikey": service_role_key,
        "Authorization": f"Bearer {service_role_key}",
        "Content-Type": "application/json",
    }

    def _sign_in() -> str | None:
        try:
            response = httpx.post(
                f"{supabase_url}/auth/v1/token?grant_type=password",
                headers={"apikey": anon_key, "Content-Type": "application/json"},
                json={"email": email, "password": password},
                timeout=30,
            )
        except httpx.HTTPError:
            return None
        if response.status_code != 200:
            return None
        return response.json()["user"]["id"]

    user_id = _sign_in()
    if user_id is None:
        response = httpx.post(
            f"{supabase_url}/auth/v1/admin/users",
            headers=admin_headers,
            json={"email": email, "password": password, "email_confirm": True},
            timeout=30,
        )
        if response.status_code not in (200, 201):
            user_id = _sign_in()
            if user_id is None:
                raise SystemExit(
                    f"No se pudo crear el usuario demo: {response.status_code} "
                    f"{response.text}"
                )
        else:
            user_id = response.json()["id"]

    # Garantiza que el correo esté confirmado y la contraseña sea la conocida.
    httpx.put(
        f"{supabase_url}/auth/v1/admin/users/{user_id}",
        headers=admin_headers,
        json={"password": password, "email_confirm": True},
        timeout=30,
    )
    return user_id


def _clear_demo_business(conn: psycopg.Connection) -> None:
    """Borra el negocio demo anterior, citas primero por las FK restrict."""
    conn.execute(
        """
        delete from public.appointments
        where business_id in (select id from public.businesses where slug = %s)
        """,
        (DEMO_SLUG,),
    )
    conn.execute("delete from public.businesses where slug = %s", (DEMO_SLUG,))


def _create_business(conn: psycopg.Connection, owner_id: str) -> str:
    row = conn.execute(
        """
        insert into public.businesses
            (owner_id, name, slug, industry, country_code, currency, timezone, phone)
        values (%s, %s, %s, 'barberia', %s, %s, %s, '50588880000')
        returning id
        """,
        (owner_id, DEMO_BUSINESS_NAME, DEMO_SLUG, DEMO_COUNTRY, DEMO_CURRENCY,
         DEMO_TIMEZONE),
    ).fetchone()
    business_id = row[0]

    # Pro manual: ilimitado y sin cobro, para que el revisor vea todo.
    conn.execute(
        """
        update public.subscriptions
        set plan = 'pro', status = 'active', source = 'manual',
            current_period_start = now(),
            current_period_end = now() + interval '1 year',
            auto_renewing = false,
            updated_at = now()
        where business_id = %s
        """,
        (business_id,),
    )
    return business_id


def _create_services(conn: psycopg.Connection, business_id: str) -> list[tuple[str, int]]:
    created: list[tuple[str, int]] = []
    for name, description, duration, price in SERVICES:
        row = conn.execute(
            """
            insert into public.services
                (business_id, name, description, duration_minutes, price)
            values (%s, %s, %s, %s, %s)
            returning id
            """,
            (business_id, name, description, duration, price),
        ).fetchone()
        created.append((row[0], duration))
    return created


def _create_staff(conn: psycopg.Connection, business_id: str) -> list[str]:
    staff_ids: list[str] = []
    for display_name, color in STAFF:
        row = conn.execute(
            """
            insert into public.staff_members (business_id, display_name, color)
            values (%s, %s, %s)
            returning id
            """,
            (business_id, display_name, color),
        ).fetchone()
        staff_ids.append(row[0])

        # Lunes (1) a sábado (6), 09:00 a 18:00.
        for weekday in range(1, 7):
            conn.execute(
                """
                insert into public.staff_schedules
                    (business_id, staff_id, weekday, start_time, end_time)
                values (%s, %s, %s, '09:00', '18:00')
                """,
                (business_id, row[0], weekday),
            )
    return staff_ids


def _create_clients(conn: psycopg.Connection, business_id: str) -> list[str]:
    client_ids: list[str] = []
    for full_name, phone, notes in CLIENTS:
        row = conn.execute(
            """
            insert into public.clients (business_id, full_name, phone, notes)
            values (%s, %s, %s, %s)
            returning id
            """,
            (business_id, full_name, phone, notes),
        ).fetchone()
        client_ids.append(row[0])
    return client_ids


def _status_for(day_offset: int, hour: int, rng: random.Random) -> str:
    """Pasado mayormente completado; hoy y futuro confirmadas o pendientes."""
    if day_offset < 0:
        draw = rng.random()
        if draw < 0.82:
            return "completada"
        if draw < 0.92:
            return "no_asistio"
        return "cancelada"
    if day_offset == 0:
        return "confirmada" if hour < 14 else "pendiente"
    return "confirmada" if rng.random() < 0.7 else "pendiente"


def _create_appointments(
    conn: psycopg.Connection,
    business_id: str,
    owner_id: str,
    services: list[tuple[str, int]],
    staff_ids: list[str],
    client_ids: list[str],
    today: date,
) -> int:
    tz = ZoneInfo(DEMO_TIMEZONE)
    rng = random.Random(20260118)
    total = 0

    for day_offset in range(-DAYS_BACK, DAYS_AHEAD + 1):
        day = today + timedelta(days=day_offset)
        if day.weekday() == 6:  # domingo: cerrado
            continue

        for staff_index, hour in SLOTS:
            if day_offset > DAYS_AHEAD - 3 and rng.random() < 0.35:
                continue  # los últimos días quedan medio libres

            service_id, duration = rng.choice(services)
            client_id = rng.choice(client_ids)
            status = _status_for(day_offset, hour, rng)

            starts_local = datetime.combine(day, time(hour, 0), tzinfo=tz)
            ends_local = starts_local + timedelta(minutes=duration)

            conn.execute(
                """
                insert into public.appointments
                    (business_id, client_id, service_id, staff_id, starts_at,
                     ends_at, status, price, created_by, confirmed_at,
                     canceled_reason)
                values (%s, %s, %s, %s, %s, %s, %s,
                        (select price from public.services where id = %s), %s,
                        case when %s in ('confirmada', 'completada')
                             then %s::timestamptz else null end,
                        case when %s = 'cancelada'
                             then 'Cancelada por el cliente' else null end)
                """,
                (
                    business_id,
                    client_id,
                    service_id,
                    staff_ids[staff_index],
                    starts_local.astimezone(ZoneInfo("UTC")),
                    ends_local.astimezone(ZoneInfo("UTC")),
                    status,
                    service_id,
                    owner_id,
                    status,
                    starts_local.astimezone(ZoneInfo("UTC")),
                    status,
                ),
            )
            total += 1

    return total


def main() -> int:
    parser = argparse.ArgumentParser(description="Crea el negocio demo de revisión.")
    parser.add_argument("--email", default=DEFAULT_EMAIL, help="Correo del usuario demo")
    parser.add_argument("--password", default=DEFAULT_PASSWORD, help="Contraseña demo")
    args = parser.parse_args()

    settings = get_settings()
    supabase_url = settings.supabase_url.rstrip("/")
    if not supabase_url or not settings.database_url:
        raise SystemExit("Faltan SUPABASE_URL o DATABASE_URL en backend/.env")

    service_role_key = resolve_service_role_key(settings.supabase_service_role_key)
    owner_id = ensure_demo_user(
        supabase_url,
        settings.supabase_anon_key,
        service_role_key,
        args.email,
        args.password,
    )
    print(f"Usuario demo listo: {args.email} ({owner_id})")

    today = datetime.now(ZoneInfo(DEMO_TIMEZONE)).date()

    with psycopg.connect(settings.database_url, autocommit=False) as conn:
        _clear_demo_business(conn)
        business_id = _create_business(conn, owner_id)
        services = _create_services(conn, business_id)
        staff_ids = _create_staff(conn, business_id)
        client_ids = _create_clients(conn, business_id)
        appointments = _create_appointments(
            conn, business_id, owner_id, services, staff_ids, client_ids, today
        )
        conn.commit()

    print(f"Negocio demo: {DEMO_BUSINESS_NAME} ({business_id})")
    print(f"  servicios: {len(services)} · empleados: {len(staff_ids)} · "
          f"clientes: {len(client_ids)} · citas: {appointments}")
    print()
    print("Credenciales para Play Console → Acceso a la app:")
    print(f"  Usuario:    {args.email}")
    print(f"  Contraseña: {args.password}")
    print()
    print("Las citas cubren desde hace %s días hasta dentro de %s días."
          % (DAYS_BACK, DAYS_AHEAD))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
