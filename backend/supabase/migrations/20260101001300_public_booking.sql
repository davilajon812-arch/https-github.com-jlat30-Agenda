-- Fase 5 - 0013: enlace público de reservas por cita.
--
-- El cliente final reserva sin cuenta desde una página web. Para que pueda
-- consultar o cancelar SU cita sin exponer el id interno, cada cita recibe un
-- token aleatorio e irrepetible que solo conoce quien la creó.

alter table public.appointments
    add column if not exists public_token text;

-- Rellena las citas que ya existen con un token distinto para cada una.
update public.appointments
set public_token = replace(gen_random_uuid()::text, '-', '')
where public_token is null;

alter table public.appointments
    alter column public_token set default replace(gen_random_uuid()::text, '-', ''),
    alter column public_token set not null;

create unique index if not exists appointments_public_token_key
    on public.appointments (public_token);

comment on column public.appointments.public_token is
    'Token opaco para que el cliente consulte o cancele su cita desde el '
    'enlace público, sin cuenta y sin exponer el id de la cita.';

-- Reservas hechas desde el enlace público (el resto vienen de la app).
alter table public.appointments
    add column if not exists booked_online boolean not null default false;

comment on column public.appointments.booked_online is
    'true si la cita la creó el cliente desde el enlace público de reservas.';

-- El negocio puede activar o desactivar el enlace público.
alter table public.businesses
    alter column public_booking_enabled set default true;
