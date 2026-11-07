-- Fase 3 - 0007: planes, facturación y contadores.
--
-- Los planes (límites y features) viven en la tabla `plans` para poder
-- ajustarlos sin desplegar. Los precios NO se guardan aquí: se leen siempre
-- desde Google Play en la app.

create table if not exists public.plans (
    id text primary key check (id in ('free', 'basico', 'pro')),
    name text not null,
    -- Identificador del producto de suscripción en Google Play (null = no comprable).
    play_product_id text unique,
    -- null significa "sin límite".
    max_staff integer check (max_staff is null or max_staff >= 0),
    max_locations integer check (max_locations is null or max_locations >= 0),
    max_appointments_per_month integer
        check (max_appointments_per_month is null or max_appointments_per_month >= 0),
    max_messages_per_month integer
        check (max_messages_per_month is null or max_messages_per_month >= 0),
    features jsonb not null default '{}'::jsonb,
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.plans is 'Catálogo de planes con sus límites; se puede ajustar sin redeploy.';
comment on column public.plans.play_product_id is 'ID del producto de suscripción en Play Console.';

insert into public.plans (
    id, name, play_product_id, max_staff, max_locations,
    max_appointments_per_month, max_messages_per_month, features, sort_order
) values
    ('free', 'Gratis', null, 1, 1, 30, 0,
     '{"reminders": false, "advanced_reports": false, "custom_branding": false}'::jsonb, 1),
    ('basico', 'Básico', 'agendapro_basico_mensual', 3, 1, null, 200,
     '{"reminders": true, "advanced_reports": false, "custom_branding": false}'::jsonb, 2),
    ('pro', 'Pro', 'agendapro_pro_mensual', null, null, null, 1000,
     '{"reminders": true, "advanced_reports": true, "custom_branding": true}'::jsonb, 3)
on conflict (id) do update set
    name = excluded.name,
    play_product_id = excluded.play_product_id,
    max_staff = excluded.max_staff,
    max_locations = excluded.max_locations,
    max_appointments_per_month = excluded.max_appointments_per_month,
    max_messages_per_month = excluded.max_messages_per_month,
    features = excluded.features,
    sort_order = excluded.sort_order;

-- ---------------------------------------------------------------------------
-- Datos extra de la suscripción (necesarios para Play y para Stripe después)
-- ---------------------------------------------------------------------------
alter table public.subscriptions
    add column if not exists google_order_id text,
    add column if not exists acknowledged_at timestamptz,
    add column if not exists grace_until timestamptz,
    add column if not exists canceled_at timestamptz,
    add column if not exists external_account_id text,
    add column if not exists latest_event_type text,
    add column if not exists raw_status text;

create index if not exists subscriptions_status_period_idx
    on public.subscriptions (status, current_period_end);

-- ---------------------------------------------------------------------------
-- Auditoría de facturación: cada verificación y cada notificación RTDN.
-- ---------------------------------------------------------------------------
create table if not exists public.billing_events (
    id uuid primary key default gen_random_uuid(),
    business_id uuid references public.businesses (id) on delete cascade,
    source text not null default 'play' check (source in ('play', 'stripe', 'manual')),
    event_type text not null,
    product_id text,
    purchase_token text,
    payload jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

comment on table public.billing_events is 'Bitácora de eventos de facturación para auditoría.';

create index if not exists billing_events_business_idx
    on public.billing_events (business_id, created_at desc);

create index if not exists billing_events_token_idx
    on public.billing_events (purchase_token) where purchase_token is not null;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.plans enable row level security;
alter table public.billing_events enable row level security;

drop policy if exists plans_select_authenticated on public.plans;
create policy plans_select_authenticated
    on public.plans for select
    to authenticated
    using (is_active);

drop policy if exists billing_events_select_owner on public.billing_events;
create policy billing_events_select_owner
    on public.billing_events for select
    to authenticated
    using (public.is_business_owner(business_id));

revoke all on public.plans, public.billing_events from anon;
grant select on public.plans to authenticated;
grant select on public.billing_events to authenticated;

-- ---------------------------------------------------------------------------
-- updated_at de plans
-- ---------------------------------------------------------------------------
drop trigger if exists set_updated_at on public.plans;
create trigger set_updated_at before update on public.plans
    for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Toda cuenta nueva arranca en el plan gratuito.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_business()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    insert into public.business_members (business_id, profile_id, role)
    values (new.id, new.owner_id, 'owner')
    on conflict (business_id, profile_id) do update set role = 'owner';

    insert into public.subscriptions (
        business_id, plan, status, source, current_period_start,
        current_period_end, auto_renewing
    )
    values (
        new.id, 'free', 'active', 'manual', now(), now() + interval '100 years', false
    )
    on conflict do nothing;

    return new;
end;
$$;
