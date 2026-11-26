# AgendaPro

Agenda de citas para negocios de servicios (barberías, salones de belleza, talleres
mecánicos, veterinarias, gimnasios, academias, fotógrafos) en Nicaragua y
Latinoamérica.

- Cliente que paga: **el dueño del negocio** (suscripción mensual).
- Idioma: español neutro latinoamericano + inglés.
- Moneda y zona horaria configurables por negocio.
- Un usuario puede administrar **varios negocios** (función del plan Pro) y
  cambiar entre ellos desde Ajustes.
- Plataforma objetivo: **Android** (Google Play).

## Estructura del monorepo

```
/backend   API en Python 3.12 + FastAPI (Render) y migraciones de Supabase
/mobile    App Flutter para Android con Riverpod, go_router y supabase_flutter
/docs      Documentación de arquitectura, base de datos y despliegue
render.yaml  Blueprint de Render para el backend
```

## Estado de las fases

| Fase | Alcance | Estado |
| ---- | ------- | ------ |
| 0 | Estructura, /health, deploy base, tema, i18n, flavors | ✅ |
| 1 | Modelo de datos, RLS, auth y onboarding del negocio | ✅ |
| 2 | Núcleo de la agenda (servicios, clientes, citas) | ✅ |
| 3 | Suscripciones con Google Play Billing | ✅ |
| 4 | Link de reserva público | ⏳ |

## Requisitos

- Flutter 3.41+ (Dart 3.11+)
- Python 3.12 + [uv](https://docs.astral.sh/uv/)
- Cuenta de [Supabase](https://supabase.com) y de [Render](https://render.com)

## Backend en local

```powershell
cd backend
uv venv --python 3.12 .venv
uv pip install --python .venv\Scripts\python.exe -r requirements-dev.txt
Copy-Item .env.example .env      # completa las variables de Supabase
.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

- Estado del servicio: <http://localhost:8000/health>
- Documentación interactiva: <http://localhost:8000/docs>
- Usuario del token: `GET /api/v1/me` con cabecera `Authorization: Bearer <access_token>`

Endpoints de la Fase 2 (todos bajo `/api/v1/businesses/{business_id}` y con JWT):

| Método | Ruta | Descripción |
| ------ | ---- | ----------- |
| GET/POST | `/services` | Listar y crear servicios |
| PATCH/DELETE | `/services/{id}` | Editar y desactivar |
| GET/POST | `/clients` | Buscar (`?search=`) y crear clientes |
| PATCH/DELETE | `/clients/{id}` | Editar y borrar (si no tiene citas) |
| GET | `/clients/{id}/history` | Historial de visitas |
| GET/POST | `/staff` | Empleados |
| GET/PUT | `/staff/{id}/schedule` | Horario semanal (reemplazo completo) |
| GET/POST/DELETE | `/staff/{id}/blocks` | Vacaciones y descansos |
| GET/POST | `/appointments` | Agenda por rango y alta de citas |
| PATCH | `/appointments/{id}` | Reagendar / editar |
| POST | `/appointments/{id}/status` | Cambiar estado |
| GET | `/availability` | Huecos libres (`service_id`, `date`, `staff_id` opcional) |

Endpoints de facturación (Fase 3):

| Método | Ruta | Descripción |
| ------ | ---- | ----------- |
| GET | `/billing/plans` | Catálogo de planes y límites (precios vienen de Play) |
| GET | `/businesses/{id}/entitlements` | Plan activo, consumo y cupos restantes |
| POST | `/billing/verify` | Verifica la compra en Play, guarda y confirma (*acknowledge*) |
| POST | `/billing/rtdn` | Notificaciones de Pub/Sub (renovación, cancelación, gracia, reembolso) |
| POST | `/internal/maintenance/daily` | Reconciliación manual (requiere `MAINTENANCE_TOKEN`) |

Los límites del plan se aplican en el backend: crear un empleado o una cita por
encima del cupo responde **402** con `{code, limit, plan, upgrade_to}` y la app
muestra un bloqueo amable con invitación a mejorar.

Guía completa de Play Console, cuenta de servicio y RTDN:
[docs/play-billing-setup.md](docs/play-billing-setup.md).

La validación de choques de horario vive en dos capas: el backend responde 409
y un trigger de Postgres (`validate_appointment_no_overlap`) lo impide incluso si
la app escribe directo por Supabase.

Pruebas:

```powershell
cd backend
.venv\Scripts\python.exe -m pytest
```

Las pruebas de RLS usan un Postgres embebido (`pgserver`) y, si defines
`SUPABASE_DB_URL`, se ejecutan contra tu proyecto real (con las migraciones ya
aplicadas y limpiando los datos de prueba al final).

## Base de datos (Supabase)

1. Crea el proyecto en Supabase.
2. Aplica las migraciones de [backend/supabase/migrations](backend/supabase/migrations)
   en orden (`0001` … `0005`).
3. Copia `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY` a
   `backend/.env` y a las variables de Render.

Detalle paso a paso: [docs/supabase-setup.md](docs/supabase-setup.md).

## App Flutter

```powershell
cd mobile
flutter pub get
flutter gen-l10n
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env
```

El archivo `mobile/.env` (no versionado) debe copiarse desde `mobile/.env.example`
y contener `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL` y `APP_FLAVOR`.

> En el **emulador de Android** el host de tu máquina es `10.0.2.2`, así que usa
> `API_BASE_URL=http://10.0.2.2:8000`. En un teléfono físico usa la IP de tu PC
> en la red local (por ejemplo `http://192.168.1.20:8000`).

Sin esas variables la app arranca en una pantalla de "falta configuración" en
lugar de fallar.

Build de producción (AAB para Play Store):

```powershell
flutter build appbundle --flavor prod -t lib/main_prod.dart --dart-define-from-file=.env.prod
```

Pruebas de la app:

```powershell
flutter analyze
flutter test
```

## Despliegue del backend en Render

Ver [docs/deploy-render.md](docs/deploy-render.md). Resumen: crear un *Blueprint*
apuntando a `render.yaml` (rootDir `backend`), definir las variables de Supabase
como secretos y verificar que `GET /health` responda 200.

> Usa la cadena del **pooler** de Supabase (`aws-1-<region>.pooler.supabase.com:5432`),
> no la conexión directa `db.<ref>.supabase.co` (IPv6-only, no alcanzable desde Render).

## Documentación

- [docs/architecture.md](docs/architecture.md): capas, convenciones y flujo de auth.
- [docs/database.md](docs/database.md): diagrama Mermaid y políticas de RLS.
- [docs/supabase-setup.md](docs/supabase-setup.md): crear el proyecto y migrar.
- [docs/deploy-render.md](docs/deploy-render.md): despliegue paso a paso.
- [docs/phase-01-report.md](docs/phase-01-report.md): entrega de las fases 0 y 1.
- [docs/phase-02-report.md](docs/phase-02-report.md): entrega de la fase 2.
- [docs/phase-03-report.md](docs/phase-03-report.md): entrega de la fase 3.
- [docs/play-billing-setup.md](docs/play-billing-setup.md): Play Console, cuenta de servicio y RTDN.
- [docs/google-sign-in.md](docs/google-sign-in.md): "Continuar con Google" (OAuth, SHA-1 y Supabase).
- [docs/demo-account.md](docs/demo-account.md): cuenta demo con datos para la revisión de Play.

## Reglas de cumplimiento (Google Play)

- El dominio es **citas y clientes**: nunca usar términos de salud.
- La app no custodia dinero ni ofrece billeteras o préstamos.
- La suscripción en Android se cobra únicamente con Google Play Billing.
- La app permite **eliminar la cuenta y sus datos** desde Ajustes, y publica su
  [política de privacidad](https://agendapro-api-469f.onrender.com/privacidad) y
  la página de [eliminación de cuenta](https://agendapro-api-469f.onrender.com/eliminar-cuenta).
- Solo se declaran los permisos estrictamente necesarios (`INTERNET`).
