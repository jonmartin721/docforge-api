# setup-windows.ps1
# Installs dependencies for DocForge API on Windows

Write-Host "🔧 DocForge Windows Setup" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

# Check for dotnet
if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
    Write-Host "✅ .NET SDK found." -ForegroundColor Green
} else {
    Write-Host "❌ .NET SDK not found! Please install .NET 8 SDK." -ForegroundColor Red
    exit 1
}

# Check for node
if (Get-Command "node" -ErrorAction SilentlyContinue) {
    Write-Host "✅ Node.js found." -ForegroundColor Green
} else {
    Write-Host "❌ Node.js not found! Please install Node.js 18+." -ForegroundColor Red
    exit 1
}

Write-Host "`n📦 Restoring Backend..." -ForegroundColor Yellow
dotnet restore
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Backend restore failed." -ForegroundColor Red
    exit 1
}

Write-Host "`n📦 Installing Frontend Dependencies..." -ForegroundColor Yellow
Push-Location "DocumentGenerator.Client"
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend install failed." -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host "`n=======================" -ForegroundColor Cyan
Write-Host "🎉 Setup complete! You can now run the API." -ForegroundColor Green
Write-Host "   Run .\docforge.ps1 to start." -ForegroundColor Gray
