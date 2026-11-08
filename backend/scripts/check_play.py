"""Verifica la cuenta de servicio de Google Play antes de desplegar.

Uso:
    cd backend
    .venv\\Scripts\\python.exe scripts\\check_play.py
    .venv\\Scripts\\python.exe scripts\\check_play.py <purchase_token>

Comprueba en orden:
1. Que GOOGLE_PLAY_SERVICE_ACCOUNT_JSON sea un JSON válido con client_email y
   private_key.
2. Que Google acepte la clave (obtiene un access token real).
3. Opcionalmente, que la cuenta tenga permisos sobre la app consultando una
   suscripción concreta.

No imprime secretos: solo el correo de la cuenta de servicio y los códigos de
respuesta.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND_ROOT))

import httpx  # noqa: E402

from app.core.config import get_settings  # noqa: E402
from app.services.google_play import (  # noqa: E402
    API_BASE,
    PlayError,
    ServiceAccountTokens,
)


def main() -> int:
    settings = get_settings()
    raw = settings.google_play_service_account_json.strip()

    print(f"BILLING_PROVIDER       = {settings.billing_provider}")
    print(f"GOOGLE_PLAY_PACKAGE    = {settings.google_play_package_name}")

    if not raw:
        print("\n[x] GOOGLE_PLAY_SERVICE_ACCOUNT_JSON está vacío.")
        print("    Pega el JSON completo de la cuenta de servicio en backend/.env")
        return 1

    try:
        info = json.loads(raw)
    except json.JSONDecodeError as exc:
        print(f"\n[x] El valor no es JSON válido: {exc}")
        print("    Copia el archivo .json completo, en una sola línea.")
        return 1

    email = info.get("client_email", "(sin client_email)")
    project = info.get("project_id", "(sin project_id)")
    print(f"\nCuenta de servicio     = {email}")
    print(f"Proyecto               = {project}")

    if info.get("type") != "service_account":
        print("[!] El JSON no parece de tipo service_account.")

    print("\n[1/2] Solicitando access token a Google...")
    try:
        tokens = ServiceAccountTokens(raw, httpx.Client(timeout=20))
        token = tokens.get()
    except PlayError as exc:
        print(f"    [x] {exc}")
        print("    Revisa que la private_key esté completa (con sus \\n).")
        return 1

    print(f"    [ok] Token obtenido ({len(token)} caracteres).")

    if len(sys.argv) < 2:
        print("\n[2/2] Omitido: sin purchase_token no se puede probar el permiso")
        print("      de la app. Ejecuta de nuevo pasando un token de compra real.")
        return 0

    purchase_token = sys.argv[1]
    print(f"\n[2/2] Consultando la suscripción {purchase_token[:12]}...")

    url = (
        f"{API_BASE}/applications/{settings.google_play_package_name}"
        f"/purchases/subscriptionsv2/tokens/{purchase_token}"
    )
    response = httpx.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=20)

    if response.status_code == 200:
        data = response.json()
        print(f"    [ok] Estado: {data.get('subscriptionState')}")
        return 0

    if response.status_code == 404:
        print("    [ok] Credenciales y permisos correctos (el token no existe).")
        return 0

    if response.status_code in (401, 403):
        print(f"    [x] Sin permisos (HTTP {response.status_code}).")
        print("        Falta invitar la cuenta de servicio en Play Console con")
        print("        permiso para ver datos financieros y gestionar suscripciones.")
        return 1

    print(f"    [?] HTTP {response.status_code}: {response.text[:200]}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
