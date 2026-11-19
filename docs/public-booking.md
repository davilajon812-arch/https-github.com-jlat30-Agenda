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

## Reglas aplicadas

1. **Solo huecos reales.** La reserva se valida contra
   `compute_availability`: horario del empleado, citas y bloqueos existentes, y
   nada en el pasado. Si el hueco desapareció, responde `409`.
2. **Plan del negocio.** Respeta el tope de citas por mes del plan Gratis
   (`402 plan_limit_reached`, igual que en la app).
3. **Cliente reutilizado.** Si el teléfono ya existe en el negocio, la cita se
   cuelga de ese cliente en vez de duplicarlo.
4. **Anti-abuso.** 6 reservas por minuto y por IP, 90 lecturas por minuto, y un
   máximo de 3 citas activas del mismo teléfono en el mismo día.
5. **Zona horaria.** La página muestra siempre la hora del negocio, aunque el
   visitante esté en otro país.

## Activarlo

En la app: **Ajustes → Mi negocio → Reservas en línea**. Ahí se enciende o
apaga el enlace, se copia, se comparte y se ve el QR para imprimir.

Para el negocio demo ya viene encendido y el enlace es:

```
https://agendapro-api-469f.onrender.com/r/barberia-demo
```

## Límite conocido

El limitador de peticiones vive en memoria del proceso. Render ejecuta una sola
instancia, así que es suficiente; si se escala a varias instancias hay que
moverlo a un almacén compartido (Redis o una tabla en Postgres).
