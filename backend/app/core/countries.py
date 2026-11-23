"""Prefijos telefónicos de los países que soporta la app.

El catálogo de países vive en la app (es el que llena el formulario). Aquí solo
se traduce el código ISO al prefijo, para mostrar formateado el teléfono del
negocio en la página pública. Si un país no está en el mapa, la página muestra
el número tal cual: nunca falla.
"""

from __future__ import annotations

DIAL_CODES: dict[str, str] = {
    "NI": "505",
    "CR": "506",
    "GT": "502",
    "HN": "504",
    "SV": "503",
    "PA": "507",
    "MX": "52",
    "CO": "57",
    "PE": "51",
    "DO": "1809",
    "AR": "54",
    "CL": "56",
    "EC": "593",
    "BO": "591",
    "PY": "595",
    "UY": "598",
    "VE": "58",
    "PR": "1787",
}


def dial_code(country_code: str | None) -> str | None:
    """Prefijo del país (sin `+`), o `None` si no se conoce."""
    if not country_code:
        return None
    return DIAL_CODES.get(country_code.strip().upper())
