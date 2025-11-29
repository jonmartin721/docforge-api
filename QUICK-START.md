# 🚀 DocForge Quick Start

**The fastest way to get DocForge running - no development experience required!**

## 🐳 Docker Quick Start (Recommended)

**Just one prerequisite:** [Docker Desktop](https://www.docker.com/products/docker-desktop)

### Windows
```powershell
# Clone and run
git clone https://github.com/your-repo/docforge-api.git
cd docforge-api
.\scripts\docker-quick-start.ps1
```

### Linux/macOS
```bash
# Clone and run
git clone https://github.com/your-repo/docforge-api.git
cd docforge-api
./scripts/docker-quick-start.sh
```

That's it! The script will:
- ✅ Check if Docker is running
- ✅ Build everything automatically
- ✅ Start both frontend and backend
- ✅ Open your browser to the app

## 🎯 What You Get

| Development Mode | Production Mode |
|------------------|-----------------|
| 🚀 Fast startup | ⚡ Optimized build |
| 🔄 Live reloading | 🏭 Single port access |
| Frontend: http://localhost:5173 | Everything: http://localhost |
| API: http://localhost:5000 | API: http://localhost/api |

## 🔧 Management Commands

```powershell
# Windows
.\scripts\docker-quick-start.ps1 --logs    # View logs
.\scripts\docker-quick-start.ps1 --stop     # Stop everything
.\scripts\docker-quick-start.ps1 --production # Production mode

# Linux/macOS
./scripts/docker-quick-start.sh --logs     # View logs
./scripts/docker-quick-start.sh --stop      # Stop everything
./scripts/docker-quick-start.sh --production # Production mode
```

## 📁 Project Structure

```
docforge-api/
├── DocumentGenerator.API/     # .NET 8 Web API
├── DocumentGenerator.Client/   # React frontend
├── scripts/                   # Setup and automation scripts
├── nginx/                     # Production reverse proxy config
├── data/                      # SQLite database (auto-created)
└── GeneratedDocuments/        # PDF output (auto-created)
```

## 🛠️ What's Happening Under the Hood

The Docker setup includes:

- **.NET 8 API** with PDF generation capabilities
- **React frontend** with Vite dev server
- **SQLite database** (automatically initialized)
- **Nginx reverse proxy** (production mode)
- **All Chrome dependencies** for PDF generation

## 🔍 Alternative Setup Options

If you prefer local development instead of Docker:

### Interactive Setup (Recommended)
```powershell
# Windows
.\scripts\setup-wizard.ps1

# Linux/macOS
./scripts/setup-wizard.sh
```

### Manual Setup
1. Install [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
2. Install [Node.js 18+](https://nodejs.org/)
3. Run the native CLI:
   ```powershell
   # Windows
   .\docforge.ps1

   # Linux/macOS
   ./docforge.sh
   ```

## 🆘 Troubleshooting

### Docker Issues
- **"Docker not running"**: Start Docker Desktop
- **"Port already in use"**: Stop other apps using ports 5173 or 5000
- **Build fails**: Check internet connection, run `docker system prune`

### Application Issues
- **Frontend not loading**: Check logs with `--logs` flag
- **API errors**: Verify containers are running with `docker ps`
- **PDF generation fails**: Chrome dependencies are included in Docker

### Performance Tips
- **First run**: May take 5-10 minutes to download and build
- **Subsequent starts**: Usually under 30 seconds
- **Development mode**: Uses more CPU for live reloading
- **Production mode**: Better performance, single port

## 🎯 Next Steps

Once DocForge is running:

1. **Create your first template** in the web interface
2. **Test PDF generation** with sample data
3. **Explore the API** at `/swagger`
4. **Check the documentation** in the repository

## 📞 Need Help?

- **Issues**: [GitHub Issues](https://github.com/your-repo/docforge-api/issues)
- **Documentation**: [Full Docs](./README.md)
- **Community**: [Discussions](https://github.com/your-repo/docforge-api/discussions)

---

**🎉 Congratulations! You now have DocForge running in minutes, not hours!**