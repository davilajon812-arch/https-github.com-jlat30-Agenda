"""Configuración de logging para toda la aplicación."""

import logging
import sys

_LOG_FORMAT = "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"


def configure_logging(level: str = "INFO") -> None:
    """Configura el logger raíz una sola vez con salida a stdout."""
    root = logging.getLogger()
    root.setLevel(level.upper())

    if any(isinstance(handler, logging.StreamHandler) for handler in root.handlers):
        return

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter(_LOG_FORMAT))
    root.addHandler(handler)

    # Uvicorn agrega sus propios handlers; los alineamos con el mismo formato.
    for name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        logger = logging.getLogger(name)
        logger.handlers = [handler]
        logger.propagate = False
