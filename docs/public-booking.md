# Página pública de reservas

El negocio comparte un enlace y sus clientes reservan solos, **sin instalar la
app y sin cuenta**. Es la funcionalidad que convierte la agenda en una
herramienta que también le sirve al cliente final.

## Cómo funciona

```
Cliente  →  https://<api>/r/<slug>          (página web, HTML + JS)
                 │
                 ├─ GET  /api/v1/public/<slug>                     negocio, servicios, personal
                 ├─ GET  /api/v1/public/<slug>/availability?…      huecos libres del día
                 ├─ POST /api/v1/public/<slug>/appointments        crear la cita
                 ├─ GET  /api/v1/public/<slug>/appointments/<tok>  consultar la cita
                 └─ POST /api/v1/public/<slug>/appointments/<tok>/cancel
```

- El negocio se identifica por su **slug público** (`businesses.slug`); el id
  interno nunca se expone.
- Cada cita recibe un **token opaco** (`appointments.public_token`) que el
  cliente guarda en su enlace `?c=<token>` para consultar o cancelar.
- La cita entra **confirmada** (`status = confirmada`, `booked_online = true`)
  y aparece en la agenda de la app al instante.

## Archivos

| Archivo | Papel |
| ------- | ----- |
| `backend/app/api/routes/public.py` | Endpoints JSON públicos |
| `backend/app/api/routes/public_page.py` | Página `/r/{slug}` (HTML+CSS+JS autocontenida) |
| `backend/app/services/public_booking.py` | Reglas: disponibilidad, cliente, plan, anti-abuso |
| `backend/app/core/ratelimit.py` | Límite de peticiones en memoria |
| `backend/app/schemas/public.py` | Contratos de entrada y salida |
| `backend/supabase/migrations/20260101001300_public_booking.sql` | `public_token` y `booked_online` |
| `mobile/lib/features/business/presentation/public_link_screen.dart` | Pantalla "Reservas en línea" (QR, copiar, compartir) |
| `mobile/lib/features/client_booking/` | Entrada pública del cliente (`/book`) y parser del enlace |

## Qué ve el cliente

| Bloque | Contenido |
| ------ | --------- |
| Cabecera | Nombre del negocio, rubro, **horario de atención** resumido, **dirección**, botón de llamada y "Cómo llegar" (Google Maps) |
| Servicios | Menú completo con duración, descripción y precio |
| Profesional | "Cualquiera" (por defecto) o un empleado concreto |
| Horarios | Una fila por hora real: con "Cualquiera" muestra cuántos profesionales están libres a esa hora |
| Confirmación | Resumen con servicio, fecha, con quién, precio y **dónde** (con enlace al mapa) |

Si el negocio no tiene ningún empleado con horario, la página no ofrece servicios:
muestra un aviso y un botón para escribirle por WhatsApp.

## Reglas aplicadas

1. **Solo huecos reales.** La reserva se valida contra
   `compute_availability`: horario del empleado, citas y bloqueos existentes, y
   nada en el pasado. Si el hueco desapareció, responde `409`.
2. **Plan del negocio.** Respeta el tope de citas por mes del plan Gratis
   (`402 plan_limit_reached`, igual que en la app).
3. **Cliente reutilizado.** Si el teléfono ya existe en el negocio, la cita se
   cuelga de ese cliente en vez de duplicarlo.
4. **Reparto automático.** Cuando el cliente elige "Cualquiera", la cita va al
   empleado libre con menos citas ese día, no siempre al primero de la lista.
5. **Anti-abuso.** 6 reservas por minuto y por IP, 90 lecturas por minuto, y un
   máximo de 3 citas activas del mismo teléfono en el mismo día.
6. **Zona horaria.** La página muestra siempre la hora del negocio, aunque el
   visitante esté en otro país.

## La dirección

Vive en `businesses.address` (migración 0014) y se edita en **Ajustes → Mi
negocio → Editar datos**. Se usa para el bloque "Dónde" de la cita y para el
botón "Cómo llegar", que abre una búsqueda de Google Maps con el nombre y la
dirección: no hace falta geocodificar ni guardar coordenadas.

Se eligió el negocio y no la tabla `locations` porque el plan solo permite una
sede y la app nunca llegó a usar esa tabla.

## Activarlo

En la app: **Ajustes → Mi negocio → Reservas en línea**. Ahí se enciende o
apaga el enlace, se copia, se comparte y se ve el QR para imprimir.

Para el negocio demo ya viene encendido y el enlace es:

```
https://agendapro-api-469f.onrender.com/r/barberia-demo
```

## El cliente sin cuenta, desde la app

La pantalla de login tiene un enlace discreto **"Solo quiero reservar una cita"**
que abre `/book`: el cliente pega el enlace (o el código) del negocio y la app
lo lleva a su página de reservas. No hay pantallas de reserva en Flutter: la web
sigue siendo el único lugar donde se agenda, así que no hay lógica duplicada.

El último enlace usado se guarda en `SharedPreferences`
(`client_last_booking_url`) para volver con un toque.

## Cambiar a un dominio propio

Toda la base de los enlaces sale de `PUBLIC_BASE_URL` (con respaldo en
`API_BASE_URL`). El día que haya dominio:

1. Apuntar el dominio a Render y añadirlo en el panel del servicio.
2. Compilar con `--dart-define=PUBLIC_BASE_URL=https://tudominio` (o en
   `.env.prod`).
3. Actualizar `PRIVACY_POLICY_URL` y `TERMS_URL` si cambian de host.

La página se sirve igual en el dominio nuevo: sus enlaces internos son relativos
y `myLink()` arma la URL del cliente con `location.origin`, así que no hay nada
que reescribir.

## Límite conocido

El limitador de peticiones vive en memoria del proceso. Render ejecuta una sola
instancia, así que es suficiente; si se escala a varias instancias hay que
moverlo a un almacén compartido (Redis o una tabla en Postgres).
