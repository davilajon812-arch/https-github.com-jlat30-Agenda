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
2. Crea la suscripción **Básico**:
   - **ID del producto**: `agendapro_basico_mensual` (debe coincidir con
     `plans.play_product_id` en la base de datos).
   - **Nombre**: `Básico`.
3. Dentro de la suscripción, crea el **plan base**:
   - **ID del plan base**: `mensual`.
   - **Tipo**: Renovación automática.
   - **Periodo de facturación**: Mensual.
   - **Precio**: el que definas por país (Play muestra el precio local con
     impuestos; la app lo lee de la tienda y **no lo escribe a mano**).
   - **Periodo de gracia**: 7 días (opcional, recomendado).
   - **Periodo de espera de cuenta** (*account hold*): 7 días.
4. Repite con **Pro**: ID `agendapro_pro_mensual`.
5. Activa ambos productos (**Activar**).

> Si cambias un ID, actualiza la fila correspondiente en `public.plans`
> (`play_product_id`). El backend resuelve el plan a partir del producto.

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

1. En Google Cloud → **Pub/Sub → Temas → Crear tema**:
   `play-subscriptions` (nombre de ejemplo).
2. En el tema, **Permisos → Agregar principal**:
   - Principal: `google-play-developer-notifications@system.gserviceaccount.com`
   - Rol: **Publicador de Pub/Sub** (`roles/pubsub.publisher`).
3. **Crear suscripción** tipo **Push**:
   - Endpoint: `https://<tu-servicio>.onrender.com/api/v1/billing/rtdn`
   - Marca **Habilitar autenticación** solo si vas a validar la identidad del
     emisor con OAuth. En esta entrega se valida un **secreto compartido**: añade
     el atributo `X-Agendapro-Token` = valor de `GOOGLE_PUBSUB_RTDN_TOKEN`.
     (Si prefieres OAuth de Pub/Sub, deja `GOOGLE_PUBSUB_RTDN_TOKEN` vacío y
     valida el JWT del emisor en un paso posterior.)
4. En Play Console → **Monetizar con Play → Configuración de monetización** →
   **Notificaciones de suscripciones** → pega el nombre completo del tema:
   `projects/<proyecto>/topics/play-subscriptions`.
5. Envía una notificación de prueba desde Pub/Sub y revisa que aparezca en
   `billing_events`.

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

## 4. Probar con cuentas de prueba

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

## 5. Modo simulado (desarrollo local)

Con `BILLING_PROVIDER=fake` el backend usa un cliente que simula Play:

- Cualquier `purchase_token` genera una suscripción activa de 30 días.
- El `acknowledge` también se simula.
- Sirve para probar límites y pantallas sin Play Console.

No uses `fake` en producción: cualquiera podría activar un plan.

## 6. Problemas comunes

| Síntoma | Causa probable |
| ------- | -------------- |
| `La compra no existe en Google Play` (404) | El `purchase_token` es de otro package, o producto/plan base mal configurado. |
| `La suscripción no está vigente` (409) | La compra quedó `PENDING` (pago diferido) o expiró. |
| Error 401/403 al verificar | La cuenta de servicio no tiene permisos en Play Console o aún no propagó. |
| La compra se reembolsa sola a los 3 días | La app no llamó a `completePurchase` (o el backend no pudo verificar). |
| Las RTDN no llegan | El tema no está configurado en *Configuración de monetización*, o falta el rol *Publicador* al servicio de Google. |
| RTDN responde 401 | `GOOGLE_PUBSUB_RTDN_TOKEN` no coincide con la cabecera de la suscripción push. |
| Precio vacío en la app | El producto no está activo o la app no está instalada desde Play. |

## 7. Checklist final

- [ ] Productos `agendapro_basico_mensual` y `agendapro_pro_mensual` activos.
- [ ] `plans.play_product_id` coincide con los IDs de Play.
- [ ] Cuenta de servicio con permiso de suscripciones en Play Console.
- [ ] `BILLING_PROVIDER=play` y `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` en Render.
- [ ] Tema RTDN configurado y suscripción push apuntando a `/api/v1/billing/rtdn`.
- [ ] `GOOGLE_PUBSUB_RTDN_TOKEN` coincide con la cabecera configurada.
- [ ] Cron diario activo (`python -m app.jobs.daily_maintenance`).
- [ ] Una compra de prueba activa el plan, una cancelación lo desactiva y el
      límite del plan se aplica en el backend.
