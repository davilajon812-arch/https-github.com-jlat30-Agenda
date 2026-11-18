"""Páginas legales públicas: privacidad, términos y eliminación de cuenta.

Google Play exige una URL pública de política de privacidad y otra de
eliminación de cuenta; ambas viven aquí para no depender de un servicio extra.
Se sirven sin autenticación y con HTML mínimo autocontenido.
"""

from __future__ import annotations

from string import Template

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse

router = APIRouter(tags=["legal"])

_PAGE = Template(
    """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title · $entity</title>
<style>
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 2rem 1.25rem 4rem;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    line-height: 1.65; color: #1f2937; background: #f8fafc;
  }
  main { max-width: 46rem; margin: 0 auto; }
  header { border-bottom: 3px solid #0F766E; padding-bottom: 1rem; margin-bottom: 2rem; }
  .brand { color: #0F766E; font-weight: 700; letter-spacing: .02em; font-size: .8rem;
           text-transform: uppercase; }
  h1 { font-size: 1.75rem; margin: .25rem 0 0; line-height: 1.25; }
  h2 { font-size: 1.1rem; margin: 2rem 0 .5rem; color: #0F766E; }
  p, li { font-size: .95rem; }
  ul { padding-left: 1.25rem; }
  a { color: #0F766E; }
  .meta { font-size: .8rem; color: #6b7280; margin-top: .5rem; }
  footer { margin-top: 3rem; padding-top: 1rem; border-top: 1px solid #e2e8f0;
           font-size: .8rem; color: #6b7280; }
  nav a { margin-right: 1rem; font-size: .85rem; }
  @media (prefers-color-scheme: dark) {
    body { background: #0f172a; color: #e2e8f0; }
    footer { border-color: #1e293b; color: #94a3b8; }
    .meta { color: #94a3b8; }
  }
</style>
</head>
<body>
<main>
<header>
  <div class="brand">$entity</div>
  <h1>$title</h1>
  <div class="meta">Última actualización: $updated</div>
</header>
$body
<footer>
  <nav>
    <a href="/privacidad">Privacidad</a>
    <a href="/terminos">Términos</a>
    <a href="/eliminar-cuenta">Eliminar cuenta</a>
  </nav>
  <p>$entity · Contacto: <a href="mailto:$email">$email</a></p>
</footer>
</main>
</body>
</html>
"""
)

_UPDATED = "18 de noviembre de 2026"

_PRIVACY = """
<h2>1. Responsable del tratamiento</h2>
<p>$entity es el responsable de los datos descritos en esta política. Puedes
escribirnos a <a href="mailto:$email">$email</a>.</p>

<h2>2. Qué datos tratamos</h2>
<p><strong>Datos de tu cuenta (usuario del negocio).</strong> Correo electrónico,
contraseña cifrada, nombre, teléfono opcional, país, zona horaria, moneda e
información del negocio (nombre, rubro).</p>
<p><strong>Datos de tus clientes.</strong> La aplicación es una agenda: tú, como
negocio, registras nombre, teléfono, notas e historial de citas de tus propios
clientes. En ese caso <strong>tú eres el responsable</strong> de esos datos y
$entity actúa únicamente como encargado que los almacena por tu cuenta.</p>
<p><strong>Datos de facturación.</strong> Cuando contratas el plan Pro, Google Play
procesa el pago. Nosotros recibimos el identificador de la compra y su estado,
nunca los datos de tu tarjeta.</p>

<h2>3. Para qué los usamos</h2>
<ul>
  <li>Prestar el servicio: autenticación, agenda, disponibilidad y recordatorios.</li>
  <li>Gestionar tu suscripción y los límites del plan.</li>
  <li>Atender solicitudes de soporte y cumplir obligaciones legales.</li>
</ul>
<p>La base legal es la ejecución del contrato que aceptas al crear la cuenta.</p>

<h2>4. Con quién los compartimos</h2>
<p>No vendemos datos personales ni los cedemos con fines publicitarios. Usamos
proveedores que actúan como encargados:</p>
<ul>
  <li><strong>Supabase</strong> — base de datos y autenticación.</li>
  <li><strong>Render</strong> — alojamiento del servidor de la aplicación.</li>
  <li><strong>Google Play</strong> — procesamiento de las suscripciones.</li>
</ul>
<p>La aplicación <strong>no incluye publicidad ni herramientas de analítica de
terceros</strong> y no rastrea tu actividad entre aplicaciones.</p>

<h2>5. Cuánto tiempo los conservamos</h2>
<p>Mientras tu cuenta esté activa. Si solicitas la eliminación, borramos tu
cuenta y los datos de tus negocios; los registros de facturación se conservan
solo el plazo exigido por la normativa fiscal aplicable.</p>

<h2>6. Seguridad</h2>
<p>El acceso a los datos está aislado por negocio mediante reglas de seguridad a
nivel de fila. Las credenciales viajan siempre sobre HTTPS y las contraseñas se
almacenan cifradas; nunca en texto plano.</p>

<h2>7. Tus derechos</h2>
<p>Puedes acceder, corregir o suprimir tus datos desde la propia aplicación
(Ajustes) o escribiéndonos. También puedes
<a href="/eliminar-cuenta">eliminar tu cuenta</a> en cualquier momento.</p>

<h2>8. Menores</h2>
<p>El servicio está dirigido a personas mayores de edad que actúan en nombre de
un negocio. No recopilamos conscientemente datos de menores.</p>

<h2>9. Cambios</h2>
<p>Si modificamos esta política, actualizaremos la fecha del encabezado y, si el
cambio es relevante, lo avisaremos dentro de la aplicación.</p>
"""

_TERMS = """
<h2>1. Objeto</h2>
<p>$entity es una aplicación de gestión de citas para negocios de servicios
(barberías, salones, talleres, veterinarias, gimnasios y similares). Permite
administrar servicios, empleados, horarios, clientes y citas.</p>

<h2>2. Tu cuenta</h2>
<p>Debes proporcionar información veraz y mantener la confidencialidad de tu
contraseña. Eres responsable de la actividad realizada desde tu cuenta y de
quienes tengan acceso al negocio.</p>

<h2>3. Datos de tus clientes</h2>
<p>Al registrar datos de tus clientes confirmas que cuentas con la base legal
para hacerlo y que cumples la normativa de protección de datos aplicable. $entity
solo almacena esa información por tu cuenta y según tus instrucciones.</p>

<h2>4. Uso aceptable</h2>
<p>No está permitido usar el servicio para fines ilícitos, enviar comunicaciones
no solicitadas, intentar acceder a datos de otros negocios ni interferir con el
funcionamiento de la plataforma.</p>

<h2>5. Planes y pagos</h2>
<p>El plan Gratis tiene límites de uso (por ejemplo, cantidad de empleados y de
citas por mes). El plan Pro se contrata como suscripción mensual a través de
Google Play, con el precio mostrado en la tienda en tu país.</p>
<p>La renovación es automática salvo que la canceles al menos 24 horas antes del
final del periodo. Puedes gestionarla o cancelarla desde Google Play. Los
reembolsos se rigen por la política de Google Play.</p>

<h2>6. Disponibilidad</h2>
<p>Procuramos mantener el servicio disponible de forma continua, pero no
garantizamos ausencia total de interrupciones por mantenimiento, fallos de red o
causas ajenas. La agenda es una herramienta de apoyo: el negocio sigue siendo
responsable de confirmar sus citas.</p>

<h2>7. Propiedad intelectual</h2>
<p>El software, la marca y el diseño pertenecen a $entity. Tus datos y los de tu
negocio siguen siendo tuyos.</p>

<h2>8. Limitación de responsabilidad</h2>
<p>En la medida permitida por la ley, $entity no responde por daños indirectos,
lucro cesante ni pérdida de datos derivados del uso del servicio.</p>

<h2>9. Terminación</h2>
<p>Puedes dejar de usar el servicio y
<a href="/eliminar-cuenta">eliminar tu cuenta</a> cuando quieras. Podemos
suspender cuentas que incumplan estos términos.</p>

<h2>10. Ley aplicable</h2>
<p>Estos términos se rigen por las leyes de la República de Nicaragua.</p>
"""

_DELETION = """
<h2>Cómo eliminar tu cuenta desde la aplicación</h2>
<ol>
  <li>Abre <strong>$entity</strong> e inicia sesión.</li>
  <li>Ve a la pestaña <strong>Ajustes</strong>.</li>
  <li>Toca <strong>Eliminar cuenta</strong> y confirma la acción.</li>
</ol>
<p>La eliminación es inmediata y definitiva.</p>

<h2>Qué datos se eliminan</h2>
<ul>
  <li>Tu cuenta de usuario: correo, nombre, teléfono y contraseña.</li>
  <li>Los negocios de los que eres dueño.</li>
  <li>Servicios, empleados, horarios y bloqueos de agenda.</li>
  <li>Clientes registrados e historial completo de citas.</li>
</ul>

<h2>Qué datos se conservan</h2>
<p>Únicamente los registros de facturación asociados a compras realizadas en
Google Play, que debemos mantener por obligaciones fiscales y de auditoría. No
contienen datos de tarjetas ni información de contacto de tus clientes.</p>

<h2>Si no puedes acceder a la aplicación</h2>
<p>Escríbenos a <a href="mailto:$email">$email</a> desde el correo con el que
registraste la cuenta e indicando el nombre de tu negocio. Procesaremos la
solicitud en un plazo máximo de 30 días.</p>
"""


def _render(request: Request, title: str, body: str) -> HTMLResponse:
    settings = request.app.state.settings
    return HTMLResponse(
        _PAGE.substitute(
            title=title,
            entity=settings.legal_entity_name,
            email=settings.support_email,
            updated=_UPDATED,
            body=Template(body).substitute(
                entity=settings.legal_entity_name,
                email=settings.support_email,
            ),
        )
    )


@router.get("/privacidad", response_class=HTMLResponse, summary="Política de privacidad")
def privacy_policy(request: Request) -> HTMLResponse:
    return _render(request, "Política de privacidad", _PRIVACY)


@router.get("/terminos", response_class=HTMLResponse, summary="Términos del servicio")
def terms_of_service(request: Request) -> HTMLResponse:
    return _render(request, "Términos del servicio", _TERMS)


@router.get("/eliminar-cuenta", response_class=HTMLResponse, summary="Eliminar cuenta")
def account_deletion(request: Request) -> HTMLResponse:
    return _render(request, "Eliminar cuenta", _DELETION)
