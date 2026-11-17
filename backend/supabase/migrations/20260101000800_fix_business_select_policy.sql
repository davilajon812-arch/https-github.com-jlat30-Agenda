-- Fase 3 - 0008: el dueño siempre puede leer su propio negocio.
--
-- Problema: la política SELECT de `businesses` dependía solo de
-- `is_business_member(id)`, que lee `business_members`. Esa fila la crea el
-- trigger AFTER INSERT `handle_new_business`, por lo que no es visible en el
-- mismo statement. Resultado: `INSERT ... RETURNING` (que usa la app vía
-- `.select()`) fallaba con "new row violates row-level security policy".
--
-- La corrección es semánticamente correcta: el dueño debe poder leer su
-- negocio aunque la membresía todavía no exista.

drop policy if exists businesses_select_member on public.businesses;
create policy businesses_select_member
    on public.businesses for select
    to authenticated
    using (owner_id = auth.uid() or public.is_business_member(id));

-- Mismo razonamiento para la propia membresía: quien aparece como miembro de
-- una fila puede leerla (necesario para `business_members` insert + RETURNING).
drop policy if exists business_members_select_member on public.business_members;
create policy business_members_select_member
    on public.business_members for select
    to authenticated
    using (
        profile_id = auth.uid()
        or public.is_business_owner(business_id)
        or public.is_business_member(business_id)
    );
