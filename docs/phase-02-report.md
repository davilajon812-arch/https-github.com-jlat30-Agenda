# Entrega Fase 2

## 1. Archivos creados o modificados

### Base de datos

| Archivo | Contenido |
| ------- | --------- |
| `backend/supabase/migrations/20260101000600_staff_and_conflicts.sql` | `staff_members`, `staff_schedules`, `staff_blocks`, FK nueva de `appointments.staff_id`, trigger de choques, triggers de consistencia y RLS de las 3 tablas. |

### Backend

| Archivo | Contenido |
| ------- | --------- |
| `app/core/db.py` | Pool de psycopg síncrono (`DATABASE_URL`), dependencia `get_connection`, cierre en el `lifespan`.<br>*Síncrono a propósito*: FastAPI ejecuta los endpoints `def` en el threadpool, así funciona igual en Linux (Render) y en Windows, donde el event loop Proactor no soporta psycopg async. |
| `app/core/timeutils.py` | Parseo de fechas ISO con zona, zona IANA del negocio, límites del día en UTC. |
| `app/services/access.py` | `require_member`, `require_roles`, `require_owner` (404 para negocios ajenos, 403 para roles insuficientes). |
| `app/services/appointments.py` | Duración por servicio, detección de choques y bloqueos, validación de transiciones de estado. |
| `app/services/availability.py` | Cálculo de huecos libres (horario semanal − citas − bloqueos, pasos de 15 min). |
| `app/api/routes/services.py` | CRUD de servicios (baja lógica). |
| `app/api/routes/clients.py` | CRUD, búsqueda por nombre/teléfono e historial de visitas. |
| `app/api/routes/staff.py` | Empleados, reemplazo del horario semanal y bloqueos. |
| `app/api/routes/appointments.py` | Agenda por rango, alta, edición y cambio de estado. |
| `app/api/routes/availability.py` | `GET /availability`. |
| `app/api/router.py`, `app/main.py` | Registro de routers y pool en el ciclo de vida. |
| `app/schemas/{services,clients,staff,appointments,availability}.py` | Modelos de entrada y salida. |
| `tests/database_support.py` | Postgres embebido reutilizable por las pruebas. |
| `tests/api/*` | 29 pruebas de integración de los endpoints. |
| `tests/rls/*` | 24 pruebas de aislamiento (ahora incluyen empleados, horarios, bloqueos y choques). |

### App Flutter

| Archivo | Contenido |
| ------- | --------- |
| `lib/core/api/agenda_api.dart` | Cliente HTTP de la disponibilidad con el token de Supabase. |
| `lib/core/l10n/labels.dart` | Traducciones de estados y días de la semana. |
| `lib/core/utils/whatsapp_launcher.dart` | Apertura de `wa.me` con mensaje prellenado. |
| `lib/features/appointments/domain/appointment.dart` | Modelo y enum de estados. |
| `lib/features/appointments/data/appointments_repository.dart` | Agenda por rango, alta, edición y estados. |
| `lib/features/appointments/presentation/appointments_screen.dart` | Agenda del día y de la semana con navegación de fechas. |
| `lib/features/appointments/presentation/new_appointment_sheet.dart` | Formulario rápido: cliente → servicio → horario libre. |
| `lib/features/appointments/presentation/appointment_detail_screen.dart` | Detalle, acciones de estado y WhatsApp. |
| `lib/features/appointments/presentation/widgets/{appointment_tile,status_chip}.dart` | Fila de cita y etiqueta de estado. |
| `lib/features/clients/**` | Cliente, repositorio, listado con búsqueda, ficha con historial y formulario. |
| `lib/features/services/**` | Servicio, repositorio y catálogo con alta/edición/baja. |
| `lib/features/staff/**` | Empleado, horario y bloqueos; pantalla de horario semanal. |
| `lib/features/settings/presentation/settings_screen.dart` | Accesos a Servicios y Empleados. |
| `lib/app/router/app_router.dart` | Rutas nuevas (`/appointments/:id`, `/clients/:id`, `/services`, `/staff`, `/staff/:id/schedule`). |
| `lib/l10n/app_{es,en}.arb` | ~60 textos nuevos en español e inglés. |
| `test/**` | Pruebas del modelo de cita, del horario y del chip de estado. |

### Documentación

`docs/database.md` (tablas y triggers nuevos), `README.md` (endpoints y notas
del emulador) y este informe.

## 2. Cómo probarla

### Backend

```powershell
cd backend
.venv\Scripts\python.exe -m pytest -q              # 64 pruebas
.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

Contra el proyecto real (migraciones ya aplicadas):

```powershell
$env:SUPABASE_DB_URL="postgresql://postgres.<ref>:<password>@aws-1-<region>.pooler.supabase.com:5432/postgres"
.venv\Scripts\python.exe -m pytest tests/rls -q     # 24 pruebas de aislamiento
```

### App

```powershell
cd mobile
flutter pub get; flutter gen-l10n
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env
flutter analyze      # sin issues
flutter test         # 25 pruebas
```

Flujo de prueba de un día completo (barbería de ejemplo):

1. **Ajustes → Servicios**: crea "Corte" (30 min) y "Barba" (20 min).
2. **Ajustes → Empleados**: crea a "Carlos"; entra a su horario y agrega
   lun–sáb 09:00–18:00.
3. **Clientes**: crea "Juan Pérez" con su teléfono.
4. **Agenda → Nueva cita**: cliente, servicio y un horario libre propuesto por el
   backend. Se crea la cita en estado *pendiente*.
5. Abre la cita: **Confirmar → Completada**, o **Cancelar** (libera el horario).
6. **Abrir WhatsApp**: abre `wa.me` con el mensaje prellenado.
7. Vuelve a la agenda: el horario ocupado ya no aparece en los huecos libres.

## 3. Pendientes y riesgos

| Tema | Detalle |
| ---- | ------- |
| Disponibilidad en el móvil | Requiere el backend accesible: en emulador usa `API_BASE_URL=http://10.0.2.2:8000`. Si no responde, la app muestra un mensaje y no bloquea el resto. |
| Reagendar desde la app | La API expone `PATCH /appointments/{id}`; la app solo cambia estados (reagendar se hace desde la agenda del día). |
| Sedes | `locations` existe en el modelo, pero la UI de sedes llega con los planes de pago (Fase 3). |
| Choques concurrentes | El trigger los detecta por transacción; dos escrituras simultáneas podrían ganar ambas por aislamiento `READ COMMITTED`. Se cerrará con una restricción de exclusión (`btree_gist`) al endurecer la agenda. |
| Zona horaria del dispositivo | La app muestra horas locales del teléfono; el backend calcula huecos en la zona del negocio. Un teléfono en otra zona verá horas desplazadas. |
| Recordatorios | Fase 5 (WhatsApp Cloud API). |
| Flujo público | Fase 4. |
