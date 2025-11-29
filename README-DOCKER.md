# 🐳 DocForge - Docker Quick Start

**Generate PDFs from templates with zero setup required**

> **🚀 New to DocForge?** [Start here in 2 minutes →](QUICK-START.md)

## ⚡ One-Command Setup

**Prerequisites:** Just Docker Desktop installed

```bash
# Clone and run (works on Windows, Linux, macOS)
git clone https://github.com/your-repo/docforge-api.git
cd docforge-api
./scripts/docker-quick-start.sh  # or .\scripts\docker-quick-start.ps1 on Windows
```

That's it! Your browser will open to the running application.

## 🎯 What You Get

- **📱 Web Interface**: Create and manage templates
- **🔌 REST API**: Integrate with your applications
- **📄 PDF Generation**: High-quality PDF output
- **🔧 Template Editor**: Visual template builder
- **📊 Swagger UI**: Interactive API documentation

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Nginx Proxy   │    │   .NET 8 API    │
│   (React)       │───▶│   (Optional)    │───▶│   (Puppeteer)   │
│   Port: 5173    │    │   Port: 80      │    │   Port: 5000    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                                ┌─────────────────┐
                                                │   SQLite DB     │
                                                │   Chrome/Edge   │
                                                └─────────────────┘
```

## 🔧 Docker Commands

```bash
# Start everything (development mode)
docker-compose -f docker-compose.simple.yml up -d

# Start everything (production mode)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop everything
docker-compose down

# Rebuild after changes
docker-compose up -d --build
```

## 🌐 Access Points

| Service | Development | Production |
|---------|-------------|------------|
| Frontend | http://localhost:5173 | http://localhost |
| API | http://localhost:5000 | http://localhost/api |
| API Docs | http://localhost:5000/swagger | http://localhost/swagger |

## 📦 Container Details

### API Container (`docforge-api`)
- **Base**: .NET 8 ASP.NET Runtime
- **Features**: PDF generation, JWT auth, SQLite
- **Health Check**: `/health`
- **Data Persistence**: `./data` and `./GeneratedDocuments`

### Frontend Container (`docforge-frontend`)
- **Base**: Node.js 18 Alpine
- **Features**: Hot reload, Vite dev server
- **Development Only**: Not used in production mode

### Nginx Container (`docforge-web`)
- **Base**: Nginx Alpine
- **Features**: Reverse proxy, static file serving, gzip
- **Production Only**: Single entry point for all services

## 🔒 Environment Configuration

The Docker setup includes secure defaults:

```yaml
environment:
  - ASPNETCORE_ENVIRONMENT=Development
  - ConnectionStrings__DefaultConnection=Data Source=/app/data/documentgenerator.db
  - JwtSettings__Secret=THIS_IS_A_SUPER_SECRET_KEY_FOR_JWT_TOKEN_GENERATION_AT_LEAST_32_CHARS
```

**For production**, update these values in your own `docker-compose.override.yml`.

## 📁 File Structure

```
docforge-api/
├── docker-compose.yml          # Production setup
├── docker-compose.simple.yml   # Development setup
├── Dockerfile                  # Multi-stage .NET build
├── nginx/                      # Nginx configuration
├── scripts/
│   ├── docker-quick-start.ps1 # Windows automation
│   └── docker-quick-start.sh  # Unix automation
├── DocumentGenerator.API/      # .NET backend
├── DocumentGenerator.Client/    # React frontend
├── data/                       # SQLite database (auto-created)
└── GeneratedDocuments/          # PDF output (auto-created)
```

## 🎯 Development Workflow

1. **Make changes** to the code
2. **Rebuild** containers: `docker-compose up -d --build`
3. **Frontend hot-reloads** automatically
4. **API restarts** automatically
5. **Data persists** across container restarts

## 🏭 Production Deployment

For production deployment:

```bash
# 1. Build and deploy production version
docker-compose --profile build up
docker-compose up -d

# 2. Configure environment variables
# Create docker-compose.override.yml with your settings

# 3. Set up SSL certificates
# Place certs in ./ssl/ directory

# 4. Configure backup strategy
# Backup ./data/ directory regularly
```

## 🔍 Advanced Configuration

### Custom Ports
```yaml
services:
  docforge-api:
    ports:
      - "8080:8080"  # API on port 8080
```

### External Database
```yaml
services:
  docforge-api:
    environment:
      - ConnectionStrings__DefaultConnection=Server=my-db;Database=docforge
```

### Custom Volumes
```yaml
volumes:
  postgres_data:
    driver: local
```

## 🆘 Troubleshooting

### Container Issues
```bash
# Check container status
docker ps

# View container logs
docker-compose logs docforge-api

# Debug inside container
docker-compose exec docforge-api sh
```

### Port Conflicts
```bash
# Find what's using the port
lsof -i :5173  # Linux/macOS
netstat -ano | findstr :5173  # Windows

# Kill the process
kill -9 <PID>
```

### Performance Issues
```bash
# Monitor resource usage
docker stats

# Clean up unused images
docker system prune -a
```

## 📚 Additional Resources

- [📖 Full Documentation](README.md)
- [⚡ Quick Start Guide](QUICK-START.md)
- [🔧 Setup Wizards](scripts/)
- [🐛 Report Issues](https://github.com/your-repo/docforge-api/issues)

---

**🎉 Docker makes DocForge truly portable and hassle-free!**