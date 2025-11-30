# Docker Configuration

This guide covers Docker setup for DocForge.

## Quick Start

```bash
git clone https://github.com/jonmartin721/docforge-api.git
cd docforge-api
docker-compose up -d
```

The API runs on `http://localhost:5000`. Start the frontend separately:

```bash
cd DocumentGenerator.Client
npm install
npm run dev
```

Frontend runs on `http://localhost:5173`.

## Container Setup

- **Image**: `documentgenerator-api` (built from source)
- **Port Mapping**: `5000:8080` (external:internal)
- **Environment**: Development mode by default
- **Database**: SQLite with persistent storage

## Volume Mounts

```yaml
volumes:
  - ./data:/app/data                              # Database persistence
  - ./GeneratedDocuments:/app/GeneratedDocuments  # PDF output
```

Both directories are created automatically if they don't exist.

## Data Persistence

| Data | Location |
|------|----------|
| Database | `./data/documentgenerator.db` |
| Generated PDFs | `./GeneratedDocuments/` |

## Environment Variables

Create a `.env` file before running:

```bash
cp .env.example .env
```

Key variables:

```bash
DATABASE_CONNECTION_STRING=Data Source=documentgenerator.db
JWT_SECRET=your-super-secret-key-minimum-32-characters
JWT_ISSUER=DocForge
JWT_AUDIENCE=DocForge
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```

## Chrome Dependencies

The Dockerfile includes PuppeteerSharp Chrome dependencies:

```dockerfile
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
```

Chrome is downloaded automatically on first PDF generation.

## Production

```bash
docker-compose -f docker-compose.prod.yml up -d
```

Production considerations:
- Use a strong `JWT_SECRET` (minimum 32 characters)
- Configure secure database connection strings
- Set appropriate CORS origins for your domain
- Use `ASPNETCORE_ENVIRONMENT=Production`

## Ports Reference

| Service | Port | Notes |
|---------|------|-------|
| Docker API | 5000 | Container maps 5000 → 8080 internal |
| Local API | 5257 | When running `dotnet run` directly |
| Frontend | 5173 | Vite dev server |
