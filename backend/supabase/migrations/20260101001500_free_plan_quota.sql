-- Fase 5 - 0015: cupo de citas del plan Gratis y limpieza de límites fantasma.
--
-- El plan Gratis arrancó con 30 citas al mes, que en un negocio de una sola
-- persona se agotan en 3-5 días: no alcanza para formar el hábito ni para
-- probar el enlace público. Se sube a 100, que es aproximadamente medio mes de
-- un profesional ocupado.
--
-- Además se anulan los límites que la app anuncia pero no aplica:
--   * `max_messages_per_month`: nada envía mensajes todavía (el recordatorio es
--     un botón de WhatsApp que abre el negocio). Anunciar "0 mensajes" en el
--     plan Gratis era una carencia que no existe.
--   * `max_locations`: no hay pantalla de sedes; la dirección vive en el
--     propio negocio. Se deja sin límite para no prometer algo inexistente.

update public.plans
set max_appointments_per_month = 100
where id = 'free';

update public.plans
set max_messages_per_month = null,
    max_locations = null;

comment on column public.plans.max_appointments_per_month is
    'Cupo de citas atendibles al mes (por starts_at, sin canceladas ni no-shows). null = ilimitado.';
