# Stage 1: build stage - install dependencies
FROM python:3.11-slim as builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install pip wheel build deps (if needed) and OS packages needed for some packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# Copy requirements and install into a target directory (virtualenv-style)
COPY requirements.txt .
# Create a place for site-packages
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install packages into venv
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY app.py .

# Stage 2: runtime stage - small image with only runtime env + app
FROM python:3.11-slim as runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Minimal runtime OS packages (if required)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Copy venv from builder
COPY --from=builder /opt/venv /opt/venv
# Copy application
COPY --from=builder /app/app.py /app/app.py

EXPOSE 8000

# Run with gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app", "--workers", "2", "--threads", "4", "--timeout", "120"]
