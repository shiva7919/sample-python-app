
---

# 🚀 Sample Python App – CI/CD with Docker, Docker Hub & GitHub Actions

A simple Python Flask application that prints:

```
hi from shiva ..
```

This project includes:

* ✔ Multi-stage Dockerfile for production
* ✔ GitHub Actions CI/CD pipeline
* ✔ Automatic deployment to AWS EC2
* ✔ Docker Hub integration
* ✔ Gunicorn production server
* ✔ App runs as non-root user

---

## 📁 Project Structure

```
sample-python-app/
│
├── shiva-hi-app/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── deploy.sh
│   ├── .dockerignore
│   └── README.md
│
└── .github/
    └── workflows/
        └── docker-deploy.yml
```

---

# 🐳 Multi-Stage Production Dockerfile

This Dockerfile:

* Uses Python 3.11 slim image
* Creates a virtual environment inside the image
* Installs dependencies in a separate builder layer
* Copies only required files
* Runs the app using Gunicorn
* Runs as non-root user (security best practice)
* Includes optional healthcheck

---

### **`shiva-hi-app/Dockerfile`**

```dockerfile
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
```
✅ FINAL docker-deploy.yml (Copy & Paste as-is)
```
name: Build → Push → Deploy

on:
  push:
    branches:
      - main

jobs:
  build-and-push:
    name: Build & push to Docker Hub
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USER }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: ./shiva-hi-app
          file: ./shiva-hi-app/Dockerfile
          push: true
          tags: shivasarla2398/sample-python-app:latest
          platforms: linux/amd64

  deploy:
    name: Deploy to EC2 via SSH
    runs-on: ubuntu-latest
    needs: build-and-push

    steps:
      - name: Install SSH client
        run: sudo apt-get update && sudo apt-get install -y openssh-client

      - name: Check required SSH secrets
        id: check
        run: |
          if [ -n "${{ secrets.SSH_KEY }}" ] && [ -n "${{ secrets.SSH_HOST }}" ] && [ -n "${{ secrets.SSH_USER }}" ]; then
            echo "do_deploy=true" >> $GITHUB_OUTPUT
          else
            echo "do_deploy=false" >> $GITHUB_OUTPUT
          fi

      - name: Start ssh-agent and add key
        if: steps.check.outputs.do_deploy == 'true'
        uses: webfactory/ssh-agent@v0.9.1
        with:
          ssh-private-key: ${{ secrets.SSH_KEY }}

      - name: Pull image & restart container on EC2
        if: steps.check.outputs.do_deploy == 'true'
        run: |
          ssh -o StrictHostKeyChecking=no ${{ secrets.SSH_USER }}@${{ secrets.SSH_HOST }} << 'EOF'
            set -e
            echo "Stopping existing container (if any)..."
            docker rm -f sample-python-app || true

            echo "Pulling latest image..."
            docker pull shivasarla2398/sample-python-app:latest

            echo "Starting new container..."
            docker run -d --name sample-python-app -p 80:8000 --restart unless-stopped \
              shivasarla2398/sample-python-app:latest

            echo "Deployment completed successfully."
          EOF

      - name: SSH deploy skipped
        if: steps.check.outputs.do_deploy == 'false'
        run: |
          echo "SSH deploy skipped — missing SSH_KEY or SSH_HOST or SSH_USER secrets."
```

---

# ⚙️ GitHub Actions CI/CD (Build → Push → Deploy)

Your pipeline is located at:
<img width="1919" height="1079" alt="Screenshot 2025-11-26 115706" src="https://github.com/user-attachments/assets/8dc91d72-3035-4a5e-b01e-d9f19c956ee1" />
<img width="1909" height="1079" alt="Screenshot 2025-11-26 115016" src="https://github.com/user-attachments/assets/f8d4d20e-c07c-4e05-b650-12317f0029ea" />


```
.github/workflows/docker-deploy.yml
```

### Pipeline Overview

✔ Build Docker image
✔ Push to Docker Hub
✔ SSH into EC2
✔ Pull latest image
✔ Restart container
✔ Production-ready

---

# 🔐 GitHub Secrets Required

| Secret Name    | Description                         |
| -------------- | ----------------------------------- |
| `DOCKER_USER`  | Docker Hub username                 |
| `DOCKER_TOKEN` | Docker Hub access token             |
| `SSH_HOST`     | EC2 public IP                       |
| `SSH_USER`     | EC2 login user (`ubuntu`)           |
| `SSH_KEY`      | Private SSH key used for deployment |

---

# ☁️ EC2 Deployment

### App runs automatically on:

```
http://<YOUR-EC2-PUBLIC-IP>
```
<img width="1919" height="1079" alt="Screenshot 2025-11-26 115739" src="https://github.com/user-attachments/assets/5468fac9-f3cb-40c6-a6c3-8f9f28d0d54d" />

### Security Groups Required

| Port | Description               |
| ---- | ------------------------- |
| 22   | SSH access (your IP only) |
| 80   | Web access (public)       |

---

# 🧪 Testing

Check running container:

```bash
docker ps
docker logs sample-python-app
```

Test app:

```
curl http://EC2-IP
```


Expected:
<img width="1919" height="1079" alt="Screenshot 2025-11-26 115050" src="https://github.com/user-attachments/assets/d1bd8fc1-d417-45c5-a05e-785a24af8cb1" />

```
hi from shiva ..


```
<img width="1919" height="1079" alt="Screenshot 2025-11-26 115640" src="https://github.com/user-attachments/assets/2b19c5bf-7949-45f7-a962-a89c74cbf81c" />
<img width="1549" height="525" alt="Screenshot 2025-11-26 120320" src="https://github.com/user-attachments/assets/d4a213ef-80b8-418d-a89e-63c0eeb82413" />

---

# 🐛 Troubleshooting

### ❌ Permission denied (publickey)

Your `SSH_KEY` does not match EC2 `authorized_keys`.

Fix:
Add public key from `ssh-keygen -y -f <key>` → into EC2.

---


