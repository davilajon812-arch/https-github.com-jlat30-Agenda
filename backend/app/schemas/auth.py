"""Esquemas relacionados con la autenticación."""

from pydantic import BaseModel, EmailStr, Field


class CurrentUserResponse(BaseModel):
    """Usuario autenticado según el token de Supabase."""

    id: str = Field(description="UUID del usuario en Supabase Auth")
    email: EmailStr | None = Field(default=None, description="Correo del usuario")
    role: str = Field(description="Rol del JWT (normalmente 'authenticated')")
