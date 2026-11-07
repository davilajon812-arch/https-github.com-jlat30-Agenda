# Configurar Supabase (Fase 1)

## 1. Crear el proyecto

1. Entra a <https://supabase.com/dashboard> y crea un proyecto (guarda la
   contraseña de la base de datos).
2. Elige la región más cercana a tus usuarios (por ejemplo `us-east-1`).
3. Espera a que termine el aprovisionamiento.

## 2. Copiar credenciales

En **Project Settings → API**:

| Dato | Variable |
| ---- | -------- |
| Project URL | `SUPABASE_URL` |
| `anon` / publishable key | `SUPABASE_ANON_KEY` (app móvil y backend) |
| `service_role` key | `SUPABASE_SERVICE_ROLE_KEY` (solo backend, nunca en la app) |
| JWT secret (si usas llaves simétricas) | `SUPABASE_JWT_SECRET` |

> La `service_role` key salta RLS. Guárdala solo en las variables de Render y en
> `backend/.env`. Nunca en el repositorio ni en la app.

## 3. Aplicar las migraciones

Archivos en `backend/supabase/migrations`, en este orden:

| Archivo | Contenido |
| ------- | --------- |
| `20260101000100_extensions.sql` | `pgcrypto` (tolerante a entornos sin contrib) |
| `20260101000200_core_tables.sql` | 9 tablas del negocio |
| `20260101000300_indexes.sql` | índices de agenda, clientes y facturación |
| `20260101000400_functions_and_triggers.sql` | funciones de RLS y triggers |
| `20260101000500_rls_policies.sql` | políticas y permisos por tabla |

**Opción A — SQL Editor (rápido):**

1. Abre **SQL Editor** en Supabase.
2. Pega el contenido del archivo `0001`, ejecuta. Repite con `0002` … `0005`.

**Opción B — Supabase CLI (recomendado para el equipo):**

```powershell
npm install -g supabase
supabase login
supabase link --project-ref <tu-project-ref>
supabase db push        # aplica backend/supabase/migrations
```

## 4. Revisar Auth

En **Authentication → Providers → Email**:

- Deja habilitado *Email* con contraseña.
- Para desarrollo, desactiva **Confirm email** para poder entrar de inmediato
  (en producción actívalo).

En **Authentication → URL Configuration** define *Site URL* y las *Redirect URLs*
(de momento solo se usa el enlace de recuperación de contraseña).

## 5. Verificar el aislamiento (RLS)

Con un Postgres accesible (`Project Settings → Database → Connection string`)
puedes correr las pruebas contra tu proyecto real:

```powershell
cd backend
$env:SUPABASE_DB_URL="postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres"
.venv\Scripts\python.exe -m pytest tests/rls -v
```

Sin `SUPABASE_DB_URL` las mismas pruebas corren contra un Postgres embebido
(`pgserver`) con un esquema `auth` simulado, para validar el SQL en local/CI.

Las pruebas crean dos negocios con datos fijos, verifican que un usuario no ve ni
escribe datos del otro y limpian al terminar.

## 6. Datos mínimos para probar la app

1. Abre la app (flavor dev) → **Crear cuenta**.
2. Completa el onboarding (nombre, rubro, país, moneda, zona horaria).
3. Verifica en **Table Editor** que se crearon `profiles`, `businesses` y
   `business_members` (rol `owner`).

## Problemas comunes

| Síntoma | Causa |
| ------- | ----- |
| `permission denied for table ...` | Las migraciones de permisos (`0005`) no se aplicaron. |
| `new row violates row-level security` | El `owner_id` no coincide con el usuario del token, o falta la membresía. |
| `El cliente no pertenece al negocio de la cita` | El trigger de consistencia detectó datos cruzados entre negocios. |
| El backend responde 401 con un token válido | `SUPABASE_JWT_SECRET`/`SUPABASE_URL` mal configurados o `aud` distinto de `authenticated`. |
