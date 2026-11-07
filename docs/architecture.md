# Arquitectura

## Visión general

```
Flutter (Riverpod + go_router)  →  Supabase (Postgres + Auth + RLS)
                                        ↑
                     FastAPI (Render)  ──┘  service_role para billing y tareas
```

- La app móvil habla **directo con Supabase** para auth y CRUD (protegido por RLS).
- El backend FastAPI valida el JWT de Supabase, aplica reglas de negocio que no
  pueden vivir en el cliente (límites de plan, verificación de compras) y corre
  tareas programadas.

## Backend (`/backend`)

```
app/
  main.py                 # create_app(): CORS, middlewares, routers
  core/
    config.py             # Settings con pydantic-settings (.env / Render)
    logging.py            # logging a stdout con formato único
    security.py           # SupabaseTokenVerifier (HS256 o JWKS)
  api/
    deps.py               # get_current_user / get_optional_user
    router.py             # routers de /api/v1
    routes/health.py      # GET /health (público, usado por Render)
    routes/me.py          # GET /api/v1/me (requiere JWT)
  middleware/
    auth.py               # extrae el Bearer y deja request.state.user
    request_logging.py    # método, ruta, estado y duración
  schemas/                # modelos Pydantic de entrada y salida
  services/               # lógica de dominio (fases siguientes)
```

Decisiones:

- **Middleware + dependencia**: el middleware solo *extrae* el usuario; las rutas
  protegidas exigen `Depends(get_current_user)`. Así `/health` y `/docs` siguen
  públicos y el 401 es explícito.
- **Dos modos de verificación de JWT**: `SUPABASE_JWT_SECRET` (HS256) para
  desarrollo/pruebas y JWKS (`/auth/v1/.well-known/jwks.json`) para proyectos con
  llaves asimétricas (ES256/RS256), que es el modo recomendado hoy.
- **Errores**: se responde con `HTTPException` y `{"detail": "..."}`.

## App Flutter (`/mobile`)

```
lib/
  main.dart / main_dev.dart / main_prod.dart   # puntos de entrada por flavor
  bootstrap.dart                              # config, Supabase, preferencias
  app/
    app.dart            # MaterialApp.router (tema claro/oscuro, i18n)
    app_gate.dart       # onboarding vs app completa
    home_shell.dart     # navegación por pestañas
    router/             # go_router + refresh del redirect
  core/
    config/             # AppConfig (--dart-define)
    preferences/        # tema e idioma persistidos
    providers/          # providers base (Supabase, repositorios)
    theme/              # Material 3 claro/oscuro
    widgets/            # ErrorView, PlaceholderView
  features/
    auth/               # login, registro, recuperar contraseña
    business/           # dominio, repositorio y onboarding
    appointments/       # agenda (Fase 2)
    clients/            # clientes (Fase 2)
    billing/            # plan y compras (Fase 3)
    settings/           # apariencia, idioma, cuenta
  l10n/                 # ARB es/en y código generado
```

- **Estado**: Riverpod. `sessionProvider` escucha `onAuthStateChange` y alimenta
  las dependencias (usuario → negocios → pantallas).
- **Navegación**: go_router con `redirect` síncrono basado en la sesión. El
  *onboarding* se decide dentro de `AppGate` con `myBusinessesProvider`.
- **Flavors**: `dev` y `prod` en Android (`applicationIdSuffix .dev`) y en Dart
  (`APP_FLAVOR`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`).
- **i18n**: `flutter gen-l10n` con `app_es.arb` como plantilla y `app_en.arb`.

## Flujo de autenticación

1. `bootstrap()` valida la configuración e inicializa `Supabase.initialize`.
2. Registro: `auth.signUp` con `data.full_name`; el trigger `handle_new_user`
   crea el perfil.
3. Onboarding: se inserta el negocio (`owner_id = auth.uid()`); el trigger
   `handle_new_business` agrega al dueño como miembro `owner`.
4. `AppGate` detecta que ya hay negocio y muestra `HomeShell`.
5. El backend valida el mismo JWT en `/api/v1/me` y en las rutas futuras.
