# Entrega Fases 0 y 1

## 1. Archivos creados

### Raíz

| Archivo | Contenido |
| ------- | --------- |
| `README.md` | Guía para correr backend y app en local, estado de fases. |
| `render.yaml` | Blueprint de Render (`rootDir: backend`, health check `/health`). |
| `.gitignore` | Ignora `.env*` (salvo `.env.example`), logs y artefactos del SO. |

### Backend (`/backend`)

| Archivo | Contenido |
| ------- | --------- |
| `requirements.txt` / `requirements-dev.txt` | Dependencias fijadas (FastAPI, uvicorn, pydantic-settings, PyJWT, pytest, psycopg). |
| `pyproject.toml` | Configuración de pytest y marcador `rls`. |
| `Dockerfile` | Imagen Python 3.12 slim con uvicorn. |
| `.env.example` | Variables necesarias (app, CORS, Supabase). |
| `app/main.py` | `create_app()`: CORS, middlewares, routers, arranque de logging. |
| `app/core/config.py` | `Settings` con pydantic-settings y parseo de `CORS_ORIGINS`. |
| `app/core/logging.py` | Logging a stdout con formato único. |
| `app/core/security.py` | `SupabaseTokenVerifier` (HS256 o JWKS) y `AuthenticatedUser`. |
| `app/middleware/auth.py` | Extrae el Bearer y deja `request.state.user`. |
| `app/middleware/request_logging.py` | Método, ruta, estado y duración. |
| `app/api/deps.py` | `get_current_user` / `get_optional_user`. |
| `app/api/router.py`, `app/api/routes/health.py`, `app/api/routes/me.py` | `GET /health`, `GET /api/v1/me`. |
| `app/schemas/common.py`, `app/schemas/auth.py` | Modelos de respuesta. |
| `app/services/__init__.py` | Reservado para la lógica de las siguientes fases. |
| `supabase/migrations/20260101000100_extensions.sql` | `pgcrypto` tolerante a entornos sin contrib. |
| `supabase/migrations/20260101000200_core_tables.sql` | `profiles`, `businesses`, `business_members`, `locations`, `services`, `clients`, `appointments`, `subscriptions`, `usage_counters`. |
| `supabase/migrations/20260101000300_indexes.sql` | Índices de agenda, clientes, sedes y facturación. |
| `supabase/migrations/20260101000400_functions_and_triggers.sql` | Funciones de RLS, `handle_new_user`, `handle_new_business`, consistencia de citas, `updated_at`. |
| `supabase/migrations/20260101000500_rls_policies.sql` | RLS y políticas por rol en las 9 tablas. |
| `tests/conftest.py`, `tests/test_health.py`, `tests/test_auth.py` | Pruebas de `/health`, CORS y JWT (válido, expirado, firma y audiencia). |
| `tests/rls/conftest.py`, `tests/rls/test_isolation.py` | Infraestructura y 17 pruebas de aislamiento multi-tenant. |

### App Flutter (`/mobile`)

| Archivo | Contenido |
| ------- | --------- |
| `pubspec.yaml` | Riverpod, go_router, supabase_flutter, intl, shared_preferences, `generate: true`. |
| `l10n.yaml`, `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` | Español (plantilla) e inglés. |
| `lib/main.dart`, `lib/main_dev.dart`, `lib/main_prod.dart`, `lib/bootstrap.dart` | Arranque por flavor, `Supabase.initialize`, pantalla de "falta configuración". |
| `lib/app/app.dart` | `MaterialApp.router` con tema claro/oscuro e idioma. |
| `lib/app/app_gate.dart` | Onboarding vs app, estados de carga y error. |
| `lib/app/home_shell.dart` | Navegación por pestañas (agenda, clientes, plan, ajustes). |
| `lib/app/router/app_router.dart`, `lib/app/router/router_refresh.dart` | Rutas y `redirect` por sesión. |
| `lib/core/config/app_config.dart` | `AppFlavor` y `AppConfig` desde `--dart-define`. |
| `lib/core/providers/app_providers.dart` | Supabase, preferencias y repositorios. |
| `lib/core/preferences/preferences_controller.dart` | Tema e idioma persistidos. |
| `lib/core/theme/app_theme.dart` | Material 3 claro/oscuro. |
| `lib/core/widgets/error_view.dart`, `placeholder_view.dart` | Estados de error y "próximamente". |
| `lib/features/auth/**` | Repositorio, providers, login, registro, recuperación y traducción de errores. |
| `lib/features/business/**` | Dominio, repositorio (slug único), providers y onboarding. |
| `lib/features/appointments|clients|billing|settings/**` | Pantallas base; ajustes ya funcional. |
| `lib/.env.example` → `mobile/.env.example` | Variables de compilación. |
| `android/app/build.gradle.kts` | Flavors `dev`/`prod` con `applicationIdSuffix` y nombre. |
| `android/app/src/main/AndroidManifest.xml` | Permiso `INTERNET` y `@string/app_name`. |
| `test/**` | Configuración, slugs, preferencias y pantalla de login. |

### Documentación (`/docs`)

`architecture.md`, `database.md` (diagrama Mermaid + RLS), `supabase-setup.md`,
`deploy-render.md` y este informe.

## 2. Cómo probar

### Backend

```powershell
cd backend
uv venv --python 3.12 .venv
uv pip install --python .venv\Scripts\python.exe -r requirements-dev.txt
.venv\Scripts\python.exe -m pytest
.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

- `GET http://localhost:8000/health` → `{"status":"ok", ...}`
- `GET http://localhost:8000/api/v1/me` sin token → `401`
- Con token válido → `{"id": "...", "email": "...", "role": "authenticated"}`

### Base de datos

1. Aplica las migraciones (ver `docs/supabase-setup.md`).
2. `pytest tests/rls -v`: 17 pruebas que demuestran el aislamiento entre negocios
   (por defecto con Postgres embebido; con `SUPABASE_DB_URL` contra tu proyecto).

### App

```powershell
cd mobile
flutter pub get
flutter gen-l10n
Copy-Item .env.example .env    # completa SUPABASE_URL y SUPABASE_ANON_KEY
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env
flutter analyze
flutter test
```

Flujo esperado: registro → onboarding del negocio → pantalla principal con
pestañas. En **Ajustes** se cambian tema e idioma (persistidos) y se cierra sesión.

## 3. Pendientes y riesgos

| Tema | Detalle |
| ---- | ------- |
| Confirm email | Con "Confirm email" activo en Supabase, tras registrarse hay que confirmar antes de entrar (la app muestra el aviso). |
| Verificación de JWT | Si el proyecto usa llaves asimétricas, deja `SUPABASE_JWT_SECRET` vacío: el backend descarga el JWKS. |
| Render free | El servicio se duerme por inactividad; la primera petición tarda ~30 s. |
| Múltiples negocios | Hoy `AppGate` usa el primer negocio del usuario; el selector llega con la Fase 2. |
| iOS flavors | Solo se configuraron flavors en Android; para iOS se necesitan esquemas/xcconfig (fase de publicación). |
| Firma de la app | `release` sigue firmando con la llave de debug; se reemplaza en la Fase 8. |
| Idioma | Inglés traducido en los textos de la interfaz; falta revisar textos nuevos de las próximas fases. |
| Fase 2 | Servicios, clientes, empleados, horarios, citas y disponibilidad aún no existen. |
