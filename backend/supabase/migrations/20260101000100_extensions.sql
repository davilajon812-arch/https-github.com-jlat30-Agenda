-- Fase 1 - 0001: extensiones requeridas por el esquema.
-- gen_random_uuid() es parte del núcleo desde PostgreSQL 13, así que pgcrypto
-- solo aporta utilidades criptográficas adicionales. Supabase la incluye; en
-- entornos mínimos (CI con Postgres embebido) puede no estar disponible.
do $$
begin
    create extension if not exists pgcrypto;
exception
    when others then
        raise notice 'pgcrypto no disponible: se usa gen_random_uuid() del núcleo';
end;
$$;
