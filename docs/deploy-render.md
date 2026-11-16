# Despliegue del backend en Render

> **Estado actual: desplegado y funcionando.**
>
> - URL: **https://agendapro-api-469f.onrender.com**
> - Servicio: `agendapro-api` (`srv-dbt5j3ei0phs73eookog`), plan free, región oregon
> - Repo: `davilajon812-arch/https-github.com-jlat30-Agenda`, rama `main`, `rootDir=backend`
> - Auto-deploy activo: cada push a `main` reconstruye el servicio
>
> El sufijo `-469f` aparece porque el nombre `agendapro-api` ya estaba ocupado
> globalmente en Render.

Objetivo: dejar `https://<servicio>.onrender.com/health` respondiendo 200 y el
backend listo para verificar compras de Google Play.

## Antes de empezar

| Dato | Dónde se obtiene |
| ---- | ---------------- |
| `SUPABASE_URL` | Supabase → Project Settings → API |
| `SUPABASE_ANON_KEY` | Ídem (publishable key) |
| `SUPABASE_SERVICE_ROLE_KEY` | Ídem (secret key) |
| `DATABASE_URL` | Cadena del **pooler** (ver abajo) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | JSON de la cuenta de servicio |
| `GOOGLE_PUBSUB_RTDN_TOKEN` | Secreto que tú generas |
| `MAINTENANCE_TOKEN` | Secreto que tú generas |

> ⚠️ **Usa el pooler, no la conexión directa.** `db.<ref>.supabase.co` es
> **IPv6-only** y Render no tiene salida IPv6: la conexión falla con "Network is
> unreachable". El formato correcto es:
>
> ```
> postgresql://postgres.<ref>:<password>@aws-1-<region>.pooler.supabase.com:5432/postgres
> ```
>
> El puerto **5432 (modo sesión)** es el que necesita psycopg por las sentencias
> preparadas; el 6543 (transacción) puede fallar.

## Generar los dos secretos

```powershell
function New-Secret { -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 44 | % {[char]$_}) }
"GOOGLE_PUBSUB_RTDN_TOKEN = $(New-Secret)"
"MAINTENANCE_TOKEN        = $(New-Secret)"
```

## Opción A — Blueprint con `render.yaml` (recomendada)

1. Entra a <https://dashboard.render.com> → **New → Blueprint**.
2. Conecta el repositorio `jlat30/Agenda`, rama `main`.
3. Render detecta `render.yaml` y propone el servicio **`agendapro-api`**
   (runtime Python, plan free, `rootDir: backend`, health check `/health`).
4. Completa las variables secretas:

   | Variable | Valor |
   | -------- | ----- |
   | `CORS_ORIGINS` | `https://agendapro-api-469f.onrender.com,http://localhost:3000` |
   | `SUPABASE_URL` | `https://<ref>.supabase.co` |
   | `SUPABASE_ANON_KEY` | publishable key |
   | `SUPABASE_SERVICE_ROLE_KEY` | secret key |
   | `SUPABASE_JWT_SECRET` | **vacío** si el proyecto usa JWKS |
   | `DATABASE_URL` | pooler en puerto 5432 |
   | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | JSON completo en **una línea** |
   | `GOOGLE_PUBSUB_RTDN_TOKEN` | secreto generado arriba |
   | `MAINTENANCE_TOKEN` | secreto generado arriba |

5. **Apply**. El primer build tarda 3–5 min.
6. Verifica:

   ```powershell
   curl.exe -s https://agendapro-api-469f.onrender.com/health
   ```

   ```json
   {"status":"ok","service":"AgendaPro API","version":"0.1.0","environment":"prod"}
   ```

7. Comprueba que conecta a la base y cargó los planes:

   ```powershell
   curl.exe -s https://agendapro-api-469f.onrender.com/api/v1/billing/plans
   ```

> En los logs del deploy debe aparecer `Pool de Postgres abierto (min=1, max=8)`.
> Si ves `No se pudo abrir el pool`, el problema está en `DATABASE_URL`.

## Opción B — Servicio manual

1. **New → Web Service**, conecta el repo.
2. Configura:
   - **Root Directory**: `backend`
   - **Runtime**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path**: `/health`
3. Agrega las variables de entorno de la tabla anterior.

## Opción C — Docker

```powershell
cd backend
docker build -t agendapro-api .
docker run -p 8000:8000 --env-file .env agendapro-api
```

En Render elige **Docker** como runtime y `backend` como *Root Directory*.

## Mantenimiento diario

La tarea reconcilia suscripciones con Play, expira periodos vencidos y abre el
contador del mes.

### Plan gratuito (sin cron de Render)

Los cron jobs de Render requieren plan **Starter**; por eso el bloque viene
comentado en `render.yaml`. Usa un programador externo gratuito:

- **URL**: `https://agendapro-api-469f.onrender.com/api/v1/internal/maintenance/daily`
- **Método**: `POST`
- **Cabecera**: `X-Maintenance-Token: <MAINTENANCE_TOKEN>`
- **Horario**: diario 13:00 UTC (07:00 en Nicaragua)

Ejemplo con GitHub Actions (gratis):

```yaml
name: mantenimiento-diario
on:
  schedule: [{ cron: "0 13 * * *" }]
  workflow_dispatch:
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - run: |
          curl -sS -X POST \
            -H "X-Maintenance-Token: ${{ secrets.MAINTENANCE_TOKEN }}" \
            https://agendapro-api-469f.onrender.com/api/v1/internal/maintenance/daily
```

### Plan de pago

Descomenta el bloque `- type: cron` de `render.yaml` y vuelve a aplicar el
blueprint. Corre `python -m app.jobs.daily_maintenance` a diario.

> **Plan free:** el servicio se duerme tras ~15 min sin tráfico y la primera
> petición tarda ~30 s. Para RTDN y recordatorios conviene el plan de pago.

## Verificación final

```powershell
# 1. Estado
curl.exe -s -w " [%{http_code}]`n" https://agendapro-api-469f.onrender.com/health

# 2. Planes (público)
curl.exe -s https://agendapro-api-469f.onrender.com/api/v1/billing/plans

# 3. RTDN con el secreto correcto -> {"result":"unknown_token"}
curl.exe -s -X POST -H "Content-Type: application/json" `
  --data-binary '{"message":{"data":"eyJzdWJzY3JpcHRpb25Ob3RpZmljYXRpb24iOnsibm90aWZpY2F0aW9uVHlwZSI6MiwicHVyY2hhc2VUb2tlbiI6Im5vLWV4aXN0ZSJ9fQ=="}}' `
  "https://agendapro-api-469f.onrender.com/api/v1/billing/rtdn?token=<GOOGLE_PUBSUB_RTDN_TOKEN>"

# 4. RTDN con token incorrecto -> 401
curl.exe -s -o NUL -w "%{http_code}`n" -X POST `
  "https://agendapro-api-469f.onrender.com/api/v1/billing/rtdn?token=incorrecto"
```

### Resultados esperados

| Check | Respuesta |
| ----- | --------- |
| 1 | `{"status":"ok","service":"AgendaPro API","version":"0.1.0","environment":"prod"} [200]` |
| 2 | Array con los tres planes (`free`, `basico`, `pro`) |
| 3 | `{"result":"unknown_token"}` con código 200 |
| 4 | `{"detail":"Token de RTDN inválido"}` con código 401 |

> La primera petición tras un rato sin tráfico tarda ~30 s porque el plan free
> duerme el servicio. Usa `-m 120` en `curl` para no interpretar la espera como
> una caída.

### Si `curl` se queda sin recibir ni un byte

Ese síntoma **no** es un problema de la app: significa que el servicio existe en
Render (una URL inexistente responde `404 Not Found` en menos de un segundo)
pero la instancia no está atendiendo HTTP. Revisa en el panel de Render:

1. **Events / Deploys**: que el último despliegue diga `Live` y no
   `Build failed` ni `Deploy failed`.
2. **Logs**: busca `Uvicorn running on` y `Pool de Postgres abierto`. Si no
   aparecen, el proceso murió antes de abrir el puerto.
3. **Environment**: que estén todas las variables de `render.yaml`; las marcadas
   con `sync: false` se capturan a mano y el despliegue falla sin ellas.
4. **Plan free**: si el servicio fue suspendido por consumo de horas, hay que
   reanudarlo desde el panel.

## Problemas comunes

| Síntoma | Causa |
| ------- | ----- |
| Build falla con `No module named ...` | Falta la dependencia en `requirements.txt`. |
| `Network is unreachable` al abrir el pool | `DATABASE_URL` apunta a `db.<ref>.supabase.co` (IPv6). Usa el pooler. |
| Pool abierto pero 503 en endpoints | Las migraciones no están aplicadas en esa base. |
| Health check falla | El `startCommand` no usa `$PORT`. |
| `BILLING_PROVIDER=fake` en logs | Falta `play` o falta el JSON de la cuenta de servicio. |
| 401 al llamar las rutas de negocio | Token de Supabase ausente o `SUPABASE_URL`/`JWT_SECRET` mal configurados. |
