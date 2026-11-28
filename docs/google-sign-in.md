# Inicio de sesión con Google

La app permite crear la cuenta con la cuenta de Google del teléfono. La cuenta
que nace ahí **no tiene negocio**: al entrar, `AppGate` ve que el usuario no
pertenece a ningún negocio y abre el onboarding, que es donde se piden nombre
del negocio, rubro, país, moneda, zona horaria, teléfono y dirección. Es el mismo
camino que con el registro por correo.

## Cómo está montado

| Pieza | Archivo |
| ----- | ------- |
| Botón "Continuar con Google" | [google_sign_in_button.dart](../mobile/lib/features/auth/presentation/widgets/google_sign_in_button.dart) |
| Flujo nativo + Supabase | [auth_repository.dart](../mobile/lib/features/auth/data/auth_repository.dart) — `signInWithGoogle` |
| Mensajes de error | [auth_error_messages.dart](../mobile/lib/features/auth/presentation/auth_error_messages.dart) |
| Pantallas | [login_screen.dart](../mobile/lib/features/auth/presentation/login_screen.dart), [register_screen.dart](../mobile/lib/features/auth/presentation/register_screen.dart) |
| Client ID Web | `GOOGLE_WEB_CLIENT_ID` en `.env.prod` (y `.env` para desarrollo) |

No hay cambios en el backend ni en la base: Supabase emite el mismo JWT y el
trigger `handle_new_user` sigue creando el perfil.

El botón **solo aparece si `GOOGLE_WEB_CLIENT_ID` tiene valor**. Sin esa clave,
la app se comporta como antes: correo y contraseña.

## 1. Google Cloud

1. <https://console.cloud.google.com> → crear (o elegir) el proyecto.
2. **APIs y servicios → Pantalla de consentimiento de OAuth**:
   - Tipo de usuario: **Externo**.
   - Nombre de la app: `Citurno`, correo de soporte, logo y dominio
     (`agendapro-api-469f.onrender.com`).
   - Permisos: `email` y `profile` (no requieren verificación de Google).
   - **Publicar la app**. Si queda en *Testing*, solo entran los 100 testers
     que agregues a mano.
3. **Credenciales → Crear credenciales → ID de cliente de OAuth**:

| Cliente | Tipo | Datos |
| ------- | ---- | ----- |
| Android (debug) | Android | paquete **`com.jlaburto.citurno.dev`** · SHA-1 `9B:40:F8:46:F6:6B:32:DD:D7:51:18:35:F9:62:00:DA:4E:A3:BB:C2` |
| Android (release) | Android | paquete `com.jlaburto.citurno` · SHA-1 `FA:EE:55:D7:BE:28:32:64:EB:E0:02:D7:35:10:2E:5B:20:64:1D:EB` |
| Android (Play) | Android | paquete `com.jlaburto.citurno` · SHA-1 de **Play App Signing** |
| **Web** | Web | el **Client ID** de este cliente es el que va en `GOOGLE_WEB_CLIENT_ID` |

> El flavor `dev` añade el sufijo `.dev` al `applicationId`, así que el cliente
> de **debug** debe declarar `com.jlaburto.citurno.dev`. Un APK/AAB de release
> usa `com.jlaburto.citurno`.

> El SHA-1 de Play App Signing está en Play Console → **Probar y publicar →
> Integridad de la app → Certificado de firma de la app**. Sin ese cliente, el
> login funciona en tu teléfono y falla en los testers de Play con
> `ApiException: 10 (DEVELOPER_ERROR)`.

## 2. Supabase

Dashboard del proyecto → **Authentication → Providers → Google**:

- Habilitar.
- **Client ID** y **Client Secret**: los del cliente **Web** (no el de Android).
- No hace falta configurar *Redirect URL*: el flujo usa `signInWithIdToken`, no
  navegador.

Si vas a permitir que un correo ya registrado con contraseña también entre con
Google, la opción está en **Authentication → Providers → Email** (enlazado
automático de identidades). **No la actives**: la app muestra “Ya tienes una
cuenta con ese correo. Entra con tu contraseña”, que es explícito y evita que
alguien reclame una cuenta ajena.

## 3. Compilar

```powershell
cd mobile
# .env.prod
GOOGLE_WEB_CLIENT_ID=309065900074-ph7eq3qsjkuk27ojjm9o233llio0bslp.apps.googleusercontent.com
```

Luego el build de siempre (el archivo se pasa completo):

```powershell
flutter build appbundle --flavor prod -t lib/main_prod.dart `
  --dart-define-from-file=.env.prod
```

## 4. Verificar en el teléfono

1. Instalar el APK **firmado con la llave registrada** (debug o prod, según el
   cliente que hayas creado).
2. Login → "Continuar con Google" → elegir cuenta.
3. Debe abrir el onboarding del negocio, no la agenda.
4. Crear el negocio y comprobar que la cuenta queda con el correo de Google.

## 5. Errores comunes

| Síntoma | Causa |
| ------- | ----- |
| `ApiException: 10` (`DEVELOPER_ERROR`) | SHA-1 o paquete no coincide con el cliente OAuth del APK instalado |
| El botón no aparece | `GOOGLE_WEB_CLIENT_ID` vacío o build sin `--dart-define-from-file` |
| `Google Sign-In: clientConfigurationError` en el log | Falta el cliente Android correcto o la pantalla de consentimiento no está publicada |
| Supabase responde 400 al validar el token | En Supabase se puso el Client ID de Android en vez del **Web** |
| “Solo los testers pueden acceder” | Pantalla de consentimiento en *Testing* y la cuenta no está en la lista |
| Tras cerrar sesión vuelve a entrar solo | Es esperado: se cierra la sesión de Google en `signOut()`; si persiste, reinstala el APK |
