# Entrega Fase 3

## 1. Archivos creados o modificados

### Base de datos

| Archivo | Contenido |
| ------- | --------- |
| `backend/supabase/migrations/20260101000700_plans_and_billing.sql` | Tabla `plans` con límites ajustables (free/pro; el plan basico se retiro en la migracion 0009) y `play_product_id`; columnas nuevas en `subscriptions` (`google_order_id`, `acknowledged_at`, `grace_until`, `canceled_at`, `external_account_id`, `latest_event_type`, `raw_status`); tabla `billing_events` para auditoría; RLS; trigger que crea la suscripción Gratis al dar de alta el negocio. |

### Backend

| Archivo | Contenido |
| ------- | --------- |
| `app/services/plans.py` | Catálogo de planes (límites + features), con respaldo si falta la tabla. |
| `app/services/entitlements.py` | Plan efectivo, consumo del mes, cupos restantes y error 402 para la app. |
| `app/services/subscriptions.py` | Reglas de vigencia (renovación, gracia, cancelado con periodo activo). |
| `app/services/google_play.py` | Cliente de Play: OAuth JWT de cuenta de servicio, `subscriptionsv2`, `acknowledge`, normalización de estados y `FakeGooglePlayClient`. |
| `app/services/billing.py` | Verificación de compras, aplicación de estado, RTDN (con reconsulta a Play), auditoría y decodificación de Pub/Sub. |
| `app/core/billing_client.py` | Construye el cliente de Play según `BILLING_PROVIDER`. |
| `app/api/routes/billing.py` | `GET /billing/plans`, `GET /businesses/{id}/entitlements`, `POST /billing/verify`, `POST /billing/rtdn`. |
| `app/jobs/daily_maintenance.py` | Reconciliación diaria con Play, expiración de periodos vencidos y apertura del contador mensual. |
| `app/api/routes/internal.py` | `POST /internal/maintenance/daily` protegido con `MAINTENANCE_TOKEN`. |
| `app/api/routes/staff.py`, `appointments.py` | Bloqueo por límite del plan (402) antes de crear empleados o citas. |
| `app/core/config.py` | Variables de Play, RTDN y mantenimiento. |
| `tests/api/test_billing.py` | 14 pruebas: verificación, acknowledge, límites, RTDN (renovación, cancelación, reembolso) y auditoría. |
| `tests/api/test_entitlements.py` | 7 pruebas de planes, cupos y bloqueos 402. |
| `tests/api/test_maintenance.py` | 4 pruebas del cron y del endpoint interno. |

### App Flutter

| Archivo | Contenido |
| ------- | --------- |
| `lib/features/billing/domain/plan.dart` | `Plan`, `PlanUsage`, `Entitlements` y `PlanLimitException`. |
| `lib/features/billing/data/play_billing.dart` | Envoltorio de `in_app_purchase`: carga de productos, compra, stream, restauración y `completePurchase`. |
| `lib/features/billing/presentation/billing_screen.dart` | Plan actual con consumo, comparativa de planes con **precios de Play**, compra, restaurar compras y enlace a la gestión de suscripciones. |
| `lib/features/billing/presentation/providers/billing_providers.dart` | Planes, entitlements, producto de Play y controlador de compra (verifica antes de completar). |
| `lib/features/billing/presentation/widgets/plan_limit_dialog.dart` | Bloqueo amable con invitación a mejorar de plan. |
| `lib/core/api/agenda_api.dart` | `plans`, `entitlements`, `verifyPurchase`, `createStaff`, `createAppointment` con manejo del 402. |
| `lib/features/staff/presentation/staff_screen.dart`, `new_appointment_sheet.dart` | Creación vía backend para que los límites se apliquen. |
| `lib/app/router/app_router.dart` | Ruta `/plan`. |
| `render.yaml` | Variables de Play y cron diario. |

### Documentación

`docs/play-billing-setup.md` (guía completa de Play Console, cuenta de servicio,
Pub/Sub/RTDN y testers) y este informe.

## 2. Cómo probarla

### Sin Play Console (modo simulado)

```powershell
cd backend
$env:BILLING_PROVIDER="fake"
.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

```powershell
# Con un JWT de un dueño de negocio:
curl -X POST http://localhost:8000/api/v1/billing/verify ^
  -H "Authorization: Bearer <token>" -H "Content-Type: application/json" ^
  -d "{\"business_id\":\"<uuid>\",\"product_id\":\"agendapro_pro_mensual\",\"purchase_token\":\"prueba-1\"}"
```

Cualquier token activa el plan Pro (30 días). Luego:
`GET /api/v1/businesses/<uuid>/entitlements` muestra `plan.id = pro` y los
cupos ampliados.

### Con Play Console

Sigue [play-billing-setup.md](play-billing-setup.md) y verifica:

1. Compra de prueba con una cuenta de licencia → plan activo, compra
   *acknowledged*.
2. Cancelación en Play Console → estado `canceled` y el plan sigue activo hasta
   el fin del periodo.
3. Reembolso/revocación → degradación inmediata a Gratis.
4. Plan Gratis: el segundo empleado y la cita 31 devuelven 402 y la app muestra
   el diálogo de mejora.
5. `python -m app.jobs.daily_maintenance` reconsulta suscripciones y abre el mes.

### Pruebas automatizadas

```powershell
cd backend
.venv\Scripts\python.exe -m pytest      # 90 pruebas
cd ..\mobile
flutter analyze; flutter test           # 29 pruebas
```

## 3. Pendientes y riesgos

| Tema | Detalle |
| ---- | ------- |
| Verificación real | Necesita productos activos y cuenta de servicio con permisos; hasta entonces `BILLING_PROVIDER=fake` simula todo. |
| Prueba de compra | Requiere la app instalada desde Play (pruebas internas) con una cuenta de licencia: no funciona con un APK instalado a mano. |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Es un secreto largo: guárdalo solo en Render, nunca en el repositorio ni en el chat. |
| Autenticación de RTDN | Se usa un secreto compartido (`X-Agendapro-Token`). Para endurecerlo, validar el OAuth de Pub/Sub. |
| Prorrateo / cambio de plan | Play no permite cambiar de plan base desde la app sin `updatePurchase`; hoy se compra el nuevo producto y se cancela el anterior desde Play. |
| Consumibles (paquetes de mensajes) | Fase 5. |
| Reembolsos manuales | Se procesan por RTDN; no hay panel de administración todavía. |
| Reloj del servidor | La vigencia se compara en UTC; un desfase del servidor afectaría los bordes del periodo. |
