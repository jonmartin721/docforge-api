# DocForge Docker Quick Start for Windows
# The ultimate zero-prerequisite setup - just Docker required

param(
    [switch]$Simple,
    [switch]$Production,
    [switch]$Stop,
    [switch]$Logs
)

# Color output functions
function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Header {
    param([string]$Title)
    Clear-Host
    Write-Host $Title -ForegroundColor White
    Write-Host "=" * 50 -ForegroundColor White
    Write-Host ""
}

function Wait-For-Enter {
    param([string]$Message = "Press Enter to continue...")
    Write-Host ""
    Read-Host $Message
}

function Test-Docker {
    Write-Info "Checking Docker availability..."

    if (Get-Command docker -ErrorAction SilentlyContinue) {
        try {
            $dockerInfo = docker info 2>&1
            if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
                Write-Success "[OK] Docker is available and running"
                return $true
            } else {
                Write-Warning "[WARN] Docker is installed but not running"
                Write-Info "Please start Docker Desktop and try again"
                return $false
            }
        }
        catch {
            Write-Warning "[WARN] Docker check failed"
            return $false
        }
    } else {
        Write-Error "[ERROR] Docker is not installed"
        Write-Info "Please install Docker Desktop first:"
        Write-Info "https://www.docker.com/products/docker-desktop"
        return $false
    }
}

function Start-DocForge {
    param([switch]$IsProduction)

    Write-Header "[START] Starting DocForge with Docker"

    # Check if docker-compose.yml exists
    $composeFile = if ($IsProduction) { "docker-compose.yml" } else { "docker-compose.simple.yml" }

    if (-not (Test-Path $composeFile)) {
        Write-Error "[ERROR] $composeFile not found. Please run this from the project root."
        Wait-For-Enter
        return
    }

    Write-Info "[DOCKER] Building and starting containers..."
    Write-Info "This may take a few minutes on the first run..."
    Write-Host ""

    try {
        # Build and start containers
        if ($IsProduction) {
            # Production mode - build frontend first
            Write-Info "Building frontend..."
            docker-compose --profile build up docforge-frontend-builder

            Write-Info "Starting production services..."
            docker-compose up -d
        } else {
            # Simple development mode
            Write-Info "Starting development services..."
            docker-compose -f $composeFile up -d
        }

        if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
            Write-Success "[OK] DocForge is starting up!"
            Write-Host ""
            Write-Info "[URLs] Application URLs:"

            if ($IsProduction) {
                Write-Host "   Web App: http://localhost" -ForegroundColor White
                Write-Host "   API: http://localhost/api" -ForegroundColor White
                Write-Host "   API Docs: http://localhost/swagger" -ForegroundColor White
            } else {
                Write-Host "   Frontend: http://localhost:5173" -ForegroundColor White
                Write-Host "   API: http://localhost:5000" -ForegroundColor White
                Write-Host "   API Docs: http://localhost:5000/swagger" -ForegroundColor White
            }

            Write-Host ""
            Write-Info "[COMMANDS] Management Commands:"
            Write-Host "   View logs: .\scripts\docker-quick-start.ps1 -Logs" -ForegroundColor Gray
            Write-Host "   Stop app: .\scripts\docker-quick-start.ps1 -Stop" -ForegroundColor Gray
            Write-Host "   Restart: docker-compose restart" -ForegroundColor Gray
            Write-Host ""

            Wait-For-Enter "Press Enter to open the application in your browser..."

            # Open browser
            $url = if ($IsProduction) { "http://localhost" } else { "http://localhost:5173" }
            Start-Process $url

        } else {
            Write-Error "[ERROR] Failed to start containers"
            Write-Warning "Please check the error messages above."
        }
    }
    catch {
        Write-Error "[ERROR] Error starting DocForge: $($_.Exception.Message)"
        Write-Info "Please check Docker is running and you have sufficient disk space."
    }
}

function Stop-DocForge {
    Write-Header "[STOP] Stopping DocForge"

    try {
        Write-Info "Stopping all DocForge containers..."
        docker-compose down

        # Also stop simple version if it's running
        docker-compose -f docker-compose.simple.yml down 2>&1 | Out-Null

        Write-Success "[OK] All DocForge containers stopped"
        Write-Info "Data volumes are preserved. Use 'docker system prune' to clean up."
    }
    catch {
        Write-Error "[ERROR] Error stopping containers: $($_.Exception.Message)"
    }

    Wait-For-Enter
}

function Show-Logs {
    Write-Header "[LOGS] DocForge Logs"

    Write-Info "Showing logs from all containers..."
    Write-Info "Press Ctrl+C to exit"
    Write-Host ""

    try {
        docker-compose logs -f
    }
    catch {
        Write-Warning "No logs available or containers not running"
        Write-Info "Try: docker-compose logs docforge-api"
        Write-Info "Or: docker-compose logs docforge-frontend"
    }

    Wait-For-Enter
}

function Show-Menu {
    Write-Header "[DOCKER] DocForge Docker Quick Start"

    Write-Host "Choose your deployment mode:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1) [DEV] Quick Start (Development)" -ForegroundColor Green
    Write-Host "   * Fast startup, live reloading" -ForegroundColor Gray
    Write-Host "   * Frontend: http://localhost:5173" -ForegroundColor Gray
    Write-Host "   * API: http://localhost:5000" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2) [PROD] Production Mode" -ForegroundColor Yellow
    Write-Host "   * Optimized build, single port" -ForegroundColor Gray
    Write-Host "   * Everything: http://localhost" -ForegroundColor Gray
    Write-Host "   * Built-in reverse proxy" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3) [LOGS] View Logs"
    Write-Host "4) [STOP] Stop Services"
    Write-Host "5) [EXIT] Exit"
    Write-Host ""

    do {
        $choice = Read-Host "Select option (1-5)"
    } while ($choice -notmatch '^[1-5]$')

    switch ($choice) {
        "1" { Start-DocForge }
        "2" { Start-DocForge -IsProduction }
        "3" { Show-Logs }
        "4" { Stop-DocForge }
        "5" {
            Write-Host "Goodbye!" -ForegroundColor Green
            exit
        }
    }
}

# Main execution
if ($Stop) {
    Stop-DocForge
} elseif ($Logs) {
    Show-Logs
} else {
    # Check Docker availability first
    if (Test-Docker) {
        if ($Simple) {
            Start-DocForge
        } elseif ($Production) {
            Start-DocForge -IsProduction
        } else {
            Show-Menu
        }
    } else {
        Write-Info ""
        Write-Info "Docker setup instructions:" -ForegroundColor Cyan
        Write-Info "1. Download and install Docker Desktop" -ForegroundColor White
        Write-Info "   https://www.docker.com/products/docker-desktop" -ForegroundColor White
        Write-Info ""
        Write-Info "2. Start Docker Desktop" -ForegroundColor White
        Write-Info ""
        Write-Info "3. Run this script again" -ForegroundColor White
        Write-Info ""
        Wait-For-Enter
    }
}