# PHP Container App

A lightweight, containerized PHP application.

## Features
- **Multi-stage Docker Build:** Results in a small image size (~8MB).
- **Configurable Port:** Change listening port via Environment Variable.
- **Health Check:** Exposes `/health` endpoint for Load Balancers.
- **Logging:** Streams access logs directly to stdout/stderr.
- **Security:** Runs as a non-root user.

## Project Structure
- `public/`: Contains the application source code.
- `Dockerfile`: Multi-stage build definition.

## Getting Started

### 1. Build the Image
```bash
docker build -t php-health-app .
```

### 2. Run the Container
Default Port (8080):
```bash
docker run -d --name php-health-app -p 8080:8080 php-health-app
```
Custom Port (e.g., 3000):
```bash
docker run -d --name php-health-app \
  -e PORT=3000 \
  -p 3000:3000 \
  php-health-app
```
### 3. Verification
Check Health Endpoint:
```bash
curl -i http://localhost:8080/health
```
Response:
```json
HTTP/1.1 200 OK
Content-Type: application/json

{"status":"healthy"}
```
Check Logs:
```bash
docker logs -f php-health-app
```
We should see output similar to:

`[2025-12-28T19:34:32+00:00] GET /health - curl/8.7.1`