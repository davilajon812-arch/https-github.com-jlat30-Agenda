-- Fase 1 - 0004: funciones auxiliares, triggers y validaciones.
-- Las funciones SECURITY DEFINER evitan recursión en las políticas de RLS.

-- Mantiene updated_at al día en todas las tablas que lo usan.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

-- ¿El usuario actual es miembro activo del negocio?
create or replace function public.is_business_member(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1
        from public.business_members m
        where m.business_id = p_business_id
          and m.profile_id = auth.uid()
          and m.is_active
    );
$$;

-- ¿El usuario actual es dueño del negocio?
create or replace function public.is_business_owner(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1
        from public.businesses b
        where b.id = p_business_id
          and b.owner_id = auth.uid()
    );
$$;

-- ¿El usuario actual tiene alguno de estos roles en el negocio?
create or replace function public.has_business_role(p_business_id uuid, p_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1
        from public.business_members m
        where m.business_id = p_business_id
          and m.profile_id = auth.uid()
          and m.is_active
          and m.role = any (p_roles)
    );
$$;

-- ¿El perfil comparte algún negocio con el usuario actual?
create or replace function public.shares_business_with(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1
        from public.business_members them
        join public.business_members me
          on me.business_id = them.business_id
        where them.profile_id = p_profile_id
          and me.profile_id = auth.uid()
          and me.is_active
    );
$$;

revoke all on function public.is_business_member(uuid) from public;
revoke all on function public.is_business_owner(uuid) from public;
revoke all on function public.has_business_role(uuid, text[]) from public;
revoke all on function public.shares_business_with(uuid) from public;
grant execute on function public.is_business_member(uuid) to authenticated, service_role;
grant execute on function public.is_business_owner(uuid) to authenticated, service_role;
grant execute on function public.has_business_role(uuid, text[]) to authenticated, service_role;
grant execute on function public.shares_business_with(uuid) to authenticated, service_role;

-- Trigger: crea el perfil al registrarse un usuario en Supabase Auth.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    insert into public.profiles (id, full_name, phone, locale)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', null),
        coalesce(new.raw_user_meta_data ->> 'phone', null),
        coalesce(new.raw_user_meta_data ->> 'locale', 'es')
    )
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Trigger: el dueño queda como miembro 'owner' al crear el negocio.
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
    return new;
end;
$$;

drop trigger if exists on_business_created on public.businesses;
create trigger on_business_created
    after insert on public.businesses
    for each row execute function public.handle_new_business();

-- Validación: cliente, servicio, sede y empleado deben ser del mismo negocio.
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
            select 1 from public.business_members m
            where m.business_id = new.business_id and m.profile_id = new.staff_id
        ) into v_ok;
        if not v_ok then
            raise exception 'El empleado no pertenece al negocio de la cita'
                using errcode = '23514';
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists validate_appointment_consistency on public.appointments;
create trigger validate_appointment_consistency
    before insert or update on public.appointments
    for each row execute function public.validate_appointment_consistency();

-- Triggers de updated_at.
do $$
declare
    t text;
begin
    foreach t in array array[
        'profiles', 'businesses', 'business_members', 'locations',
        'services', 'clients', 'appointments', 'subscriptions', 'usage_counters'
    ]
    loop
        execute format('drop trigger if exists set_updated_at on public.%I', t);
        execute format(
            'create trigger set_updated_at before update on public.%I
             for each row execute function public.set_updated_at()', t
        );
    end loop;
end;
$$;
