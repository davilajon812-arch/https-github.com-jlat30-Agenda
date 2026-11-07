"""Configuración central de la aplicación basada en variables de entorno."""

from functools import lru_cache
from typing import Annotated, Literal

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración leída desde .env o desde variables de entorno de Render."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    # --- Aplicación ---
    app_name: str = "AgendaPro API"
    app_version: str = "0.1.0"
    app_env: Literal["dev", "prod"] = "dev"
    api_v1_prefix: str = "/api/v1"
    log_level: str = "INFO"

    # --- CORS ---
    # Lista separada por comas: "http://localhost:3000,https://app.agendapro.com"
    # NoDecode evita que pydantic-settings intente parsear el valor como JSON.
    cors_origins: Annotated[list[str], NoDecode] = Field(
        default_factory=lambda: ["http://localhost:3000"]
    )

    # --- Supabase ---
    supabase_url: str = ""
    supabase_anon_key: str = ""
    supabase_service_role_key: str = ""
    # Proyectos nuevos usan llaves asimétricas (JWKS); si se define el secreto
    # HS256 se valida con él (útil para desarrollo y pruebas).
    supabase_jwt_secret: str = ""
    supabase_jwt_audience: str = "authenticated"

    # --- Base de datos (Postgres de Supabase) ---
    # Cadena del pooler, por ejemplo:
    # postgresql://postgres.<ref>:<password>@aws-0-us-east-1.pooler.supabase.com:6543/postgres
    database_url: str = ""
    database_pool_min_size: int = 1
    database_pool_max_size: int = 8


    @field_validator("cors_origins", mode="before")
    @classmethod
    def _split_origins(cls, value: object) -> object:
        """Permite definir CORS_ORIGINS como texto separado por comas."""
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value

    @property
    def is_production(self) -> bool:
        """Indica si la aplicación corre en producción."""
        return self.app_env == "prod"

    @property
    def jwks_url(self) -> str:
        """URL del conjunto de llaves públicas de Supabase Auth."""
        return f"{self.supabase_url.rstrip('/')}/auth/v1/.well-known/jwks.json"


@lru_cache
def get_settings() -> Settings:
    """Devuelve una única instancia de configuración (cacheada)."""
    return Settings()
