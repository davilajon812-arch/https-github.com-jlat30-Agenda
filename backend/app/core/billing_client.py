"""Construcción del cliente de Google Play según la configuración."""

from __future__ import annotations

import logging

from app.core.config import Settings
from app.services.google_play import (
    FakeGooglePlayClient,
    GooglePlayClient,
    HttpGooglePlayClient,
    PlayError,
)

logger = logging.getLogger(__name__)


def build_play_client(settings: Settings) -> GooglePlayClient | None:
    """Devuelve el cliente de Play o `None` si no hay configuración válida.

    `BILLING_PROVIDER=fake` (por defecto en desarrollo) permite probar todo el
    flujo sin cuenta de servicio.
    """
    if settings.billing_provider == "fake":
        logger.warning(
            "BILLING_PROVIDER=fake: las compras se simulan, no se cobra nada."
        )
        return FakeGooglePlayClient(settings.google_play_package_name)

    if not settings.google_play_service_account_json:
        logger.error(
            "BILLING_PROVIDER=play sin GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: "
            "la verificación de compras responderá 503."
        )
        return None

    try:
        return HttpGooglePlayClient(
            settings.google_play_package_name,
            settings.google_play_service_account_json,
        )
    except PlayError as exc:
        logger.error("Cuenta de servicio inválida: %s", exc)
        return None
