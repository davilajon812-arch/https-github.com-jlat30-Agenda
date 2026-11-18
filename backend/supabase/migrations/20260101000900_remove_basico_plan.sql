-- Fase 3 - 0009: el catálogo queda solo con Gratis y Pro.
--
-- El plan Básico nunca llegó a publicarse en Play Console, así que se retira
-- para no ofrecer tres opciones donde el producto solo tiene dos.

-- Cualquier suscripción en Básico se conserva como Pro para no degradar a un
-- cliente que ya hubiera pagado.
update public.subscriptions
set plan = 'pro', updated_at = now()
where plan = 'basico';

delete from public.plans where id = 'basico';

alter table public.plans
    drop constraint if exists plans_id_check;
alter table public.plans
    add constraint plans_id_check check (id in ('free', 'pro'));

alter table public.subscriptions
    drop constraint if exists subscriptions_plan_check;
alter table public.subscriptions
    add constraint subscriptions_plan_check check (plan in ('free', 'pro'));

-- Pro pasa a ser el segundo y último escalón.
update public.plans set sort_order = 2, updated_at = now() where id = 'pro';
