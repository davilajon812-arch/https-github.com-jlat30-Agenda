"""Límite de peticiones en memoria para los endpoints públicos.

El enlace de reservas se sirve sin autenticación, así que necesita una defensa
básica contra abuso. Render ejecuta una sola instancia de la API, por lo que un
contador en memoria es suficiente; si algún día hay varias instancias, este
módulo debe sustituirse por un limitador compartido (Redis o la propia base).
"""

from __future__ import annotations

import threading
from collections import defaultdict, deque
from time import monotonic


class RateLimiter:
    """Ventana deslizante de N peticiones por clave cada `window` segundos."""

    def __init__(self, limit: int, window: float) -> None:
        self._limit = limit
        self._window = window
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    def allow(self, key: str) -> bool:
        """Registra un intento y dice si está dentro del cupo."""
        now = monotonic()
        with self._lock:
            hits = self._hits[key]
            while hits and now - hits[0] > self._window:
                hits.popleft()
            if len(hits) >= self._limit:
                return False
            hits.append(now)
            return True

    def reset(self) -> None:
        """Vacía los contadores (se usa en las pruebas)."""
        with self._lock:
            self._hits.clear()


# Reservar es la acción sensible: pocas por minuto y por IP.
BOOKING_LIMITER = RateLimiter(limit=6, window=60)
# El resto de lecturas puede ser más generoso (recargar la página, cambiar día…).
READ_LIMITER = RateLimiter(limit=90, window=60)
