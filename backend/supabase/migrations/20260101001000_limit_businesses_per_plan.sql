-- Fase 4 - 0010: el plan Gratis permite un solo negocio.
--
-- La app deja crear negocios adicionales solo a quien ya tiene Pro. La regla se
-- aplica en la base para que no dependa de la interfaz: si el usuario no tiene
-- una suscripción Pro activa en ninguno de sus negocios, el segundo negocio se
-- rechaza.

create or replace function public.enforce_owned_business_limit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_owned integer;
    v_has_pro boolean;
begin
    select count(*) into v_owned
    from public.businesses
    where owner_id = new.owner_id;

    -- El primer negocio siempre se permite: así nadie queda sin poder empezar.
    if v_owned = 0 then
        return new;
    end if;

    select exists (
        select 1
        from public.businesses b
        join public.subscriptions s on s.business_id = b.id
        where b.owner_id = new.owner_id
          and s.plan = 'pro'
          and s.status in ('active', 'grace')
          and (s.current_period_end is null or s.current_period_end > now())
    ) into v_has_pro;

    if not v_has_pro then
        raise exception
            'plan_limit_reached: el plan Gratis permite un solo negocio'
            using errcode = '23514';
    end if;

    return new;
end;
$$;

comment on function public.enforce_owned_business_limit() is
    'Permite varios negocios solo si el dueño ya tiene una suscripción Pro activa.';

drop trigger if exists enforce_owned_business_limit on public.businesses;
create trigger enforce_owned_business_limit
    before insert on public.businesses
    for each row execute function public.enforce_owned_business_limit();
