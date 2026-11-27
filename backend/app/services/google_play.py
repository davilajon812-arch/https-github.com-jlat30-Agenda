"""Cliente de la Google Play Developer API (subscriptionsv2).

Dos implementaciones con la misma interfaz:
* `HttpGooglePlayClient` llama a la API real con una cuenta de servicio.
* `FakeGooglePlayClient` simula respuestas para desarrollo y pruebas.

La verificación se hace SIEMPRE en el backend: la app nunca decide si una
compra es válida.
"""

from __future__ import annotations

import json
import logging
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any, Protocol

import httpx
import jwt

logger = logging.getLogger(__name__)

ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher"
TOKEN_URL = "https://oauth2.googleapis.com/token"
API_BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3"

# subscriptionState de Play -> estado interno.
STATE_MAP = {
    "SUBSCRIPTION_STATE_ACTIVE": "active",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD": "grace",
    "SUBSCRIPTION_STATE_ON_HOLD": "grace",
    "SUBSCRIPTION_STATE_PAUSED": "paused",
    "SUBSCRIPTION_STATE_CANCELED": "canceled",
    "SUBSCRIPTION_STATE_EXPIRED": "expired",
    "SUBSCRIPTION_STATE_PENDING": "pending",
    "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED": "canceled",
    "SUBSCRIPTION_STATE_UNSPECIFIED": "pending",
}


class PlayError(RuntimeError):
    """Fallo al consultar Google Play."""

    def __init__(self, message: str, status_code: int = 502) -> None:
        super().__init__(message)
        self.status_code = status_code


@dataclass(frozen=True, slots=True)
class PlaySubscription:
    """Estado normalizado de una suscripción de Play."""

    product_id: str
    status: str
    expires_at: datetime | None
    auto_renewing: bool
    acknowledged: bool
    order_id: str | None = None
    obfuscated_account_id: str | None = None
    raw_state: str = ""
    raw: dict[str, Any] = field(default_factory=dict)


class GooglePlayClient(Protocol):
    """Interfaz mínima usada por el servicio de facturación."""

    def get_subscription(self, product_id: str, purchase_token: str) -> PlaySubscription:
        """Consulta el estado actual de la suscripción."""

    def acknowledge(self, product_id: str, purchase_token: str) -> None:
        """Confirma (acknowledge) la compra en Google Play."""


def _parse_time(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def normalize_purchase(data: dict[str, Any], product_id: str) -> PlaySubscription:
    """Convierte la respuesta de subscriptionsv2 al modelo interno."""
    state = str(data.get("subscriptionState") or "")
    line_items = data.get("lineItems") or []

    expires_at: datetime | None = None
    auto_renewing = False
    resolved_product = product_id
    for item in line_items:
        item_expiry = _parse_time(item.get("expiryTime"))
        if item_expiry and (expires_at is None or item_expiry > expires_at):
            expires_at = item_expiry
        plan = item.get("autoRenewingPlan") or {}
        if plan.get("autoRenewEnabled"):
            auto_renewing = True
        if item.get("productId"):
            resolved_product = item["productId"]

    acknowledgement = str(data.get("acknowledgementState") or "")
    account = (data.get("externalAccountIdentifiers") or {}).get(
        "obfuscatedExternalAccountId"
    )

    return PlaySubscription(
        product_id=resolved_product,
        status=STATE_MAP.get(state, "pending"),
        expires_at=expires_at,
        auto_renewing=auto_renewing,
        acknowledged=acknowledgement == "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
        order_id=data.get("latestOrderId"),
        obfuscated_account_id=account,
        raw_state=state,
        raw=data,
    )


class ServiceAccountTokens:
    """Obtiene access tokens con el flujo JWT bearer de una cuenta de servicio."""

    def __init__(self, credentials_json: str, http_client: httpx.Client | None = None):
        try:
            info = json.loads(credentials_json)
        except json.JSONDecodeError as exc:
            raise PlayError("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON no es un JSON válido") from exc

        self._client_email = info.get("client_email")
        self._private_key = info.get("private_key")
        if not self._client_email or not self._private_key:
            raise PlayError("La cuenta de servicio no tiene client_email/private_key")

        self._http = http_client or httpx.Client(timeout=15)
        self._token: str | None = None
        self._expires_at: float = 0

    def get(self) -> str:
        """Devuelve un token válido, refrescándolo si expiró."""
        if self._token and time.time() < self._expires_at - 60:
            return self._token

        now = int(time.time())
        assertion = jwt.encode(
            {
                "iss": self._client_email,
                "scope": ANDROID_PUBLISHER_SCOPE,
                "aud": TOKEN_URL,
                "iat": now,
                "exp": now + 3600,
            },
            self._private_key,
            algorithm="RS256",
        )

        response = self._http.post(
            TOKEN_URL,
            data={
                "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                "assertion": assertion,
            },
        )
        if response.status_code != 200:
            raise PlayError(f"No se pudo autenticar con Google: {response.text[:200]}")

        payload = response.json()
        self._token = payload["access_token"]
        self._expires_at = time.time() + int(payload.get("expires_in", 3600))
        return self._token


class HttpGooglePlayClient:
    """Cliente real contra la Google Play Developer API."""

    def __init__(
        self,
        package_name: str,
        credentials_json: str,
        http_client: httpx.Client | None = None,
    ) -> None:
        self._package = package_name
        self._http = http_client or httpx.Client(timeout=20)
        self._tokens = ServiceAccountTokens(credentials_json, self._http)

    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self._tokens.get()}"}

    def get_subscription(self, product_id: str, purchase_token: str) -> PlaySubscription:
        url = (
            f"{API_BASE}/applications/{self._package}"
            f"/purchases/subscriptionsv2/tokens/{purchase_token}"
        )
        response = self._http.get(url, headers=self._headers())
        if response.status_code == 404:
            raise PlayError("La compra no existe en Google Play", status_code=404)
        if response.status_code != 200:
            logger.warning("Play respondió %s: %s", response.status_code, response.text[:200])
            raise PlayError("Google Play rechazó la consulta")
        return normalize_purchase(response.json(), product_id)

    def acknowledge(self, product_id: str, purchase_token: str) -> None:
        url = (
            f"{API_BASE}/applications/{self._package}"
            f"/purchases/subscriptions/{product_id}/tokens/{purchase_token}:acknowledge"
        )
        response = self._http.post(url, headers=self._headers(), json={})
        if response.status_code not in (200, 204):
            logger.warning(
                "Acknowledge falló (%s): %s", response.status_code, response.text[:200]
            )
            raise PlayError("No se pudo confirmar la compra en Google Play")


class FakeGooglePlayClient:
    """Simula Play para desarrollo local y pruebas automatizadas.

    * `known_tokens=None` (por defecto): modo permisivo, cualquier token se
      considera una compra activa de 30 días. Útil para probar la app sin
      Play Console.
    * `known_tokens={}`: modo estricto, solo los tokens registrados con
      `add_token` existen; el resto responde 404.
    """

    def __init__(
        self,
        package_name: str = "com.turnia.app",
        known_tokens: dict[str, dict[str, Any]] | None = None,
        acknowledged: set[str] | None = None,
    ) -> None:
        self._package = package_name
        self._tokens = known_tokens
        self.acknowledged = acknowledged if acknowledged is not None else set()

    def add_token(
        self,
        token: str,
        product_id: str,
        *,
        days: int = 30,
        state: str = "SUBSCRIPTION_STATE_ACTIVE",
        auto_renewing: bool = True,
        acknowledged: bool = False,
    ) -> None:
        if self._tokens is None:
            self._tokens = {}
        expires = datetime.now(tz=timezone.utc) + timedelta(days=days)
        self._tokens[token] = {
            "kind": "androidpublisher#subscriptionPurchaseV2",
            "subscriptionState": state,
            "acknowledgementState": (
                "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"
                if acknowledged
                else "ACKNOWLEDGEMENT_STATE_PENDING"
            ),
            "lineItems": [
                {
                    "productId": product_id,
                    "expiryTime": expires.isoformat().replace("+00:00", "Z"),
                    "autoRenewingPlan": {"autoRenewEnabled": auto_renewing},
                }
            ],
            "latestOrderId": f"GPA.{token[:8]}",
            "externalAccountIdentifiers": {
                "obfuscatedExternalAccountId": "test-account"
            },
        }
        if acknowledged:
            self.acknowledged.add(token)

    def get_subscription(self, product_id: str, purchase_token: str) -> PlaySubscription:
        if self._tokens is None:
            # Modo permisivo: se genera una compra activa al vuelo.
            self.add_token(purchase_token, product_id)
        data = self._tokens.get(purchase_token)
        if data is None:
            raise PlayError("La compra no existe en Google Play", status_code=404)

        if purchase_token in self.acknowledged:
            data = {**data, "acknowledgementState": "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"}
        return normalize_purchase(data, product_id)

    def acknowledge(self, product_id: str, purchase_token: str) -> None:
        if self._tokens is None:
            self.add_token(purchase_token, product_id)
        if purchase_token not in self._tokens:
            raise PlayError("La compra no existe en Google Play", status_code=404)
        self.acknowledged.add(purchase_token)
