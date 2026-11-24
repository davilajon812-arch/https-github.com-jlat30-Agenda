-- Fase 5 - 0016: cupo propio para las reservas que llegan por el enlace público.
--
-- Antes había una sola bolsa de citas: las reservas hechas por los clientes
-- desde el enlace consumían el mismo cupo que las citas que el negocio agenda a
-- mano. El resultado era injusto en los dos sentidos: un negocio que recibía
-- 20 reservas por el link se quedaba con 80 para su propia agenda, y al revés,
-- agendar a mano dejaba a los clientes sin poder reservar.
--
-- Ahora son dos bolsas independientes que se suman:
--   * `max_appointments_per_month`: citas que agenda el negocio desde la app.
--   * `max_online_bookings_per_month`: citas que entran por el enlace público.
--
-- Ambas usan la misma regla de conteo: citas atendibles del mes en curso (por
-- `starts_at`, sin canceladas ni no-shows). El plan Gratis queda en 100 + 50.

alter table public.plans
    add column if not exists max_online_bookings_per_month integer
        check (max_online_bookings_per_month is null
               or max_online_bookings_per_month >= 0);

update public.plans
set max_online_bookings_per_month = 50
where id = 'free';

comment on column public.plans.max_appointments_per_month is
    'Cupo de citas al mes agendadas por el negocio desde la app (no cuentan las del enlace público). Por starts_at, sin canceladas ni no-shows. null = ilimitado.';

comment on column public.plans.max_online_bookings_per_month is
    'Cupo de reservas al mes recibidas por el enlace público (booked_online). Por starts_at, sin canceladas ni no-shows. null = ilimitado.';
