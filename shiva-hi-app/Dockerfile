# Stage 1: builder - create virtualenv and install deps
FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install build deps only for building wheels if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# Copy requirements and create virtualenv
COPY requirements.txt .
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY app.py .

# Stage 2: runtime - small image with only venv and app
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Minimal runtime packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Copy venv and app from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app/app.py /app/app.py

EXPOSE 8000

# Run with gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app", "--workers", "2", "--threads", "4", "--timeout", "120"]
