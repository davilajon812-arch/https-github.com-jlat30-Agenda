-- Fase 5 - 0014: dirección del negocio para el enlace público.
--
-- Quien reserva por internet necesita saber a dónde ir. La app nunca llegó a
-- usar la tabla `locations`, así que la dirección vive en el propio negocio:
-- el plan permite una sola sede y así el dato está donde se edita el perfil.

alter table public.businesses
    add column if not exists address text;

comment on column public.businesses.address is
    'Dirección que se muestra en la página pública de reservas; null si no se indicó.';
