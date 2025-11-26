# Stage 1: builder - create virtualenv and install deps
FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install build deps only for building wheels if needed (kept minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Copy only requirements first for better layer caching
COPY requirements.txt .

# Create a virtualenv and make sure pip/setuptools/wheel are up-to-date
RUN python -m venv /opt/venv \
 && /opt/venv/bin/python -m pip install --upgrade pip setuptools wheel \
 && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Copy only the app source (keeps builds fast)
COPY app.py .

# Stage 2: runtime - small image with only venv and app
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Minimal runtime packages (ca-certificates needed for TLS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Copy venv and app from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app/app.py /app/app.py

# Create non-root user and give it ownership of /app and venv
RUN addgroup --system appgroup \
 && adduser --system --ingroup appgroup appuser \
 && chown -R appuser:appgroup /opt/venv /app

USER appuser

EXPOSE 8000

# Healthcheck (optional): check root path returns 200
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://127.0.0.1:8000/ || exit 1

# Run with gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app", "--workers", "2", "--threads", "4", "--timeout", "120"]
