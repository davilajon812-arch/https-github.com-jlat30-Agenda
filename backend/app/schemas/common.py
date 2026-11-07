"""Esquemas compartidos por toda la API."""

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Respuesta del endpoint de estado del servicio."""

    status: str = Field(description="Estado del servicio", examples=["ok"])
    service: str = Field(description="Nombre del servicio")
    version: str = Field(description="Versión desplegada")
    environment: str = Field(description="Entorno de ejecución (dev, prod)")


class ErrorResponse(BaseModel):
    """Cuerpo estándar de error."""

    detail: str = Field(description="Descripción del error")
