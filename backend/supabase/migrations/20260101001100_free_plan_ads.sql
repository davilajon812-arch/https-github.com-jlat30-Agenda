-- Fase 4 - 0011: el plan Gratis muestra anuncios.
--
-- La app decide si muestra el banner leyendo `plans.features.ads`, no un id de
-- plan escrito en el código: así se puede activar o desactivar sin desplegar
-- una versión nueva de la app.

update public.plans
set features = features || '{"ads": true}'::jsonb,
    updated_at = now()
where id = 'free';

update public.plans
set features = features || '{"ads": false}'::jsonb,
    updated_at = now()
where id = 'pro';

comment on column public.plans.features is
    'Funciones del plan. `ads` indica si la app muestra anuncios a ese plan.';
