"""Configura el servicio de Render por API (sin tocar el panel).

Uso:
    cd backend
    .venv\\Scripts\\python.exe scripts\\setup_render.py           # crea o actualiza
    .venv\\Scripts\\python.exe scripts\\setup_render.py --dry-run # solo muestra

Credenciales (ninguna se imprime ni se versiona):
    .render-api-key          -> API key de Render (rnd_...)
    .supabase-service-role   -> service_role key de Supabase (opcional)

Si falta el service_role, el script crea el servicio igual y avisa de que hay
que cargarla a mano en el panel.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any

import httpx

ROOT = Path(__file__).resolve().parent.parent.parent
API = "https://api.render.com/v1"
REPO = "https://github.com/davilajon812-arch/https-github.com-jlat30-Agenda"
SERVICE_NAME = "agendapro-api"
BRANCH = "main"
ROOT_DIR = "backend"
REGION = "oregon"
PLAN = "free"

# Valores no secretos del proyecto.
SUPABASE_URL = "https://rvsyvgtdakubkzcaohlh.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_eyikIA42mZ0SqcdOnzRtPQ_5eLuNvml"
SUPABASE_DB_PASSWORD = "BpX1Wq8HxSXTzLxQ"
DATABASE_URL = (
    f"postgresql://postgres.rvsyvgtdakubkzcaohlh:{SUPABASE_DB_PASSWORD}"
    "@aws-1-us-west-2.pooler.supabase.com:5432/postgres"
)
RTDN_TOKEN = "12AtOIL0CVPZzDYNugkoijEx5scvhlpaeQdFG9RBr4TX"
MAINTENANCE_TOKEN = "kNfbwjGJuOB65MvxtT7DHpFondqCheamrZ3Ucg90LWzY"


def read_secret(name: str) -> str:
    """Lee un secreto desde la raíz del repo o desde el entorno."""
    import os

    path = ROOT / name
    if path.exists():
        return path.read_text(encoding="utf-8").strip()
    return os.getenv(name.upper().replace("-", "_"), "").strip()


def build_env_vars(service_role: str) -> list[dict[str, str]]:
    """Variables de entorno del servicio (las mismas de render.yaml)."""
    env: list[dict[str, str]] = [
        {"key": "PYTHON_VERSION", "value": "3.12.8"},
        {"key": "APP_ENV", "value": "prod"},
        {"key": "LOG_LEVEL", "value": "INFO"},
        {"key": "API_V1_PREFIX", "value": "/api/v1"},
        {"key": "BILLING_PROVIDER", "value": "fake"},
        {"key": "GOOGLE_PLAY_PACKAGE_NAME", "value": "com.agendapro.agenda_pro"},
        {"key": "SUPABASE_JWT_AUDIENCE", "value": "authenticated"},
        {"key": "SUPABASE_JWT_SECRET", "value": ""},
        {
            "key": "CORS_ORIGINS",
            "value": "https://agendapro-api.onrender.com,http://localhost:3000",
        },
        {"key": "SUPABASE_URL", "value": SUPABASE_URL},
        {"key": "SUPABASE_ANON_KEY", "value": SUPABASE_ANON_KEY},
        {"key": "DATABASE_URL", "value": DATABASE_URL},
        {"key": "GOOGLE_PUBSUB_RTDN_TOKEN", "value": RTDN_TOKEN},
        {"key": "MAINTENANCE_TOKEN", "value": MAINTENANCE_TOKEN},
    ]
    if service_role:
        env.append({"key": "SUPABASE_SERVICE_ROLE_KEY", "value": service_role})
    return env


class RenderClient:
    def __init__(self, api_key: str, dry_run: bool = False) -> None:
        self._dry = dry_run
        self._http = httpx.Client(
            base_url=API,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            timeout=60,
        )

    def _request(self, method: str, path: str, **kwargs: Any) -> Any:
        if self._dry and method != "GET":
            print(f"    [dry-run] {method} {path}")
            return None
        response = self._http.request(method, path, **kwargs)
        if response.status_code >= 400:
            raise RuntimeError(
                f"{method} {path} -> HTTP {response.status_code}: {response.text[:400]}"
            )
        if not response.content:
            return None
        return response.json()

    def owners(self) -> list[dict[str, Any]]:
        data = self._request("GET", "/owners", params={"limit": 20})
        return [item["owner"] for item in data]

    def services(self, owner_id: str) -> list[dict[str, Any]]:
        data = self._request(
            "GET", "/services", params={"ownerId": owner_id, "limit": 100}
        )
        return [item["service"] for item in data]

    def create_service(self, owner_id: str, env_vars: list[dict[str, str]]) -> dict[str, Any]:
        body = {
            "type": "web_service",
            "name": SERVICE_NAME,
            "ownerId": owner_id,
            "repo": REPO,
            "branch": BRANCH,
            "rootDir": ROOT_DIR,
            "autoDeploy": "yes",
            "envVars": env_vars,
            "serviceDetails": {
                "env": "python",
                "plan": PLAN,
                "region": REGION,
                "healthCheckPath": "/health",
                "envSpecificDetails": {
                    "buildCommand": "pip install -r requirements.txt",
                    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT",
                },
            },
        }
        return self._request("POST", "/services", json=body)

    def update_env(self, service_id: str, env_vars: list[dict[str, str]]) -> Any:
        return self._request(
            "PUT", f"/services/{service_id}/env-vars", json=env_vars
        )

    def deploy(self, service_id: str) -> Any:
        return self._request("POST", f"/services/{service_id}/deploys", json={})

    def latest_deploy(self, service_id: str) -> dict[str, Any] | None:
        data = self._request(
            "GET", f"/services/{service_id}/deploys", params={"limit": 1}
        )
        return data[0]["deploy"] if data else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="no crea nada")
    args = parser.parse_args()

    api_key = read_secret(".render-api-key")
    if not api_key:
        print("[x] Falta la API key de Render.")
        print("    Guárdala en  C:\\WebSite\\Agenda\\.render-api-key")
        print("    (Render → Account Settings → API Keys → Create API Key)")
        return 1

    service_role = read_secret(".supabase-service-role")
    if not service_role:
        print("[!] Sin SUPABASE_SERVICE_ROLE_KEY: cárgala a mano en el panel.")
        print("    (Supabase → Project Settings → API → secret key)")

    client = RenderClient(api_key, dry_run=args.dry_run)

    print("[1/5] Consultando la cuenta de Render...")
    owners = client.owners()
    if not owners:
        print("    [x] La API key no tiene acceso a ninguna cuenta.")
        return 1
    owner = owners[0]
    print(f"    cuenta: {owner['name']} ({owner['type']}) id={owner['id']}")

    print("[2/5] Buscando un servicio existente...")
    existing = [s for s in client.services(owner["id"]) if s["name"] == SERVICE_NAME]
    env_vars = build_env_vars(service_role)

    if existing:
        service = existing[0]
        print(f"    ya existe: {service['id']} ({service.get('suspended') and 'suspendido' or 'activo'})")
        print("[3/5] Actualizando variables de entorno...")
        client.update_env(service["id"], env_vars)
        print(f"    {len(env_vars)} variables configuradas")
    else:
        print("    no existe: se creará")
        print("[3/5] Creando el servicio web...")
        created = client.create_service(owner["id"], env_vars)
        if created is None:  # dry-run
            print("    [dry-run] servicio simulado")
            print("[4/5] dry-run: no se lanza el despliegue")
            return 0
        service = created["service"] if "service" in created else created
        print(f"    creado: {service['id']}")
        print(f"    {len(env_vars)} variables configuradas")

    print("[4/5] Lanzando el despliegue...")
    client.deploy(service["id"])

    if args.dry_run:
        print("[5/5] dry-run: no se espera al despliegue")
        return 0

    print("[5/5] Esperando a que el despliegue esté live (máx. 12 min)...")
    for attempt in range(48):
        time.sleep(15)
        deploy = client.latest_deploy(service["id"])
        if deploy:
            status = deploy.get("status")
            print(f"    [{attempt * 15}s] {status}")
            if status == "live":
                print("\n[ok] Desplegado.")
                print(f"     https://{service.get('serviceDetails', {}).get('url') or service['name'] + '.onrender.com'}")
                return 0
            if status in ("build_failed", "update_failed", "canceled", "pre_deploy_failed"):
                print(f"\n[x] El despliegue falló: {status}")
                return 1

    print("\n[!] Sigue desplegando. Revisa el panel de Render.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
