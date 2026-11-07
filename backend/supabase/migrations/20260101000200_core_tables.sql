-- Fase 1 - 0002: tablas del núcleo del negocio.
-- Todas las tablas quedan ligadas a un negocio (multi-tenant) excepto profiles.

-- Perfil de cada usuario registrado (dueño o empleado).
create table if not exists public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    full_name text,
    phone text,
    locale text not null default 'es',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Perfil de usuario de la plataforma (dueño o empleado).';

-- Negocio: el cliente que paga la suscripción.
create table if not exists public.businesses (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references public.profiles (id) on delete restrict,
    name text not null check (length(btrim(name)) between 1 and 120),
    slug text not null unique check (slug ~ '^[a-z0-9-]{3,60}$'),
    industry text,
    country_code text not null default 'NI' check (country_code ~ '^[A-Z]{2}$'),
    currency text not null default 'NIO' check (currency ~ '^[A-Z]{3}$'),
    timezone text not null default 'America/Managua',
    phone text,
    public_booking_enabled boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.businesses is 'Negocio con agenda (barbería, salón, taller, etc.).';

-- Miembros del negocio con su rol.
create table if not exists public.business_members (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    profile_id uuid not null references public.profiles (id) on delete cascade,
    role text not null default 'staff' check (role in ('owner', 'staff')),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint business_members_unique_member unique (business_id, profile_id)
);

comment on table public.business_members is 'Relación negocio-usuario con rol owner o staff.';

-- Sedes del negocio.
create table if not exists public.locations (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(btrim(name)) between 1 and 120),
    address text,
    phone text,
    timezone text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Servicios que ofrece el negocio.
create table if not exists public.services (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(btrim(name)) between 1 and 120),
    description text,
    duration_minutes integer not null default 30
        check (duration_minutes between 5 and 600),
    price numeric(12, 2) not null default 0 check (price >= 0),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Clientes del negocio (nunca "pacientes").
create table if not exists public.clients (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    full_name text not null check (length(btrim(full_name)) between 1 and 120),
    phone text not null check (length(phone) between 6 and 20),
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint clients_unique_phone_per_business unique (business_id, phone)
);

-- Citas del negocio.
create table if not exists public.appointments (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    location_id uuid references public.locations (id) on delete set null,
    client_id uuid not null references public.clients (id) on delete restrict,
    service_id uuid references public.services (id) on delete set null,
    staff_id uuid references public.profiles (id) on delete set null,
    starts_at timestamptz not null,
    ends_at timestamptz not null,
    status text not null default 'pendiente'
        check (status in ('pendiente', 'confirmada', 'completada', 'cancelada', 'no_asistio')),
    price numeric(12, 2) check (price >= 0),
    notes text,
    created_by uuid references public.profiles (id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint appointments_time_valid check (ends_at > starts_at)
);

comment on table public.appointments is 'Cita agendada con un cliente del negocio.';

-- Suscripción del negocio (Play Billing hoy, Stripe a futuro).
create table if not exists public.subscriptions (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    plan text not null default 'free' check (plan in ('free', 'basico', 'pro')),
    status text not null default 'active'
        check (status in ('active', 'grace', 'pending', 'canceled', 'expired', 'paused')),
    source text not null default 'play' check (source in ('play', 'stripe', 'manual')),
    product_id text,
    purchase_token text,
    current_period_start timestamptz,
    current_period_end timestamptz,
    auto_renewing boolean not null default false,
    last_event_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.subscriptions is 'Estado de la suscripción del negocio por proveedor (play, stripe).';
comment on column public.subscriptions.source is 'Permite añadir Stripe después sin cambiar el esquema.';

-- Contadores mensuales usados para aplicar los límites del plan.
create table if not exists public.usage_counters (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    period_start date not null,
    period_end date not null,
    appointments_count integer not null default 0 check (appointments_count >= 0),
    messages_count integer not null default 0 check (messages_count >= 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint usage_counters_period_valid check (period_end > period_start),
    constraint usage_counters_unique_period unique (business_id, period_start)
);
