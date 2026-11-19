-- Fase 5 - 0012: registro de pagos de las citas.
--
-- Permite saber si una cita se cobró y con qué medio, para poder mostrar los
-- ingresos del negocio sin depender de una hoja de cálculo aparte.

alter table public.appointments
    add column if not exists paid_at timestamptz,
    add column if not exists amount_paid numeric(12, 2)
        check (amount_paid is null or amount_paid >= 0),
    add column if not exists payment_method text
        check (payment_method is null
               or payment_method in ('efectivo', 'transferencia', 'tarjeta', 'otro'));

comment on column public.appointments.paid_at is
    'Momento en que se registró el cobro; null si aún no se cobró.';
comment on column public.appointments.amount_paid is
    'Importe cobrado. Puede diferir del precio si hubo descuento o propina.';
comment on column public.appointments.payment_method is
    'Medio de pago: efectivo, transferencia, tarjeta u otro.';

-- Los reportes de ingresos filtran por negocio y fecha de cobro.
create index if not exists appointments_business_paid_idx
    on public.appointments (business_id, paid_at)
    where paid_at is not null;
