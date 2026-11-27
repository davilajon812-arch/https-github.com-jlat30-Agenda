"""Páginas legales públicas requeridas por las tiendas."""

from __future__ import annotations

from fastapi.testclient import TestClient

import pytest

PAGINAS = ("/privacidad", "/terminos", "/eliminar-cuenta")


@pytest.mark.parametrize("ruta", PAGINAS)
def test_las_paginas_legales_son_publicas(client: TestClient, ruta: str) -> None:
    response = client.get(ruta)

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/html")
    assert "Turnia" in response.text


def test_la_politica_menciona_eliminacion_de_cuenta(client: TestClient) -> None:
    body = client.get("/privacidad").text

    assert "/eliminar-cuenta" in body
    assert "Supabase" in body
    assert "no vendemos datos personales" in body.lower()


def test_la_politica_declara_la_publicidad(client: TestClient) -> None:
    body = client.get("/privacidad").text

    assert "AdMob" in body
    assert "identificador de publicidad" in body
    assert "plan Pro no se muestra ningún anuncio" in body.replace("\n", " ")


def test_la_pagina_de_eliminacion_explica_el_proceso(client: TestClient) -> None:
    body = client.get("/eliminar-cuenta").text

    assert "Ajustes" in body
    assert "Eliminar cuenta" in body
