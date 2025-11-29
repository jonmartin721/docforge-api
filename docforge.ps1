# docforge.ps1 - CLI for DocForge API
# Usage: .\docforge.ps1

param(
    [switch]$SkipDependencyCheck,
    [switch]$AutoFixDependencies
)

$API_PORT = 5257
$CLIENT_PORT = 5173
$API_DIR = ".\DocumentGenerator.API"
$CLIENT_DIR = ".\DocumentGenerator.Client"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Global variable to track dependency status
$Global:DependencyStatus = $null

function Check-Port {
    param([int]$port)
    $tcp = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($tcp -and $tcp.State -eq 'Listen') {
        Write-Host "UP" -ForegroundColor Green -NoNewline
    } else {
        Write-Host "DOWN" -ForegroundColor Red -NoNewline
    }
}

function Test-QuickDependency {
    param([string]$Command)

    try {
        $result = Invoke-Expression $Command 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Invoke-ProactiveDependencyCheck {
    if ($SkipDependencyCheck) {
        return $true
    }

    Write-Host "🔍 Checking dependencies..." -ForegroundColor Cyan
    $issues = @()

    # Quick dependency checks
    if (-not (Test-QuickDependency "dotnet --version")) {
        $issues += ".NET 8 SDK not found"
    }

    if (-not (Test-QuickDependency "node --version")) {
        $issues += "Node.js not found"
    }

    if (-not (Test-QuickDependency "npm --version")) {
        $issues += "npm not found"
    }

    if ($issues.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️  Found dependency issues:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "   • $issue" -ForegroundColor Red
        }

        if ($AutoFixDependencies) {
            Write-Host ""
            Write-Host "🔧 Attempting to fix dependencies automatically..." -ForegroundColor Cyan

            $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
            if (Test-Path $dependencyChecker) {
                try {
                    & $dependencyChecker -AutoInstall -Quiet
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Dependencies fixed!" -ForegroundColor Green
                        return $true
                    } else {
                        Write-Host "⚠️  Some dependencies could not be fixed automatically" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "❌ Auto-fix failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ Dependency checker not found" -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "🔧 Options:" -ForegroundColor Cyan
        Write-Host "   1) Run automatic fix (--autofix)" -ForegroundColor White
        Write-Host "   2) Run full dependency check" -ForegroundColor White
        Write-Host "   3) Continue anyway (may fail)" -ForegroundColor White
        Write-Host ""

        do {
            $choice = Read-Host "Select option (1-3, or skip with --skip-dependency-check)"
        } while ($choice -notmatch '^[1-3]$')

        switch ($choice) {
            "1" {
                $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
                if (Test-Path $dependencyChecker) {
                    & $dependencyChecker -AutoInstall
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
                        return $true
                    } else {
                        Write-Host "❌ Some dependencies failed to install" -ForegroundColor Red
                        return $false
                    }
                } else {
                    Write-Host "❌ Dependency checker not found" -ForegroundColor Red
                    return $false
                }
            }
            "2" {
                $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
                if (Test-Path $dependencyChecker) {
                    & $dependencyChecker
                    return $LASTEXITCODE -eq 0
                } else {
                    Write-Host "❌ Dependency checker not found" -ForegroundColor Red
                    return $false
                }
            }
            "3" {
                Write-Host "⚠️  Continuing with potential issues..." -ForegroundColor Yellow
                return $true
            }
        }
    } else {
        Write-Host "✅ All dependencies appear to be installed" -ForegroundColor Green
        return $true
    }
}

function Show-Dependency-Status {
    if ($Global:DependencyStatus) {
        Write-Host "🔍 Dependencies: " -NoNewline
        if ($Global:DependencyStatus) {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "ISSUES" -ForegroundColor Red
        }
    }
}

function Print-Header {
    Clear-Host
    Write-Host "   DOCFORGE" -ForegroundColor Cyan
    Write-Host "==============================================="
    Show-Dependency-Status
    Write-Host " Backend (API):    " -NoNewline
    Check-Port $API_PORT
    Write-Host " (Port $API_PORT)"
    Write-Host " Frontend (Client): " -NoNewline
    Check-Port $CLIENT_PORT
    Write-Host " (Port $CLIENT_PORT)"
    Write-Host "==============================================="
    Write-Host ""
}

function Wait-For-Enter {
    Write-Host ""
    Read-Host "Press Enter to continue..."
}

function Do-Setup {
    Write-Host "🔧 Setup Options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1) 🐳 Docker Setup (Easiest)" -ForegroundColor Green
    Write-Host "2) 🔧 Native Setup (Full development)" -ForegroundColor Yellow
    Write-Host "3) 🔍 Check Dependencies Only" -ForegroundColor Cyan
    Write-Host "4) 📦 Install Dependencies Automatically" -ForegroundColor White
    Write-Host ""

    do {
        $choice = Read-Host "Select setup option (1-4)"
    } while ($choice -notmatch '^[1-4]$')

    switch ($choice) {
        "1" {
            $setupWizard = "$ScriptDir\scripts\setup-wizard.ps1"
            if (Test-Path $setupWizard) {
                & $setupWizard
            } else {
                Write-Host "❌ Setup wizard not found" -ForegroundColor Red
                Write-Host "   Falling back to native setup..." -ForegroundColor Yellow
                Do-Native-Setup
            }
        }
        "2" {
            Do-Native-Setup
        }
        "3" {
            $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
            if (Test-Path $dependencyChecker) {
                & $dependencyChecker
            } else {
                Write-Host "❌ Dependency checker not found" -ForegroundColor Red
            }
        }
        "4" {
            $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
            if (Test-Path $dependencyChecker) {
                & $dependencyChecker -AutoInstall
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
                } else {
                    Write-Host "❌ Some dependencies failed to install" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ Dependency checker not found" -ForegroundColor Red
            }
        }
    }

    Wait-For-Enter
}

function Do-Native-Setup {
    Write-Host "🔧 Setting up native development environment..." -ForegroundColor Yellow

    # Check and install dependencies
    $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
    if (Test-Path $dependencyChecker) {
        Write-Host "📦 Checking and installing dependencies..." -ForegroundColor Cyan
        & $dependencyChecker -AutoInstall

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green

            # Restore .NET packages
            Write-Host "📦 Restoring .NET packages..." -ForegroundColor Cyan
            dotnet restore

            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ .NET packages restored" -ForegroundColor Green
            } else {
                Write-Host "⚠️  .NET package restore had issues" -ForegroundColor Yellow
            }

            # Install npm dependencies
            Write-Host "📦 Installing frontend dependencies..." -ForegroundColor Cyan
            if (Test-Path "$CLIENT_DIR\package.json") {
                Push-Location $CLIENT_DIR
                npm install
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Frontend dependencies installed" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  Frontend dependency installation had issues" -ForegroundColor Yellow
                }
                Pop-Location
            } else {
                Write-Host "⚠️  Frontend package.json not found" -ForegroundColor Yellow
            }

            Write-Host ""
            Write-Host "🎉 Native setup completed!" -ForegroundColor Green
            Write-Host "You can now start the backend and frontend services." -ForegroundColor Cyan
        } else {
            Write-Host "❌ Dependency installation failed" -ForegroundColor Red
            Write-Host "Please check the error messages above and try again." -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Dependency checker not found" -ForegroundColor Red
        Write-Host "Please run the setup wizard instead: .\scripts\setup-wizard.ps1" -ForegroundColor Yellow
    }
}

function Do-Start-Backend-NewWindow {
    # Pre-flight checks
    if (-not (Test-Path $API_DIR)) {
        Write-Host "❌ API directory not found: $API_DIR" -ForegroundColor Red
        Write-Host "   Make sure you're running this from the project root." -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    if (-not (Test-QuickDependency "dotnet --version")) {
        Write-Host "❌ .NET SDK not found. Please run setup first." -ForegroundColor Red
        Write-Host "   Option 1) Setup Dependencies" -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    Write-Host "🚀 Starting Backend in new window..." -ForegroundColor Yellow

    try {
        Start-Process "cmd.exe" -ArgumentList "/c dotnet run --project $API_DIR"
        Write-Host "✓ Backend process started" -ForegroundColor Green

        # Wait for API to be ready (with timeout)
        Write-Host "⏳ Waiting for API to be ready..." -ForegroundColor Gray
        for ($i = 0; $i -lt 30; $i++) {  # Increased timeout to 30 seconds
            Start-Sleep -Seconds 1
            $tcp = Get-NetTCPConnection -LocalPort $API_PORT -ErrorAction SilentlyContinue
            if ($tcp -and $tcp.State -eq 'Listen') {
                Write-Host "✅ API is up and running on port $API_PORT!" -ForegroundColor Green
                Write-Host "   API URL: http://localhost:$API_PORT" -ForegroundColor Cyan
                Write-Host "   Swagger UI: http://localhost:$API_PORT/swagger" -ForegroundColor Cyan
                Wait-For-Enter
                return
            }

            # Show progress
            if ($i % 5 -eq 0) {
                Write-Host "   Still waiting... ($($i + 1)/30 seconds)" -ForegroundColor Gray
            }
        }

        Write-Host "⚠️  WARNING: API may not have started within expected time." -ForegroundColor Yellow
        Write-Host "   Check the new window for errors and consider:" -ForegroundColor Yellow
        Write-Host "   • Running 'dotnet restore' first" -ForegroundColor White
        Write-Host "   • Checking for missing dependencies" -ForegroundColor White
        Write-Host "   • Looking for build errors in the API window" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Failed to start backend: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   • Make sure .NET 8 SDK is installed" -ForegroundColor Yellow
        Write-Host "   • Check that the API project exists and can build" -ForegroundColor Yellow
    }

    Wait-For-Enter
}

function Do-Start-Frontend-NewWindow {
    # Pre-flight checks
    if (-not (Test-Path $CLIENT_DIR)) {
        Write-Host "❌ Client directory not found: $CLIENT_DIR" -ForegroundColor Red
        Write-Host "   Make sure you're running this from the project root." -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    if (-not (Test-Path "$CLIENT_DIR\package.json")) {
        Write-Host "❌ package.json not found in client directory" -ForegroundColor Red
        Write-Host "   Make sure the frontend project is properly set up." -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    if (-not (Test-QuickDependency "node --version")) {
        Write-Host "❌ Node.js not found. Please run setup first." -ForegroundColor Red
        Write-Host "   Option 1) Setup Dependencies" -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    if (-not (Test-QuickDependency "npm --version")) {
        Write-Host "❌ npm not found. Please run setup first." -ForegroundColor Red
        Write-Host "   Option 1) Setup Dependencies" -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    # Check if node_modules exists
    if (-not (Test-Path "$CLIENT_DIR\node_modules")) {
        Write-Host "⚠️  node_modules not found. Running npm install first..." -ForegroundColor Yellow
        Push-Location $CLIENT_DIR
        npm install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Dependencies installed" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
            Pop-Location
            Wait-For-Enter
            return
        }
        Pop-Location
    }

    Write-Host "🚀 Starting Frontend in new window..." -ForegroundColor Yellow

    try {
        Push-Location $CLIENT_DIR
        Start-Process "cmd.exe" -ArgumentList "/c npm run dev"
        Pop-Location
        Write-Host "✓ Frontend process started" -ForegroundColor Green

        # Wait for Vite to be ready (with timeout)
        Write-Host "⏳ Waiting for Vite to be ready..." -ForegroundColor Gray
        for ($i = 0; $i -lt 30; $i++) {  # Increased timeout to 30 seconds
            Start-Sleep -Seconds 1
            $tcp = Get-NetTCPConnection -LocalPort $CLIENT_PORT -ErrorAction SilentlyContinue
            if ($tcp -and $tcp.State -eq 'Listen') {
                Write-Host "✅ Frontend is up and running on port $CLIENT_PORT!" -ForegroundColor Green
                Write-Host "   Frontend URL: http://localhost:$CLIENT_PORT" -ForegroundColor Cyan
                Wait-For-Enter
                return
            }

            # Show progress
            if ($i % 5 -eq 0) {
                Write-Host "   Still waiting... ($($i + 1)/30 seconds)" -ForegroundColor Gray
            }
        }

        Write-Host "⚠️  WARNING: Frontend may not have started within expected time." -ForegroundColor Yellow
        Write-Host "   Check the new window for errors and consider:" -ForegroundColor Yellow
        Write-Host "   • Running 'npm install' first" -ForegroundColor White
        Write-Host "   • Checking for missing Node.js dependencies" -ForegroundColor White
        Write-Host "   • Looking for build errors in the frontend window" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Failed to start frontend: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   • Make sure Node.js and npm are installed" -ForegroundColor Yellow
        Write-Host "   • Check that package.json exists and is valid" -ForegroundColor Yellow
        Write-Host "   • Try running 'npm install' in the client directory" -ForegroundColor Yellow
    }

    Wait-For-Enter
}

function Do-Stop-All {
    Write-Host "Stopping services..." -ForegroundColor Yellow
    
    # Stop API
    $api = Get-NetTCPConnection -LocalPort $API_PORT -ErrorAction SilentlyContinue
    if ($api) { 
        Stop-Process -Id $api.OwningProcess -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped API" -ForegroundColor Green
    } else {
        Write-Host "API not running" -ForegroundColor Gray
    }
    
    # Stop Frontend (Vite/Node)
    $client = Get-NetTCPConnection -LocalPort $CLIENT_PORT -ErrorAction SilentlyContinue
    if ($client) { 
        Stop-Process -Id $client.OwningProcess -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped Frontend" -ForegroundColor Green
    } else {
        Write-Host "Frontend not running" -ForegroundColor Gray
    }
    
    Wait-For-Enter
}

function Do-View-Logs {
    param([string]$LogFile, [string]$Name)
    
    if (-not (Test-Path $LogFile)) {
        Write-Host "Log file $LogFile not found." -ForegroundColor Red
        Wait-For-Enter
        return
    }

    Write-Host "Viewing $Name logs (Press Ctrl+C to exit)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    Get-Content -Path $LogFile -Wait
}

function Do-Open-Browser {
    $tcp = Get-NetTCPConnection -LocalPort $CLIENT_PORT -ErrorAction SilentlyContinue
    if (-not ($tcp -and $tcp.State -eq 'Listen')) {
        Write-Host "Frontend is not running! Please start it first." -ForegroundColor Red
        Wait-For-Enter
        return
    }

    $url = "http://localhost:$CLIENT_PORT"
    Write-Host "Opening $url..." -ForegroundColor Green
    Start-Process $url
    Wait-For-Enter
}

function Do-Test {
    Write-Host "Running Tests..." -ForegroundColor Yellow
    dotnet test
    Wait-For-Enter
}

function Do-Clear-Data {
    Write-Host "WARNING: This will delete all data (Database & Generated Files)!" -ForegroundColor Red
    $confirm = Read-Host "Are you sure? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled."
        Wait-For-Enter
        return
    }

    Do-Stop-All
    
    Write-Host "Deleting database..."
    if (Test-Path "$API_DIR\documentgenerator.db") {
        Remove-Item "$API_DIR\documentgenerator.db" -Force
    }
    
    Write-Host "Deleting generated documents..."
    if (Test-Path "$API_DIR\GeneratedDocuments") {
        Get-ChildItem "$API_DIR\GeneratedDocuments" | Remove-Item -Recurse -Force
    }
    
    Write-Host "Data cleared!" -ForegroundColor Green
    Wait-For-Enter
}

# Run proactive dependency check on startup
$Global:DependencyStatus = Invoke-ProactiveDependencyCheck

# Main Loop
while ($true) {
    Print-Header
    Write-Host "Core Actions:" -ForegroundColor White
    Write-Host "  1) 🔧 Setup Dependencies"
    Write-Host "  2) 🚀 Start Backend"
    Write-Host "  3) 🌐 Start Frontend"
    Write-Host "  4) ⚡ Start Both Services"
    Write-Host "  5) 🛑 Stop All Services"
    Write-Host ""
    Write-Host "Tools:" -ForegroundColor White
    Write-Host "  6) 📄 View Backend Logs"
    Write-Host "  7) 📑 View Frontend Logs"
    Write-Host "  8) 🌍 Open App in Browser"
    Write-Host "  9) 🧪 Run Tests"
    Write-Host ""
    Write-Host "  r) 🔄 Refresh Status"
    Write-Host "  c) 🗑️  Clear All Data"
    Write-Host "  d) 🔍 Dependencies Status"
    Write-Host "  q) 👋 Quit"
    Write-Host ""
    $option = Read-Host "Select an option"

    switch ($option) {
        "1" {
            Do-Setup
            # Re-check dependencies after setup
            $Global:DependencyStatus = Invoke-ProactiveDependencyCheck
        }
        "2" { Do-Start-Backend-NewWindow }
        "3" { Do-Start-Frontend-NewWindow }
        "4" {
            Do-Start-Backend-NewWindow
            Do-Start-Frontend-NewWindow
        }
        "5" { Do-Stop-All }
        "6" { Do-View-Logs "api.log" "Backend" }
        "7" { Do-View-Logs "client.log" "Frontend" }
        "8" { Do-Open-Browser }
        "9" { Do-Test }
        "r" { } # Just loop to refresh
        "c" { Do-Clear-Data }
        "d" {
            $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
            if (Test-Path $dependencyChecker) {
                & $dependencyChecker
                $Global:DependencyStatus = ($LASTEXITCODE -eq 0)
            } else {
                Write-Host "❌ Dependency checker not found" -ForegroundColor Red
                Wait-For-Enter
            }
        }
        "q" {
            Write-Host "👋 Goodbye!" -ForegroundColor Green
            exit
        }
        Default {
            Write-Host "❌ Invalid option. Please select 1-9, r, c, d, or q." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
