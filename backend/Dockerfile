# Imagen oficial de Python 3.12 (slim para reducir tamaño).
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.txt ./
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY app ./app

# Render inyecta el puerto en la variable PORT.
ENV PORT=8000
EXPOSE 8000

RUN useradd --create-home --uid 1001 appuser
USER appuser

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
