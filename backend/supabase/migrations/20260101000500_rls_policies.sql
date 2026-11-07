-- Fase 1 - 0005: Row Level Security en todas las tablas.
-- Regla general: un usuario solo ve datos de los negocios donde es miembro.
-- Los roles se resuelven con las funciones de la migración 0004.

alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.locations enable row level security;
alter table public.services enable row level security;
alter table public.clients enable row level security;
alter table public.appointments enable row level security;
alter table public.subscriptions enable row level security;
alter table public.usage_counters enable row level security;

-- ---------------------------------------------------------------------------
-- profiles: cada usuario ve y edita su perfil; ve a sus compañeros de negocio.
-- ---------------------------------------------------------------------------
drop policy if exists profiles_select_self_or_coworkers on public.profiles;
create policy profiles_select_self_or_coworkers
    on public.profiles for select
    to authenticated
    using (id = auth.uid() or public.shares_business_with(id));

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self
    on public.profiles for insert
    to authenticated
    with check (id = auth.uid());

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self
    on public.profiles for update
    to authenticated
    using (id = auth.uid())
    with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- businesses: lectura para miembros, escritura solo para el dueño.
-- ---------------------------------------------------------------------------
drop policy if exists businesses_select_member on public.businesses;
create policy businesses_select_member
    on public.businesses for select
    to authenticated
    using (public.is_business_member(id));

drop policy if exists businesses_insert_owner on public.businesses;
create policy businesses_insert_owner
    on public.businesses for insert
    to authenticated
    with check (owner_id = auth.uid());

drop policy if exists businesses_update_owner on public.businesses;
create policy businesses_update_owner
    on public.businesses for update
    to authenticated
    using (owner_id = auth.uid())
    with check (owner_id = auth.uid());

drop policy if exists businesses_delete_owner on public.businesses;
create policy businesses_delete_owner
    on public.businesses for delete
    to authenticated
    using (owner_id = auth.uid());

-- ---------------------------------------------------------------------------
-- business_members: lectura para miembros, gestión solo para el dueño.
-- ---------------------------------------------------------------------------
drop policy if exists business_members_select_member on public.business_members;
create policy business_members_select_member
    on public.business_members for select
    to authenticated
    using (profile_id = auth.uid() or public.is_business_member(business_id));

drop policy if exists business_members_insert_owner on public.business_members;
create policy business_members_insert_owner
    on public.business_members for insert
    to authenticated
    with check (public.is_business_owner(business_id));

drop policy if exists business_members_update_owner on public.business_members;
create policy business_members_update_owner
    on public.business_members for update
    to authenticated
    using (public.is_business_owner(business_id))
    with check (public.is_business_owner(business_id));

drop policy if exists business_members_delete_owner on public.business_members;
create policy business_members_delete_owner
    on public.business_members for delete
    to authenticated
    using (public.is_business_owner(business_id) and role <> 'owner');

-- ---------------------------------------------------------------------------
-- locations: lectura para miembros, escritura solo para el dueño.
-- ---------------------------------------------------------------------------
drop policy if exists locations_select_member on public.locations;
create policy locations_select_member
    on public.locations for select
    to authenticated
    using (public.is_business_member(business_id));

drop policy if exists locations_write_owner on public.locations;
create policy locations_write_owner
    on public.locations for insert
    to authenticated
    with check (public.is_business_owner(business_id));

drop policy if exists locations_update_owner on public.locations;
create policy locations_update_owner
    on public.locations for update
    to authenticated
    using (public.is_business_owner(business_id))
    with check (public.is_business_owner(business_id));

drop policy if exists locations_delete_owner on public.locations;
create policy locations_delete_owner
    on public.locations for delete
    to authenticated
    using (public.is_business_owner(business_id));

-- ---------------------------------------------------------------------------
-- services: dueño y empleados pueden gestionar los servicios.
-- ---------------------------------------------------------------------------
drop policy if exists services_select_member on public.services;
create policy services_select_member
    on public.services for select
    to authenticated
    using (public.is_business_member(business_id));

drop policy if exists services_insert_staff on public.services;
create policy services_insert_staff
    on public.services for insert
    to authenticated
    with check (public.has_business_role(business_id, array['owner', 'staff']));

drop policy if exists services_update_staff on public.services;
create policy services_update_staff
    on public.services for update
    to authenticated
    using (public.has_business_role(business_id, array['owner', 'staff']))
    with check (public.has_business_role(business_id, array['owner', 'staff']));

drop policy if exists services_delete_staff on public.services;
create policy services_delete_staff
    on public.services for delete
    to authenticated
    using (public.has_business_role(business_id, array['owner', 'staff']));

-- ---------------------------------------------------------------------------
-- clients: dueño y empleados.
-- ---------------------------------------------------------------------------
drop policy if exists clients_select_member on public.clients;
create policy clients_select_member
    on public.clients for select
    to authenticated
    using (public.is_business_member(business_id));

drop policy if exists clients_insert_staff on public.clients;
create policy clients_insert_staff
    on public.clients for insert
    to authenticated
    with check (public.has_business_role(business_id, array['owner', 'staff']));

drop policy if exists clients_update_staff on public.clients;
create policy clients_update_staff
    on public.clients for update
    to authenticated
    using (public.has_business_role(business_id, array['owner', 'staff']))
    with check (public.has_business_role(business_id, array['owner', 'staff']));

drop policy if exists clients_delete_staff on public.clients;
create policy clients_delete_staff
    on public.clients for delete
    to authenticated
    using (public.has_business_role(business_id, array['owner', 'staff']));

-- ---------------------------------------------------------------------------
-- appointments: dueño y empleados.
-- ---------------------------------------------------------------------------
drop policy if exists appointments_select_member on public.appointments;
create policy appointments_select_member
    on public.appointments for select
    to authenticated
    using (public.is_business_member(business_id));

drop policy if exists appointments_insert_staff on public.appointments;
create policy appointments_insert_staff
    on public.appointments for insert
    to authenticated
    with check (public.has_business_role(business_id, array['owner', 'staff']));

drop policy if exists appointments_update_staff on public.appointments;
create policy appointments_update_staff
    on public.appointments for update
    to authenticated
    using (public.has_business_role(business_id, array['owner', 'staff']))
    with check (public.has_business_role(business_id, array['owner', 'staff']));

drop policy if exists appointments_delete_staff on public.appointments;
create policy appointments_delete_staff
    on public.appointments for delete
    to authenticated
    using (public.has_business_role(business_id, array['owner', 'staff']));

-- ---------------------------------------------------------------------------
-- subscriptions y usage_counters: solo lectura en la app.
-- La escritura la hace el backend con la service role key (verificación de
-- compras y tareas programadas), por eso no hay políticas de escritura.
-- ---------------------------------------------------------------------------
drop policy if exists subscriptions_select_member on public.subscriptions;
create policy subscriptions_select_member
    on public.subscriptions for select
    to authenticated
    using (public.is_business_member(business_id));

drop policy if exists usage_counters_select_member on public.usage_counters;
create policy usage_counters_select_member
    on public.usage_counters for select
    to authenticated
    using (public.is_business_member(business_id));

-- ---------------------------------------------------------------------------
-- Permisos por tabla: cerramos el acceso anónimo y abrimos lo mínimo.
-- ---------------------------------------------------------------------------
revoke all on public.profiles,
    public.businesses,
    public.business_members,
    public.locations,
    public.services,
    public.clients,
    public.appointments,
    public.subscriptions,
    public.usage_counters
from anon;

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.businesses to authenticated;
grant select, insert, update, delete on public.business_members to authenticated;
grant select, insert, update, delete on public.locations to authenticated;
grant select, insert, update, delete on public.services to authenticated;
grant select, insert, update, delete on public.clients to authenticated;
grant select, insert, update, delete on public.appointments to authenticated;
grant select on public.subscriptions to authenticated;
grant select on public.usage_counters to authenticated;
