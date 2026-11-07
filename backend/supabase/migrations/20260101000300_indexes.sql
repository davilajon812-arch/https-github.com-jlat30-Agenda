-- Fase 1 - 0003: índices para las consultas frecuentes.

-- Citas por fecha y negocio (agenda del día y de la semana).
create index if not exists appointments_business_starts_at_idx
    on public.appointments (business_id, starts_at);

-- Citas por empleado y fecha (validación de choques de horario).
create index if not exists appointments_staff_starts_at_idx
    on public.appointments (staff_id, starts_at);

-- Citas por estado dentro del negocio (pendientes, canceladas, etc.).
create index if not exists appointments_business_status_idx
    on public.appointments (business_id, status);

-- Historial de visitas de un cliente.
create index if not exists appointments_client_idx
    on public.appointments (client_id, starts_at desc);

-- Búsqueda de clientes por teléfono.
create index if not exists clients_business_phone_idx
    on public.clients (business_id, phone);

-- Búsqueda de clientes por nombre (insensible a mayúsculas).
create index if not exists clients_business_name_idx
    on public.clients (business_id, lower(full_name));

-- Membresías: saber a qué negocios pertenece un usuario.
create index if not exists business_members_profile_idx
    on public.business_members (profile_id) where is_active;

-- Servicios activos por negocio.
create index if not exists services_business_active_idx
    on public.services (business_id, is_active);

-- Sedes activas por negocio.
create index if not exists locations_business_active_idx
    on public.locations (business_id, is_active);

-- Suscripciones vigentes por negocio.
create index if not exists subscriptions_business_idx
    on public.subscriptions (business_id, current_period_end desc);

-- Un purchase_token de Play solo puede pertenecer a un negocio.
create unique index if not exists subscriptions_purchase_token_key
    on public.subscriptions (purchase_token)
    where purchase_token is not null;
