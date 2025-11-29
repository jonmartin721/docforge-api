# DocForge Setup Wizard for Windows
# Interactive setup wizard with Docker and native setup options

param(
    [switch]$SkipDocker,
    [switch]$ForceNative
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

# System detection functions
function Test-DockerAvailability {
    Write-Info "Checking Docker availability..."

    # Check if Docker is installed
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        try {
            # Check if Docker daemon is running
            $dockerInfo = docker info 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✓ Docker is available and running"
                return $true
            } else {
                Write-Warning "⚠ Docker is installed but not running"
                Write-Info "  Please start Docker Desktop and try again"
                return $false
            }
        }
        catch {
            Write-Warning "⚠ Docker is installed but may not be properly configured"
            return $false
        }
    } else {
        Write-Warning "⚠ Docker is not installed"
        return $false
    }
}

function Show-Welcome {
    Write-Header "🚀 Welcome to DocForge!"
    Write-Host "DocForge is a powerful document generation system that combines:"
    Write-Host ""
    Write-Host "• .NET 8 Web API backend"
    Write-Host "• React frontend with Vite"
    Write-Host "• PDF generation using headless Chrome"
    Write-Host "• Template-based document creation"
    Write-Host ""
    Write-Host "This wizard will help you get DocForge running on your system."
    Write-Host ""
    Wait-For-Enter
}

function Show-Setup-Options {
    Write-Header "Choose Your Setup Method"
    Write-Host "How would you like to run DocForge?"
    Write-Host ""

    # Check Docker availability first
    $dockerAvailable = if (-not $SkipDocker) { Test-DockerAvailability } else { $false }

    if ($dockerAvailable -and -not $ForceNative) {
        Write-Host "1) 🐳 Docker Setup (Recommended - 5 minutes)" -ForegroundColor Green
        Write-Host "   ✓ No dependencies required" -ForegroundColor Gray
        Write-Host "   ✓ Works immediately" -ForegroundColor Gray
        Write-Host "   ✓ Isolated environment" -ForegroundColor Gray
        Write-Host ""

        Write-Host "2) 🔧 Native Setup (15 minutes)" -ForegroundColor Yellow
        Write-Host "   ✓ Full development environment" -ForegroundColor Gray
        Write-Host "   ✓ Direct code access" -ForegroundColor Gray
        Write-Host "   ✓ Customizable configuration" -ForegroundColor Gray
        Write-Host ""

        Write-Host "3) 📋 Compare Options" -ForegroundColor Cyan
        Write-Host ""

        do {
            $choice = Read-Host "Select option (1-3)"
        } while ($choice -notmatch '^[1-3]$')

        return $choice
    } else {
        Write-Warning "Docker is not available or was skipped"
        Write-Host ""
        Write-Host "🔧 Setting up native development environment..."
        Write-Host ""
        Write-Host "This will install the following:"
        Write-Host "• .NET 8 SDK"
        Write-Host "• Node.js 18+"
        Write-Host "• Git"
        Write-Host "• (Optional) Visual Studio Code"
        Write-Host ""

        $choice = Read-Host "Continue with native setup? (Y/n)"
        if ($choice -eq "n" -or $choice -eq "N") {
            Write-Info "Setup cancelled. Please install Docker Desktop first and try again."
            exit 0
        }

        return "2"  # Native setup
    }
}

function Show-Comparison {
    Write-Header "Setup Method Comparison"
    Write-Host ""

    Write-Host "🐳 Docker Setup:" -ForegroundColor Green
    Write-Host "  PROS:" -ForegroundColor Gray
    Write-Host "  • No local dependencies to install" -ForegroundColor Gray
    Write-Host "  • Consistent environment across machines" -ForegroundColor Gray
    Write-Host "  • Easy to start fresh (docker-compose down/up)" -ForegroundColor Gray
    Write-Host "  • No conflicts with existing software" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  CONS:" -ForegroundColor Gray
    Write-Host "  • Requires Docker Desktop installation" -ForegroundColor Gray
    Write-Host "  • Slower initial startup" -ForegroundColor Gray
    Write-Host "  • Uses more disk space" -ForegroundColor Gray
    Write-Host "  • More complex for debugging" -ForegroundColor Gray
    Write-Host ""

    Write-Host "🔧 Native Setup:" -ForegroundColor Yellow
    Write-Host "  PROS:" -ForegroundColor Gray
    Write-Host "  • Full development environment" -ForegroundColor Gray
    Write-Host "  • Direct access to code and tools" -ForegroundColor Gray
    Write-Host "  • Faster startup and compilation" -ForegroundColor Gray
    Write-Host "  • Easier debugging and customization" -ForegroundColor Gray
    Write-Host "  • Less disk space usage" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  CONS:" -ForegroundColor Gray
    Write-Host "  • Requires installing multiple dependencies" -ForegroundColor Gray
    Write-Host "  • May conflict with existing software versions" -ForegroundColor Gray
    Write-Host "  • Platform-specific setup required" -ForegroundColor Gray
    Write-Host ""

    Wait-For-Enter "Press Enter to return to options..."
    return "show-options"
}

function Start-DockerSetup {
    Write-Header "🐳 Docker Setup"
    Write-Host "Setting up DocForge with Docker containers..."
    Write-Host ""

    # Check if we're in the right directory
    if (-not (Test-Path "docker-compose.yml")) {
        Write-Error "docker-compose.yml not found. Please run this script from the project root."
        Wait-For-Enter()
        return
    }

    Write-Info "Building Docker images..."
    docker-compose build

    if ($LASTEXITCODE -eq 0) {
        Write-Success "✓ Docker images built successfully"
    } else {
        Write-Error "✗ Docker build failed"
        Write-Warning "Please check the error messages above and try again."
        Wait-For-Enter()
        return
    }

    Write-Info "Starting containers..."
    docker-compose up -d

    if ($LASTEXITCODE -eq 0) {
        Write-Success "✓ DocForge is now running!"
        Write-Host ""
        Write-Host "🌐 Application URLs:" -ForegroundColor Cyan
        Write-Host "   API: http://localhost:5000" -ForegroundColor White
        Write-Host "   API Documentation: http://localhost:5000/swagger" -ForegroundColor White
        Write-Host ""
        Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
        Write-Host "   View logs: docker-compose logs -f" -ForegroundColor Gray
        Write-Host "   Stop application: docker-compose down" -ForegroundColor Gray
        Write-Host "   Restart application: docker-compose restart" -ForegroundColor Gray
        Write-Host ""

        Wait-For-Enter("Press Enter to open the application in your browser...")
        Start-Process "http://localhost:5000"
    } else {
        Write-Error "✗ Failed to start containers"
        Write-Warning "Please check the error messages above."
    }
}

function Start-NativeSetup {
    Write-Header "🔧 Native Setup"
    Write-Host "Setting up native development environment..."
    Write-Host ""

    # Check if dependency checker script exists
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $DependencyChecker = "$ScriptDir\check-dependencies.ps1"

    if (-not (Test-Path $DependencyChecker)) {
        Write-Error "Dependency checker script not found: $DependencyChecker"
        Wait-For-Enter()
        return
    }

    Write-Info "Checking and installing dependencies..."
    Write-Host ""

    # Run dependency checker with auto-install
    try {
        & $DependencyChecker -AutoInstall

        if ($LASTEXITCODE -eq 0) {
            Write-Success "✓ All dependencies installed successfully!"
        } else {
            Write-Warning "⚠ Some dependencies may not have installed correctly"
            Write-Info "You can try running the dependency checker manually:"
            Write-Host "   .\scripts\check-dependencies.ps1 -AutoInstall"
        }
    }
    catch {
        Write-Error "✗ Dependency installation failed: $($_.Exception.Message)"
        Write-Warning "Please install dependencies manually and try again."
        Wait-For-Enter()
        return
    }

    Write-Host ""
    Write-Info "Setting up project dependencies..."

    # Restore .NET dependencies
    Write-Info "Restoring .NET packages..."
    dotnet restore

    if ($LASTEXITCODE -eq 0) {
        Write-Success "✓ .NET packages restored"
    } else {
        Write-Warning "⚠ .NET package restore had issues"
    }

    # Install npm dependencies
    Write-Info "Installing frontend dependencies..."
    Push-Location "DocumentGenerator.Client"

    if (Test-Path "package.json") {
        npm install

        if ($LASTEXITCODE -eq 0) {
            Write-Success "✓ Frontend dependencies installed"
        } else {
            Write-Warning "⚠ Frontend dependency installation had issues"
        }
    } else {
        Write-Warning "⚠ Frontend package.json not found"
    }

    Pop-Location

    Write-Host ""
    Write-Success "✓ Native setup completed!"
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Run: .\docforge.ps1" -ForegroundColor White
    Write-Host "   2. Select option 2 to start the backend" -ForegroundColor White
    Write-Host "   3. Select option 3 to start the frontend" -ForegroundColor White
    Write-Host "   4. Select option 8 to open in your browser" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Or use option 4 to start both services at once!" -ForegroundColor Yellow
    Write-Host ""

    Wait-For-Enter("Press Enter to start the DocForge CLI...")

    # Start the DocForge CLI
    $DocForgeCLI = "$ScriptDir\..\docforge.ps1"
    if (Test-Path $DocForgeCLI) {
        & $DocForgeCLI
    } else {
        Write-Warning "DocForge CLI not found. Please run: .\docforge.ps1"
    }
}

# Main execution
function Main {
    try {
        Show-Welcome

        do {
            $choice = Show-Setup-Options

            switch ($choice) {
                "1" {
                    Start-DockerSetup
                    break
                }
                "2" {
                    Start-NativeSetup
                    break
                }
                "3" {
                    $choice = Show-Comparison
                    if ($choice -eq "show-options") {
                        continue
                    }
                }
            }
        } while ($true)
    }
    catch {
        Write-Error "Setup wizard encountered an error: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "If this error persists, please:"
        Write-Host "1. Check the error message above"
        Write-Host "2. Ensure you have sufficient disk space"
        Write-Host "3. Try running as Administrator if permission errors occur"
        Write-Host "4. Visit https://github.com/your-repo/docforge for troubleshooting"
        Write-Host ""
        Wait-For-Enter()
    }
}

# Run the wizard
Main