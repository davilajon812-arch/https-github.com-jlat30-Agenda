"""Carga la cuenta de servicio de Google Play en local y en Render.

Uso:
    cd backend
    .venv\\Scripts\\python.exe scripts\\setup_billing.py --validate   # solo valida
    .venv\\Scripts\\python.exe scripts\\setup_billing.py --apply      # valida y carga

Lee el JSON desde  C:\\WebSite\\Agenda\\.google-play-sa.json  (no versionado).
Nunca imprime la private_key: solo el correo de la cuenta y los códigos HTTP.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import httpx

ROOT = Path(__file__).resolve().parent.parent.parent
BACKEND = ROOT / "backend"
SA_PATH = ROOT / ".google-play-sa.json"
ENV_PATH = BACKEND / ".env"
RENDER_API = "https://api.render.com/v1"
SERVICE_ID = "srv-dbt5j3ei0phs73eookog"


def load_service_account() -> dict[str, Any] | None:
    if not SA_PATH.exists():
        print(f"[x] No existe {SA_PATH}")
        print("    Guarda el JSON de la cuenta de servicio con ese nombre exacto.")
        return None

    raw = SA_PATH.read_text(encoding="utf-8").strip()
    try:
        info = json.loads(raw)
    except json.JSONDecodeError as exc:
        print(f"[x] El archivo no es JSON válido: {exc}")
        return None

    required = ("type", "client_email", "private_key", "project_id")
    missing = [key for key in required if not info.get(key)]
    if missing:
        print(f"[x] Faltan campos: {', '.join(missing)}")
        return None

    if info["type"] != "service_account":
        print(f"[!] type = {info['type']} (se esperaba 'service_account')")

    if "\\n" in info["private_key"]:
        print("[!] La private_key tiene '\\n' literales; se normalizarán al guardar.")

    print(f"[ok] JSON válido")
    print(f"     cuenta  : {info['client_email']}")
    print(f"     proyecto: {info['project_id']}")
    print(f"     key_id  : {info.get('private_key_id', '(sin id)')[:12]}...")
    return info


def normalize(info: dict[str, Any]) -> str:
    """JSON en una sola línea, con saltos de línea reales en private_key."""
    copy = dict(info)
    copy["private_key"] = copy["private_key"].replace("\\n", "\n")
    return json.dumps(copy, separators=(",", ":"))


def verify_google(info: dict[str, Any]) -> bool:
    """Pide un access token real a Google para comprobar la clave."""
    sys.path.insert(0, str(BACKEND))
    from app.services.google_play import PlayError, ServiceAccountTokens

    print("\n[1/2] Solicitando access token a Google...")
    try:
        tokens = ServiceAccountTokens(normalize(info), httpx.Client(timeout=25))
        token = tokens.get()
    except PlayError as exc:
        print(f"     [x] {exc}")
        return False
    print(f"     [ok] token obtenido ({len(token)} caracteres)")
    return True


def update_local_env(info: dict[str, Any]) -> None:
    print("\n[2/2] Actualizando backend/.env ...")
    if not ENV_PATH.exists():
        print(f"     [x] No existe {ENV_PATH}")
        return

    value = normalize(info)
    lines = ENV_PATH.read_text(encoding="utf-8").splitlines()
    out: list[str] = []
    seen = False

    for line in lines:
        if line.startswith("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="):
            out.append(f"GOOGLE_PLAY_SERVICE_ACCOUNT_JSON={value}")
            seen = True
        elif line.strip() == "BILLING_PROVIDER=fake":
            out.append("BILLING_PROVIDER=play")
        else:
            out.append(line)

    if not seen:
        out.append(f"GOOGLE_PLAY_SERVICE_ACCOUNT_JSON={value}")
    if not any(line.strip() == "BILLING_PROVIDER=play" for line in out):
        out.append("BILLING_PROVIDER=play")

    ENV_PATH.write_text("\n".join(out) + "\n", encoding="utf-8")
    print("     [ok] backend/.env actualizado (BILLING_PROVIDER=play)")


def update_render(info: dict[str, Any]) -> bool:
    key_path = ROOT / ".render-api-key"
    if not key_path.exists():
        print("\n[!] Sin .render-api-key: carga el JSON a mano en Render.")
        return False

    api_key = key_path.read_text(encoding="utf-8").strip()
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    print("\n[+] Actualizando Render ...")

    with httpx.Client(base_url=RENDER_API, headers=headers, timeout=60) as client:
        current = client.get(
            f"/services/{SERVICE_ID}/env-vars", params={"limit": 100}
        )
        if current.status_code != 200:
            print(f"     [x] No se pudieron leer las variables ({current.status_code})")
            return False

        env = [
            {"key": item["envVar"]["key"], "value": item["envVar"]["value"]}
            for item in current.json()
        ]
        value = normalize(info)
        wanted = {
            "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON": value,
            "BILLING_PROVIDER": "play",
        }

        replaced: set[str] = set()
        for item in env:
            if item["key"] in wanted:
                item["value"] = wanted[item["key"]]
                replaced.add(item["key"])
        for key, val in wanted.items():
            if key not in replaced:
                env.append({"key": key, "value": val})

        put = client.put(f"/services/{SERVICE_ID}/env-vars", json=env)
        print(f"     [{'ok' if put.status_code < 300 else 'x'}] PUT env-vars -> {put.status_code}")

        deploy = client.post(f"/services/{SERVICE_ID}/deploys", json={})
        print(f"     [{'ok' if deploy.status_code < 300 else 'x'}] deploy -> {deploy.status_code}")

        return put.status_code < 300 and deploy.status_code < 300


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--validate", action="store_true", help="solo valida")
    parser.add_argument("--apply", action="store_true", help="valida y carga")
    parser.add_argument("--skip-google", action="store_true", help="no consulta a Google")
    args = parser.parse_args()

    info = load_service_account()
    if info is None:
        return 1

    if not args.skip_google and not verify_google(info):
        print("\n[!] La clave no pudo autenticarse con Google.")
        print("    Revisa que la API 'Google Play Android Developer API' esté habilitada")
        print("    en el proyecto y que el JSON sea de tipo service_account.")
        return 1

    if args.validate and not args.apply:
        print("\n[ok] Validación completa. Usa --apply para cargar en local y Render.")
        return 0

    update_local_env(info)
    update_render(info)

    print("\n[!] Recuerda invitar la cuenta de servicio en Play Console:")
    print(f"    {info['client_email']}")
    print("    Usuarios y permisos -> Invitar -> rol con 'Ver datos financieros,")
    print("    pedidos y gestión de suscripciones' + permiso de la app.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
