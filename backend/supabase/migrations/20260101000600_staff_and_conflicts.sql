-- Fase 2 - 0006: empleados, horarios, bloqueos y validación de choques.
--
-- Los empleados pasan a ser un recurso de agenda propio del negocio
-- (`staff_members`), no un usuario del sistema: una barbería puede tener 3
-- estilistas sin que los 3 tengan cuenta. Si un empleado sí tiene cuenta se
-- enlaza con `profile_id`.

-- ---------------------------------------------------------------------------
-- staff_members
-- ---------------------------------------------------------------------------
create table if not exists public.staff_members (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    profile_id uuid references public.profiles (id) on delete set null,
    display_name text not null check (length(btrim(display_name)) between 1 and 120),
    phone text,
    color text not null default '#0F766E' check (color ~ '^#[0-9A-Fa-f]{6}$'),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.staff_members is 'Empleado que atiende citas (con o sin cuenta de usuario).';

create index if not exists staff_members_business_active_idx
    on public.staff_members (business_id, is_active);

create unique index if not exists staff_members_profile_key
    on public.staff_members (business_id, profile_id)
    where profile_id is not null;

-- ---------------------------------------------------------------------------
-- staff_schedules: horario semanal por empleado
-- ---------------------------------------------------------------------------
create table if not exists public.staff_schedules (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    staff_id uuid not null references public.staff_members (id) on delete cascade,
    location_id uuid references public.locations (id) on delete set null,
    weekday smallint not null check (weekday between 0 and 6), -- 0 = domingo
    start_time time not null,
    end_time time not null,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint staff_schedules_time_valid check (end_time > start_time),
    constraint staff_schedules_unique_block
        unique (staff_id, weekday, start_time, end_time)
);

create index if not exists staff_schedules_staff_weekday_idx
    on public.staff_schedules (staff_id, weekday) where is_active;

-- ---------------------------------------------------------------------------
-- staff_blocks: vacaciones, descansos y ausencias puntuales
-- ---------------------------------------------------------------------------
create table if not exists public.staff_blocks (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    staff_id uuid not null references public.staff_members (id) on delete cascade,
    starts_at timestamptz not null,
    ends_at timestamptz not null,
    kind text not null default 'bloqueo'
        check (kind in ('vacacion', 'descanso', 'bloqueo')),
    reason text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint staff_blocks_time_valid check (ends_at > starts_at)
);

create index if not exists staff_blocks_staff_starts_idx
    on public.staff_blocks (staff_id, starts_at);

-- ---------------------------------------------------------------------------
-- appointments.staff_id ahora apunta a staff_members
-- ---------------------------------------------------------------------------
alter table public.appointments drop constraint if exists appointments_staff_id_fkey;
alter table public.appointments
    add constraint appointments_staff_id_fkey
    foreign key (staff_id) references public.staff_members (id) on delete set null;

alter table public.appointments
    add column if not exists reminded_24h_at timestamptz,
    add column if not exists reminded_2h_at timestamptz,
    add column if not exists confirmed_at timestamptz,
    add column if not exists canceled_reason text;

-- El empleado de la cita debe ser del mismo negocio (antes: business_members).
create or replace function public.validate_appointment_consistency()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_ok boolean;
begin
    select exists (
        select 1 from public.clients c
        where c.id = new.client_id and c.business_id = new.business_id
    ) into v_ok;
    if not v_ok then
        raise exception 'El cliente no pertenece al negocio de la cita'
            using errcode = '23514';
    end if;

    if new.service_id is not null then
        select exists (
            select 1 from public.services s
            where s.id = new.service_id and s.business_id = new.business_id
        ) into v_ok;
        if not v_ok then
            raise exception 'El servicio no pertenece al negocio de la cita'
                using errcode = '23514';
        end if;
    end if;

    if new.location_id is not null then
        select exists (
            select 1 from public.locations l
            where l.id = new.location_id and l.business_id = new.business_id
        ) into v_ok;
        if not v_ok then
            raise exception 'La sede no pertenece al negocio de la cita'
                using errcode = '23514';
        end if;
    end if;

    if new.staff_id is not null then
        select exists (
            select 1 from public.staff_members s
            where s.id = new.staff_id and s.business_id = new.business_id
        ) into v_ok;
        if not v_ok then
            raise exception 'El empleado no pertenece al negocio de la cita'
                using errcode = '23514';
        end if;
    end if;

    return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Choques de horario por empleado (citas activas)
-- ---------------------------------------------------------------------------
create or replace function public.validate_appointment_no_overlap()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    -- Sin empleado asignado no hay a quién comparar.
    if new.staff_id is null then
        return new;
    end if;

    -- Citas canceladas o marcadas como no asistió liberan el horario.
    if new.status in ('cancelada', 'no_asistio') then
        return new;
    end if;

    if exists (
        select 1
        from public.appointments a
        where a.business_id = new.business_id
          and a.staff_id = new.staff_id
          and a.id <> new.id
          and a.status not in ('cancelada', 'no_asistio')
          and a.starts_at < new.ends_at
          and a.ends_at > new.starts_at
    ) then
        raise exception 'El empleado ya tiene una cita en ese horario'
            using errcode = '23514';
    end if;

    return new;
end;
$$;

drop trigger if exists validate_appointment_no_overlap on public.appointments;
create trigger validate_appointment_no_overlap
    before insert or update of starts_at, ends_at, staff_id, status
    on public.appointments
    for each row execute function public.validate_appointment_no_overlap();

-- ---------------------------------------------------------------------------
-- Los horarios y bloqueos deben ser del mismo negocio que el empleado
-- ---------------------------------------------------------------------------
create or replace function public.validate_staff_child_consistency()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_ok boolean;
begin
    select exists (
        select 1 from public.staff_members s
        where s.id = new.staff_id and s.business_id = new.business_id
    ) into v_ok;
    if not v_ok then
        raise exception 'El empleado no pertenece al negocio'
            using errcode = '23514';
    end if;
    return new;
end;
$$;

drop trigger if exists validate_schedule_staff on public.staff_schedules;
create trigger validate_schedule_staff
    before insert or update on public.staff_schedules
    for each row execute function public.validate_staff_child_consistency();

drop trigger if exists validate_block_staff on public.staff_blocks;
create trigger validate_block_staff
    before insert or update on public.staff_blocks
    for each row execute function public.validate_staff_child_consistency();

-- ---------------------------------------------------------------------------
-- updated_at
-- ---------------------------------------------------------------------------
do $$
declare
    t text;
begin
    foreach t in array array['staff_members', 'staff_schedules', 'staff_blocks']
    loop
        execute format('drop trigger if exists set_updated_at on public.%I', t);
        execute format(
            'create trigger set_updated_at before update on public.%I
             for each row execute function public.set_updated_at()', t
        );
    end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.staff_members enable row level security;
alter table public.staff_schedules enable row level security;
alter table public.staff_blocks enable row level security;

drop policy if exists staff_members_select_member on public.staff_members;
create policy staff_members_select_member
    on public.staff_members for select
    to authenticated
    using (public.is_business_member(business_id));

drop policy if exists staff_members_insert_owner on public.staff_members;
create policy staff_members_insert_owner
    on public.staff_members for insert
    to authenticated
    with check (public.is_business_owner(business_id));

drop policy if exists staff_members_update_owner on public.staff_members;
create policy staff_members_update_owner
    on public.staff_members for update
    to authenticated
    using (public.is_business_owner(business_id))
    with check (public.is_business_owner(business_id));

drop policy if exists staff_members_delete_owner on public.staff_members;
create policy staff_members_delete_owner
    on public.staff_members for delete
    to authenticated
    using (public.is_business_owner(business_id));

drop policy if exists staff_schedules_select_member on public.staff_schedules;
create policy staff_schedules_select_member
    on public.staff_schedules for select
    to authenticated
    using (public.is_business_member(business_id));

drop policy if exists staff_schedules_write_owner on public.staff_schedules;
create policy staff_schedules_write_owner
    on public.staff_schedules for insert
    to authenticated
    with check (public.is_business_owner(business_id));

drop policy if exists staff_schedules_update_owner on public.staff_schedules;
create policy staff_schedules_update_owner
    on public.staff_schedules for update
    to authenticated
    using (public.is_business_owner(business_id))
    with check (public.is_business_owner(business_id));

drop policy if exists staff_schedules_delete_owner on public.staff_schedules;
create policy staff_schedules_delete_owner
    on public.staff_schedules for delete
    to authenticated
    using (public.is_business_owner(business_id));

drop policy if exists staff_blocks_select_member on public.staff_blocks;
create policy staff_blocks_select_member
    on public.staff_blocks for select
    to authenticated
    using (public.is_business_member(business_id));

drop policy if exists staff_blocks_insert_staff on public.staff_blocks;
create policy staff_blocks_insert_staff
    on public.staff_blocks for insert
    to authenticated
    with check (public.has_business_role(business_id, array['owner', 'staff']));

drop policy if exists staff_blocks_update_staff on public.staff_blocks;
create policy staff_blocks_update_staff
    on public.staff_blocks for update
    to authenticated
    using (public.has_business_role(business_id, array['owner', 'staff']))
    with check (public.has_business_role(business_id, array['owner', 'staff']));

drop policy if exists staff_blocks_delete_staff on public.staff_blocks;
create policy staff_blocks_delete_staff
    on public.staff_blocks for delete
    to authenticated
    using (public.has_business_role(business_id, array['owner', 'staff']));

grant select, insert, update, delete on public.staff_members to authenticated;
grant select, insert, update, delete on public.staff_schedules to authenticated;
grant select, insert, update, delete on public.staff_blocks to authenticated;
revoke all on public.staff_members, public.staff_schedules, public.staff_blocks from anon;
