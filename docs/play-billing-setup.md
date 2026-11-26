# Guía: Google Play Billing paso a paso

Esta guía cubre todo lo que se hace **fuera del código**: crear los productos de
suscripción, la cuenta de servicio, las notificaciones RTDN y probar con cuentas
de prueba.

> Orden importante: los productos de suscripción **no se pueden crear** hasta que
> la app tenga al menos un *bundle* subido (aunque sea a pruebas internas).

## 0. Antes de empezar

| Requisito | Detalle |
| --------- | ------- |
| Cuenta de desarrollador | Play Console con la cuota de 25 US$ pagada. |
| App creada | Nombre y package name `com.agendapro.agenda_pro`. |
| Build subido | Un AAB en **Pruebas internas** (Fase 8 genera el AAB; sirve cualquiera con la misma firma). |
| Proyecto de Google Cloud | Se crea en el paso 2. |
| Acceso al backend | El endpoint público de Render (`https://<servicio>.onrender.com`). |

## 1. Crear los productos de suscripción

1. Play Console → tu app → **Monetizar con Play → Productos → Suscripciones**.
2. Crea la suscripción **Pro**:
   - **ID del producto**: `agendapro_pro_mensual` (debe coincidir con
     `plans.play_product_id` en la base de datos).
   - **Nombre**: `Pro`.
3. Dentro de la suscripción, crea el **plan base**:
   - **ID del plan base**: `mensual`.
   - **Tipo**: Renovación automática.
   - **Periodo de facturación**: Mensual.
   - **Precio base**: **USD 5.00** (suscripción mensual).
     Play genera automáticamente el precio en cada país a partir del precio
     base; puedes ajustarlo por país si conviene (por ejemplo, Nicaragua).
     La app **nunca escribe el precio**: lo lee de la tienda y muestra la
     moneda y los impuestos locales del usuario.
   - **Periodo de gracia**: 7 días (opcional, recomendado).
   - **Periodo de espera de cuenta** (*account hold*): 7 días.
4. Activa el producto (**Activar**).

> El catálogo tiene solo dos planes: **Gratis** (no comprable, con anuncios) y
> **Pro** (USD 5/mes, sin anuncios).
> Si cambias el ID, actualiza la fila de `public.plans`
> (`play_product_id`). El backend resuelve el plan a partir del producto.

> **Cambiar el precio después**: se hace en Play Console, no en el código. Los
> usuarios existentes conservan su precio hasta que cambien de plan; Play avisa
> a quien corresponda. No hay que publicar una versión nueva de la app.

## 1.1. Anuncios del plan Gratis (AdMob)

El plan Gratis muestra un banner; el plan Pro no. La decisión la toma el
backend con `plans.features.ads`, así que se puede apagar sin publicar una
versión nueva.

La app ya apunta a la cuenta de AdMob de AgendaPro y el banner es adaptativo
(ajusta el ancho al de la pantalla, con altura calculada por Google):

| Dónde | Variable | Valor |
| ----- | -------- | ----- |
| `AndroidManifest.xml` | `com.google.android.gms.ads.APPLICATION_ID` | `ca-app-pub-7577794697772765~5358276955` |
| `.env.prod` | `ADMOB_BANNER_UNIT_ID` | `ca-app-pub-7577794697772765/4748349971` |

El App ID va versionado en el manifiesto (es público); el bloque de anuncios
llega por `--dart-define-from-file=.env.prod`. Si esa clave falta, la app cae
al bloque de **prueba** de Google (`ca-app-pub-3940256099942544/6300978111`),
que no genera ingresos.

Si algún día cambian los IDs:

1. Reemplazar el `android:value` del manifiesto por el nuevo App ID.
2. Actualizar `ADMOB_BANNER_UNIT_ID` en `.env.prod` y en `.env.example`.

> Si el App ID del manifiesto no es válido, **la app se cierra al arrancar**.
> Es el error más común al integrar AdMob.

### Consentimiento (EEE y Reino Unido)

La app pide el banner sin formulario de consentimiento. Si se distribuye en el
EEE o Reino Unido, Play exige un CMP certificado: hay que crear el mensaje en
AdMob → *Privacidad y mensajes* y añadir el flujo de
`ConsentInformation`/`ConsentForm` antes de `MobileAds.initialize`.

### Declaración obligatoria en Play Console

Con anuncios, la ficha cambia:

- **Seguridad de los datos**: declarar que la app muestra anuncios, que se
  recopila el *identificador de publicidad* y los datos técnicos del
  dispositivo por parte de Google AdMob.
- **Clasificación de contenido**: marcar que la app contiene anuncios.
- **Política de privacidad**: ya publica una sección de publicidad
  (<https://agendapro-api-469f.onrender.com/privacidad>).

## 2. Crear la cuenta de servicio

1. Entra a <https://console.cloud.google.com> y crea (o elige) un proyecto.
2. **APIs y servicios → Biblioteca** → busca **Google Play Android Developer API**
   → **Habilitar**.
3. **APIs y servicios → Credenciales → Crear credenciales → Cuenta de servicio**:
   - Nombre: `agendapro-billing`.
   - No hace falta asignar roles de IAM dentro de GCP.
4. Crea una **clave JSON** para esa cuenta de servicio y descárgala.
5. En **Play Console → Usuarios y permisos → Invitar usuarios nuevos**:
   - Correo: el `client_email` de la cuenta de servicio
     (`agendapro-billing@<proyecto>.iam.gserviceaccount.com`).
   - Permisos de app: **Ver datos financieros, gestionar pedidos y suscripciones**.
   - Guarda.
6. Copia el contenido **completo del JSON en una sola línea** en la variable de
   Render `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` y en `backend/.env` (nunca al repo).
7. Cambia `BILLING_PROVIDER=play` en el backend.

> La cuenta de servicio tarda unos minutos en propagarse. Mientras tanto la
> verificación responde 401/403: reintenta.

## 3. Notificaciones en tiempo real (RTDN) con Pub/Sub

> **Importante:** las suscripciones push de Pub/Sub **no permiten cabeceras HTTP
> personalizadas**. Por eso el secreto compartido viaja en la *query string* del
> endpoint (`?token=...`). El backend también acepta la cabecera
> `X-Agendapro-Token` para pruebas manuales.

1. Genera un secreto largo y guárdalo:

   ```powershell
   -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 40 | % {[char]$_})
   ```

   Ese valor va en `GOOGLE_PUBSUB_RTDN_TOKEN` (Render y `backend/.env`).

2. En Google Cloud → **Pub/Sub → Temas → Crear tema**:
   - Nombre: `play-subscriptions`
   - Déjalo con suscripciones predeterminadas o crea la push aparte.

3. En el tema → **Permisos → Agregar principal**:
   - Principal: `google-play-developer-notifications@system.gserviceaccount.com`
   - Rol: **Publicador de Pub/Sub** (`roles/pubsub.publisher`)

4. **Crear suscripción** de tipo **Push**:
   - **Endpoint**:
     ```
     https://<tu-servicio>.onrender.com/api/v1/billing/rtdn?token=<GOOGLE_PUBSUB_RTDN_TOKEN>
     ```
   - Sin autenticación OIDC (el secreto de la URL es la autenticación).
   - **Política de reintento**: reintento exponencial, 10 s a 600 s.

5. En Play Console → **Monetizar con Play → Configuración de monetización** →
   **Notificaciones de suscripciones** → pega el nombre completo del tema:
   ```
   projects/<proyecto>/topics/play-subscriptions
   ```

6. Verifica que lleguen: compra con una cuenta de licencia y revisa la tabla
   `billing_events` en Supabase (debe aparecer `rtdn_SUBSCRIPTION_PURCHASED` o
   `rtdn_SUBSCRIPTION_RENEWED`). También puedes publicar un mensaje de prueba
   desde la consola de Pub/Sub.

### Probar el endpoint a mano

```powershell
$token = "<GOOGLE_PUBSUB_RTDN_TOKEN>"
$payload = '{"message":{"data":"eyJzdWJzY3JpcHRpb25Ob3RpZmljYXRpb24iOnsibm90aWZpY2F0aW9uVHlwZSI6MiwicHVyY2hhc2VUb2tlbiI6Im5vLWV4aXN0ZSJ9fQ=="}}'
curl.exe -s -X POST -H "Content-Type: application/json" `
  --data-binary $payload "https://<tu-servicio>.onrender.com/api/v1/billing/rtdn?token=$token"
```

Respuesta esperada: `{"result":"unknown_token"}` (HTTP 200). Si devuelve **401**,
el token no coincide.

### Qué procesa el backend

| notificationType | Evento | Efecto |
| ---------------- | ------ | ------ |
| 1, 2, 4, 7 | recuperada / renovada / comprada / reiniciada | plan activo |
| 3 | cancelada | conserva el plan hasta el fin del periodo |
| 5, 6 | cuenta en espera / periodo de gracia | estado `grace` (mantiene acceso) |
| 10 | pausada | `paused` hasta el fin del periodo |
| 12, 13 | revocada / vencida | degrada a Gratis de inmediato |
| 20 | compra pendiente cancelada | `canceled` |

En cada notificación el backend **reconsulta la API de Play** para confirmar el
estado real; el tipo de notificación solo se usa como respaldo si Play no responde.

## 4. Firmar el AAB

Play rechaza los paquetes firmados con la llave de debug, y cambiar de firma
después obliga a subir una app nueva. La firma se configura una sola vez.

### Crear el keystore de subida

```powershell
cd mobile\android
keytool -genkey -v -keystore agendapro-upload.jks -keyalg RSA ^
  -keysize 2048 -validity 10000 -alias agendapro
```

Guarda la contraseña en el gestor de secretos: **si se pierde, no se puede
volver a firmar la app**.

### `android/key.properties`

```properties
storeFile=agendapro-upload.jks
storePassword=...
keyAlias=agendapro
keyPassword=...
```

El archivo `key.properties` y el `.jks` **no se versionan** (están en
`.gitignore`). Si falta `key.properties`, la compilación de release **falla a
propósito** con un mensaje claro: antes se firmaba en silencio con la llave de
debug y Play lo rechazaba. `flutter run` en debug sigue funcionando sin keystore.

### Compilar

```powershell
cd mobile
flutter build appbundle --flavor prod -t lib/main_prod.dart ^
  --dart-define-from-file=.env.prod
```

Salida: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.

> Sube `versionCode` en `pubspec.yaml` (p. ej. `version: 0.2.0+2`) antes de
> **cada** envío a Play.

Verificar la firma del paquete:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" ^
  -printcert -jarfile build\app\outputs\bundle\prodRelease\app-prod-release.aab
```

## 5. Probar con cuentas de prueba

1. Play Console → **Configuración → Pruebas de licencia**: agrega los correos de
   Gmail que probarán. Estas cuentas pagan 0 y no se les cobra.
2. Sube el AAB a **Pruebas internas** e invita a los testers (hasta 100).
3. Instala desde el enlace de pruebas internas (no por APK suelto: Play Billing
   exige la app instalada por Play).
4. Compra con una cuenta de prueba:
   - El diálogo de Play muestra el precio real.
   - Tras la compra, la app llama a `POST /billing/verify`.
   - El backend guarda la suscripción, **acknowledge** la compra y devuelve el
     plan.
   - La app recién entonces llama a `completePurchase`.
5. Verifica en **Pedidos y suscripciones** de Play Console y en la tabla
   `subscriptions` / `billing_events`.
6. Para probar cancelación: Play Console → pedido → **Cancelar suscripción**;
   llegarán las RTDN y el estado cambiará en pocos minutos.
7. **Restaurar compras**: reinstala la app e inicia sesión con el mismo negocio y
   pulsa *Restaurar compras*.

## 6. Modo simulado (desarrollo local)

Con `BILLING_PROVIDER=fake` el backend usa un cliente que simula Play:

- Cualquier `purchase_token` genera una suscripción activa de 30 días.
- El `acknowledge` también se simula.
- Sirve para probar límites y pantallas sin Play Console.

No uses `fake` en producción: cualquiera podría activar un plan.

## 7. Problemas comunes

| Síntoma | Causa probable |
| ------- | -------------- |
| `La compra no existe en Google Play` (404) | El `purchase_token` es de otro package, o producto/plan base mal configurado. |
| `La suscripción no está vigente` (409) | La compra quedó `PENDING` (pago diferido) o expiró. |
| Error 401/403 al verificar | La cuenta de servicio no tiene permisos en Play Console o aún no propagó. |
| La compra se reembolsa sola a los 3 días | La app no llamó a `completePurchase` (o el backend no pudo verificar). |
| «Ya se cobró tu compra, pero no pudimos verificarla» | El backend no respondió (Render dormido o sin red). La app guarda la compra y ofrece **Reintentar verificación**; también se reintenta sola al reabrir la app. |
| Las RTDN no llegan | El tema no está configurado en *Configuración de monetización*, o falta el rol *Publicador* al servicio de Google. |
| RTDN responde 401 | `GOOGLE_PUBSUB_RTDN_TOKEN` no coincide con el `?token=` de la URL de la suscripción push. |
| RTDN devuelve 404 | El endpoint está mal escrito o el servicio está dormido (plan free de Render). |
| Precio vacío en la app | El producto no está activo o la app no está instalada desde Play. |

## 8. Checklist final

- [ ] `android/key.properties` y el `.jks` existen y están fuera del repositorio.
- [ ] El AAB de release compila y `keytool -printcert` muestra tu llave, no la de debug.
- [ ] `versionCode` incrementado respecto al envío anterior.
- [ ] Producto `agendapro_pro_mensual` activo con precio base **USD 5.00**.
- [ ] App ID y Ad unit ID reales de AdMob (no los de prueba) en manifiesto y compilación.
- [ ] Seguridad de los datos y clasificación de contenido declaran los anuncios.
- [ ] `plans.play_product_id` coincide con los IDs de Play.
- [ ] Cuenta de servicio con permiso de suscripciones en Play Console.
- [ ] `BILLING_PROVIDER=play` y `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` en Render.
- [ ] Tema RTDN configurado y suscripción push apuntando a `/api/v1/billing/rtdn?token=...`.
- [ ] `GOOGLE_PUBSUB_RTDN_TOKEN` coincide con el `?token=` de la URL.
- [ ] Cron diario activo (`python -m app.jobs.daily_maintenance`).
- [ ] Una compra de prueba activa el plan, una cancelación lo desactiva y el
      límite del plan se aplica en el backend.
