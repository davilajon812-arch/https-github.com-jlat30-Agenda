# Cuenta demo para la revisión de Google Play

Google Play exige **credenciales de acceso** cuando la app no se puede usar sin
iniciar sesión. Un revisor que se registre desde cero solo vería el alta del
negocio y una agenda vacía, y eso se rechaza como *"funcionalidad mínima"*.

Para evitarlo existe un negocio de demostración con datos reales.

## Crear o refrescar los datos

```powershell
cd backend
.venv\Scripts\python.exe scripts\seed_demo.py
```

El script es **idempotente**: borra el negocio demo anterior y lo vuelve a crear.
Las citas se generan **alrededor de la fecha en que se ejecuta**, así que hay
que correrlo otra vez antes de cada envío a la tienda. Si las fechas caducan, el
revisor abre una agenda en el pasado.

Opcionalmente se pueden cambiar las credenciales:

```powershell
.venv\Scripts\python.exe scripts\seed_demo.py --email otro@correo.com --password OtraClave2026!
```

## Qué crea

| Elemento | Detalle |
| -------- | ------- |
| Usuario | `demo@agendapro.app`, correo ya confirmado (sin verificación) |
| Negocio | **Barbería El Buen Corte**, Managua, NIO, plan **Pro** manual |
| Servicios | Corte clásico (30 min/150), Corte + barba (45/250), Afeitado (20/100), Tinte (60/450) |
| Empleados | Carlos Mendoza, María López, José Ruiz — lunes a sábado, 09:00–18:00 |
| Clientes | 10 con nombres y teléfonos nicaragüenses |
| Citas | ~73 desde 14 días atrás hasta 7 días adelante |

Las citas se reparten con estados variados para que se vean todas las pantallas:

- **Pasadas**: mayormente `completada`, algunas `no_asistio` y `cancelada`.
- **Hoy**: `confirmada` por la mañana, `pendiente` por la tarde.
- **Próximos días**: `confirmada` o `pendiente`.

El plan Pro es `source = manual`, es decir **no se cobra**: el revisor ve la app
sin límites y sin pasar por Google Play.

## Dónde se usan las credenciales

Play Console → **Presencia en la tienda → Acceso a la app**:

```
Nombre de usuario: demo@agendapro.app
Contraseña:        AgendaDemo2026!
Instrucciones:     Inicia sesión con estas credenciales. La app abre en la
                   agenda del negocio "Barbería El Buen Corte", con citas de
                   hoy y de los próximos días. Recorre las pestañas Agenda,
                   Clientes, Plan y Ajustes. La suscripción Pro ya está activa,
                   así que no hace falta comprar nada.
```

## Para poder probar la compra

El negocio demo ya está en Pro, así que el flujo de pago no se ejercita. Si se
quiere validar:

1. Play Console → **Configuración → Pruebas de licencias** → añadir el correo del
   revisor como *license tester*.
2. Crear una cuenta nueva desde la app (queda en plan Gratis) y comprar el plan
   Pro. Con un tester de licencias no se cobra.

## Cambiar los datos

Todo está en `backend/scripts/seed_demo.py`:

| Constante | Para qué |
| --------- | -------- |
| `DEFAULT_EMAIL` / `DEFAULT_PASSWORD` | Credenciales del usuario demo |
| `DEMO_BUSINESS_NAME`, `DEMO_SLUG` | Nombre y slug del negocio |
| `DAYS_BACK`, `DAYS_AHEAD` | Ventana de fechas de las citas |
| `SERVICES`, `STAFF`, `CLIENTS` | Catálogo y personas |
| `SLOTS` | Reparto de horas por empleado |
