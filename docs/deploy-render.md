# Despliegue del backend en Render

## Opción A — Blueprint con `render.yaml` (recomendada)

1. Sube el repositorio a GitHub.
2. En Render: **New → Blueprint** y elige el repositorio.
3. Render detecta `render.yaml` en la raíz y propone el servicio `agendapro-api`
   (`rootDir: backend`, plan free, health check `/health`).
4. Completa las variables marcadas con `sync: false`:

   | Variable | Valor |
   | -------- | ----- |
   | `CORS_ORIGINS` | `http://localhost:3000,https://tu-dominio` |
   | `SUPABASE_URL` | URL del proyecto |
   | `SUPABASE_ANON_KEY` | anon key |
   | `SUPABASE_SERVICE_ROLE_KEY` | service role key |
   | `SUPABASE_JWT_SECRET` | vacío si el proyecto usa JWKS |

5. **Apply** y espera el primer deploy.
6. Verifica: `https://agendapro-api.onrender.com/health` debe responder

   ```json
   {"status":"ok","service":"AgendaPro API","version":"0.1.0","environment":"prod"}
   ```

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

El repositorio incluye `backend/Dockerfile`:

```powershell
cd backend
docker build -t agendapro-api .
docker run -p 8000:8000 --env-file .env agendapro-api
```

En Render elige **Docker** como runtime y `backend` como *Root Directory*.

## Notas

- El plan gratuito de Render **duerme** el servicio tras inactividad: la primera
  petición tarda ~30 s. Para recordatorios y webhooks (fases 5 y 6) se necesita
  el plan de pago o un cron externo.
- `APP_ENV=prod` desactiva `/docs` y `/redoc`.
- Los secretos se definen solo en Render; nunca en el repositorio.
- Comandos útiles de verificación:

  ```powershell
  curl https://agendapro-api.onrender.com/health
  curl -H "Authorization: Bearer <access_token>" https://agendapro-api.onrender.com/api/v1/me
  ```
