# docforge.ps1 - CLI for DocForge API
# Usage: .\docforge.ps1 [options]

param(
    [switch]$SkipDependencyCheck,
    [switch]$AutoFix,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\docforge.ps1 [options]"
    Write-Host "Options:"
    Write-Host "  -SkipDependencyCheck    Skip dependency checks"
    Write-Host "  -AutoFix                Auto-fix dependency issues"
    Write-Host "  -Help                   Show this help"
    exit
}

$ErrorActionPreference = "Continue"

# Configuration
$API_PORT = 5257
$CLIENT_PORT = 5173
$API_DIR = ".\DocumentGenerator.API"
$CLIENT_DIR = ".\DocumentGenerator.Client"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Global variables
$Global:DependencyStatus = 0 # 0 = OK, 1 = Issues

# Helper Functions
function Check-Port {
    param([int]$port)
    $portOpen = $false
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' }
        if ($conn) {
            $portOpen = $true
        }
    } catch {}

    if ($portOpen) {
        Write-Host "UP" -ForegroundColor Green -NoNewline
    } else {
        Write-Host "DOWN" -ForegroundColor Red -NoNewline
    }
}

function Test-QuickDependency {
    param([string]$CommandStr)
    # $CommandStr e.g. "dotnet --version"
    try {
        # Split command to get executable
        $parts = $CommandStr -split " ", 2
        $cmd = $parts[0]
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
             # Try running it
             $null = Invoke-Expression "$CommandStr 2>&1"
             return ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0)
        }
        return $false
    }
    catch {
        return $false
    }
}

function Show-Dependency-Status {
    if ($Global:DependencyStatus -eq 0) {
        Write-Host "[CHECK] Dependencies: " -NoNewline
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "[CHECK] Dependencies: " -NoNewline
        Write-Host "ISSUES" -ForegroundColor Red
    }
}

function Invoke-ProactiveDependencyCheck {
    if ($SkipDependencyCheck) {
        return
    }

    Write-Host "[CHECK] Checking dependencies..." -ForegroundColor Cyan
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
        Write-Host "[WARN] Found dependency issues:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "   * $issue" -ForegroundColor Red
        }

        if ($AutoFix) {
            Write-Host ""
            Write-Host "[SETUP] Attempting to fix dependencies automatically..." -ForegroundColor Cyan

            $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
            if (Test-Path $dependencyChecker) {
                & $dependencyChecker -AutoInstall -Quiet
                if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Dependencies fixed!" -ForegroundColor Green
                    $Global:DependencyStatus = 0
                    return
                } else {
                    Write-Host "[WARN] Some dependencies could not be fixed automatically" -ForegroundColor Yellow
                }
            } else {
                Write-Host "[ERROR] Dependency checker not found" -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "[SETUP] Options:" -ForegroundColor Cyan
        Write-Host "   1) Run automatic fix (.\docforge.ps1 -AutoFix)"
        Write-Host "   2) Run full dependency check"
        Write-Host "   3) Continue anyway (may fail)"
        Write-Host ""

        do {
            $choice = Read-Host "Select option (1-3, or skip with -SkipDependencyCheck)"
        } while ($choice -notmatch '^[1-3]$')

        switch ($choice) {
            "1" {
                $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
                if (Test-Path $dependencyChecker) {
                    & $dependencyChecker -AutoInstall
                    if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
                        Write-Host "[OK] Dependencies installed successfully!" -ForegroundColor Green
                        $Global:DependencyStatus = 0
                        return
                    } else {
                        Write-Host "[ERROR] Some dependencies failed to install" -ForegroundColor Red
                        $Global:DependencyStatus = 1
                        return
                    }
                } else {
                    Write-Host "[ERROR] Dependency checker not found" -ForegroundColor Red
                    $Global:DependencyStatus = 1
                    return
                }
            }
            "2" {
                $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
                if (Test-Path $dependencyChecker) {
                    & $dependencyChecker
                    if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) { $Global:DependencyStatus = 0 } else { $Global:DependencyStatus = 1 }
                    return
                } else {
                    Write-Host "[ERROR] Dependency checker not found" -ForegroundColor Red
                    $Global:DependencyStatus = 1
                    return
                }
            }
            "3" {
                Write-Host "[WARN] Continuing with potential issues..." -ForegroundColor Yellow
                $Global:DependencyStatus = 1
                return
            }
        }
    } else {
        Write-Host "[OK] All dependencies appear to be installed" -ForegroundColor Green
        $Global:DependencyStatus = 0
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

# Actions
function Do-Setup {
    Write-Host "[SETUP] Options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1) [DOCKER] Docker Setup (Recommended for Windows)" -ForegroundColor Green
    Write-Host "2) [LINKS] Open Manual Download Pages" -ForegroundColor Yellow
    Write-Host "3) [AUTO] Auto-Install Dependencies (uses winget)" -ForegroundColor White
    Write-Host "4) [CHECK] Check Dependencies Status" -ForegroundColor Cyan
    Write-Host "5) [NATIVE] Full Native Setup Wizard" -ForegroundColor Gray
    Write-Host ""

    do {
        $choice = Read-Host "Select setup option (1-5)"
    } while ($choice -notmatch '^[1-5]$')

    switch ($choice) {
        "1" {
            $dockerScript = "$ScriptDir\scripts\docker-quick-start.ps1"
            if (Test-Path $dockerScript) {
                & $dockerScript
            } else {
                Write-Host "[ERROR] Docker quick start not found" -ForegroundColor Red
                Write-Host ""
                Write-Host "Download Docker Desktop manually:" -ForegroundColor Yellow
                Write-Host "  https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
            }
        }
        "2" {
            Write-Host ""
            Write-Host "[LINKS] Opening download pages..." -ForegroundColor Cyan
            Write-Host ""

            Write-Host "Opening Docker Desktop (recommended)..." -ForegroundColor Green
            Start-Process "https://www.docker.com/products/docker-desktop"
            Start-Sleep -Milliseconds 500

            Write-Host "Opening .NET 8 SDK..." -ForegroundColor White
            Start-Process "https://dotnet.microsoft.com/download/dotnet/8.0"
            Start-Sleep -Milliseconds 500

            Write-Host "Opening Node.js..." -ForegroundColor White
            Start-Process "https://nodejs.org/en/download/"
            Start-Sleep -Milliseconds 500

            Write-Host "Opening Git for Windows..." -ForegroundColor White
            Start-Process "https://git-scm.com/download/win"

            Write-Host ""
            Write-Host "Download Links:" -ForegroundColor Yellow
            Write-Host "  Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
            Write-Host "  .NET 8 SDK:     https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor Cyan
            Write-Host "  Node.js:        https://nodejs.org/en/download/" -ForegroundColor Cyan
            Write-Host "  Git:            https://git-scm.com/download/win" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "[IMPORTANT] After installing, close and reopen your terminal!" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Verify with:" -ForegroundColor Gray
            Write-Host "  dotnet --version" -ForegroundColor Gray
            Write-Host "  node --version" -ForegroundColor Gray
            Write-Host "  npm --version" -ForegroundColor Gray
            Write-Host "  git --version" -ForegroundColor Gray
        }
        "3" {
            $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
            if (Test-Path $dependencyChecker) {
                & $dependencyChecker -AutoInstall
                if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Dependencies installed successfully!" -ForegroundColor Green
                } else {
                    Write-Host "[ERROR] Some dependencies failed to install" -ForegroundColor Red
                    Write-Host ""
                    Write-Host "Try option 2 to download manually, or use Docker (option 1)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "[ERROR] Dependency checker not found" -ForegroundColor Red
            }
        }
        "4" {
            $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
            if (Test-Path $dependencyChecker) {
                & $dependencyChecker
            } else {
                Write-Host "[ERROR] Dependency checker not found" -ForegroundColor Red
            }
        }
        "5" {
            $setupWizard = "$ScriptDir\scripts\setup-wizard.ps1"
            if (Test-Path $setupWizard) {
                & $setupWizard
            } else {
                Write-Host "[ERROR] Setup wizard not found" -ForegroundColor Red
                Do-Native-Setup
            }
        }
    }

    Wait-For-Enter
}

function Do-Native-Setup {
    Write-Host "[SETUP] Setting up native development environment..." -ForegroundColor Yellow

    # Check and install dependencies
    $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
    if (Test-Path $dependencyChecker) {
        Write-Host "[PKG] Checking and installing dependencies..." -ForegroundColor Cyan
        & $dependencyChecker -AutoInstall

        if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
            Write-Host "[OK] Dependencies installed successfully!" -ForegroundColor Green

            # Restore .NET packages
            Write-Host "[PKG] Restoring .NET packages..." -ForegroundColor Cyan
            dotnet restore

            if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
                Write-Host "[OK] .NET packages restored" -ForegroundColor Green
            } else {
                Write-Host "[WARN] .NET package restore had issues" -ForegroundColor Yellow
            }

            # Install npm dependencies
            Write-Host "[PKG] Installing frontend dependencies..." -ForegroundColor Cyan
            if (Test-Path "$CLIENT_DIR\package.json") {
                Push-Location $CLIENT_DIR
                npm install
                if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Frontend dependencies installed" -ForegroundColor Green
                } else {
                    Write-Host "[WARN] Frontend dependency installation had issues" -ForegroundColor Yellow
                }
                Pop-Location
            } else {
                Write-Host "[WARN] Frontend package.json not found" -ForegroundColor Yellow
            }

            Write-Host ""
            Write-Host "[OK] Native setup completed!" -ForegroundColor Green
            Write-Host "You can now start the backend and frontend services." -ForegroundColor Cyan
        } else {
            Write-Host "[ERROR] Dependency installation failed" -ForegroundColor Red
            Write-Host "Please check the error messages above and try again." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[ERROR] Dependency checker not found" -ForegroundColor Red
        Write-Host "Please run the setup wizard instead: .\scripts\setup-wizard.ps1" -ForegroundColor Yellow
    }
}

function Do-Start-Backend {
    # Pre-flight checks
    if (-not (Test-Path $API_DIR)) {
        Write-Host "[ERROR] API directory not found: $API_DIR" -ForegroundColor Red
        Write-Host "   Make sure you're running this from the project root." -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    if (-not (Test-QuickDependency "dotnet --version")) {
        Write-Host "[ERROR] .NET SDK not found. Please run setup first." -ForegroundColor Red
        Write-Host "   Option 1) Setup Dependencies" -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    Write-Host "[START] Starting Backend..." -ForegroundColor Yellow

    try {
        $process = Start-Process -FilePath "dotnet" -ArgumentList "run --project $API_DIR" -RedirectStandardOutput "api.log" -RedirectStandardError "api.log" -PassThru -NoNewWindow
        
        Write-Host "[OK] Backend process started (PID: $($process.Id))" -ForegroundColor Green

        # Wait for API to be ready (with timeout)
        Write-Host "[WAIT] Waiting for API to be ready..." -ForegroundColor Cyan
        for ($i = 0; $i -lt 30; $i++) {
            if (Get-NetTCPConnection -LocalPort $API_PORT -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' }) {
                Write-Host "[OK] API is up and running on port $API_PORT!" -ForegroundColor Green
                Write-Host "   API URL: http://localhost:$API_PORT" -ForegroundColor Cyan
                Write-Host "   Swagger UI: http://localhost:$API_PORT/swagger" -ForegroundColor Cyan
                Wait-For-Enter
                return
            }

            # Show progress
            if ($i % 5 -eq 0) {
                Write-Host "   Still waiting... ($($i + 1)/30 seconds)" -ForegroundColor Cyan
            }
            Start-Sleep -Seconds 1
        }

        Write-Host "[WARN] WARNING: API may not have started within expected time." -ForegroundColor Yellow
        Write-Host "   Check api.log for errors and consider:" -ForegroundColor Yellow
        Write-Host "   • Running 'dotnet restore' first"
        Write-Host "   • Checking for missing dependencies"
        Write-Host "   • Looking for build errors"
    }
    catch {
        Write-Host "[ERROR] Failed to start backend process: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   • Make sure .NET 8 SDK is installed" -ForegroundColor Yellow
        Write-Host "   • Check that the API project exists and can build" -ForegroundColor Yellow
    }

    Wait-For-Enter
}

function Do-Start-Frontend {
    # Pre-flight checks
    if (-not (Test-Path $CLIENT_DIR)) {
        Write-Host "[ERROR] Client directory not found: $CLIENT_DIR" -ForegroundColor Red
        Write-Host "   Make sure you're running this from the project root." -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    if (-not (Test-Path "$CLIENT_DIR\package.json")) {
        Write-Host "[ERROR] package.json not found in client directory" -ForegroundColor Red
        Write-Host "   Make sure the frontend project is properly set up." -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    if (-not (Test-QuickDependency "node --version")) {
        Write-Host "[ERROR] Node.js not found. Please run setup first." -ForegroundColor Red
        Write-Host "   Option 1) Setup Dependencies" -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    if (-not (Test-QuickDependency "npm --version")) {
        Write-Host "[ERROR] npm not found. Please run setup first." -ForegroundColor Red
        Write-Host "   Option 1) Setup Dependencies" -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    # Check if node_modules exists
    if (-not (Test-Path "$CLIENT_DIR\node_modules")) {
        Write-Host "[WARN] node_modules not found. Running npm install first..." -ForegroundColor Yellow
        Push-Location $CLIENT_DIR
        npm install
        if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
            Write-Host "[OK] Dependencies installed" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
            Pop-Location
            Wait-For-Enter
            return
        }
        Pop-Location
    }

    Write-Host "[START] Starting Frontend..." -ForegroundColor Yellow

    try {
        # Start npm run dev
        # PS5.1 doesn't have $IsWindows, but PS5.1 only runs on Windows anyway
        $npmCmd = "npm"
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            # Windows PowerShell 5.1 - always on Windows
            $npmCmd = "npm.cmd"
        } elseif ($IsWindows) {
            # PowerShell Core on Windows
            $npmCmd = "npm.cmd"
        }

        $process = Start-Process -FilePath $npmCmd -ArgumentList "run dev" -WorkingDirectory $CLIENT_DIR -RedirectStandardOutput "..\client.log" -RedirectStandardError "..\client.log" -PassThru -NoNewWindow
        
        Write-Host "[OK] Frontend process started (PID: $($process.Id))" -ForegroundColor Green

        # Wait for Vite to be ready (with timeout)
        Write-Host "[WAIT] Waiting for Vite to be ready..." -ForegroundColor Cyan
        for ($i = 0; $i -lt 30; $i++) {
            if (Get-NetTCPConnection -LocalPort $CLIENT_PORT -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' }) {
                Write-Host "[OK] Frontend is up and running on port $CLIENT_PORT!" -ForegroundColor Green
                Write-Host "   Frontend URL: http://localhost:$CLIENT_PORT" -ForegroundColor Cyan
                Wait-For-Enter
                return
            }

            # Show progress
            if ($i % 5 -eq 0) {
                Write-Host "   Still waiting... ($($i + 1)/30 seconds)" -ForegroundColor Cyan
            }
            Start-Sleep -Seconds 1
        }

        Write-Host "[WARN] WARNING: Frontend may not have started within expected time." -ForegroundColor Yellow
        Write-Host "   Check client.log for errors and consider:" -ForegroundColor Yellow
        Write-Host "   • Running 'npm install' first"
        Write-Host "   • Checking for missing Node.js dependencies"
        Write-Host "   • Looking for build errors"
    }
    catch {
        Write-Host "[ERROR] Failed to start frontend process: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   • Make sure Node.js and npm are installed" -ForegroundColor Yellow
        Write-Host "   • Check that package.json exists and is valid" -ForegroundColor Yellow
        Write-Host "   • Try running 'npm install' in the client directory" -ForegroundColor Yellow
    }

    Wait-For-Enter
}

function Do-Stop-All {
    Write-Host "Stopping all services..." -ForegroundColor Yellow
    
    # Kill by port is safer
    $ports = @($API_PORT, $CLIENT_PORT)
    foreach ($port in $ports) {
        $conns = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' }
        if ($conns) {
            foreach ($conn in $conns) {
                try {
                    Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
                    Write-Host "Stopped process on port $port (PID: $($conn.OwningProcess))" -ForegroundColor Green
                }
                catch {
                    Write-Host "Failed to stop process on port $port" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host "Stopped." -ForegroundColor Green
    Start-Sleep -Seconds 1
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
    if (-not (Get-NetTCPConnection -LocalPort $CLIENT_PORT -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' })) {
        Write-Host "Frontend is not running! Please start it first." -ForegroundColor Red
        Wait-For-Enter
        return
    }

    $url = "http://localhost:$CLIENT_PORT"
    Write-Host "Opening $url..." -ForegroundColor Green
    
    try {
        Start-Process $url
    } catch {
        Write-Host "Could not open browser automatically. Please go to $url" -ForegroundColor Yellow
    }
    Wait-For-Enter
}

function Do-Test {
    Write-Host "Running Tests..." -ForegroundColor Yellow
    dotnet test
    Wait-For-Enter
}

function Do-API-Playground {
    # Check if API is running
    $apiRunning = $false
    try {
        $conn = Get-NetTCPConnection -LocalPort $API_PORT -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' }
        if ($conn) { $apiRunning = $true }
    } catch {}

    if (-not $apiRunning) {
        Write-Host "[WARN] API is not running! Start it first for full functionality." -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host "[API] API Playground" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "API Base URL: http://localhost:$API_PORT" -ForegroundColor White
    Write-Host ""
    Write-Host "Quick Actions:" -ForegroundColor White
    Write-Host "  1) [HEALTH] Health Check" -ForegroundColor Green
    Write-Host "  2) [SWAGGER] Open Swagger UI (API Docs)" -ForegroundColor Cyan
    Write-Host "  3) [GET] List Templates" -ForegroundColor Yellow
    Write-Host "  4) [GET] List Documents" -ForegroundColor Yellow
    Write-Host "  5) [TEST] Test Custom Endpoint" -ForegroundColor White
    Write-Host "  6) [INFO] Show API Endpoints" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  b) Back to Main Menu" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option"

    switch ($choice) {
        "1" {
            Do-API-HealthCheck
        }
        "2" {
            Do-API-OpenSwagger
        }
        "3" {
            Do-API-Request "GET" "/api/templates" "List Templates"
        }
        "4" {
            Do-API-Request "GET" "/api/documents" "List Documents"
        }
        "5" {
            Do-API-CustomEndpoint
        }
        "6" {
            Do-API-ShowEndpoints
        }
        "b" {
            return
        }
        default {
            Write-Host "[ERROR] Invalid option" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }

    # Loop back to playground menu unless going back
    if ($choice -ne "b") {
        Do-API-Playground
    }
}

function Do-API-HealthCheck {
    Write-Host ""
    Write-Host "[HEALTH] Checking API Health..." -ForegroundColor Cyan
    Write-Host ""

    $baseUrl = "http://localhost:$API_PORT"
    $endpoints = @(
        @{ Path = "/health"; Name = "Health Endpoint" },
        @{ Path = "/api/templates"; Name = "Templates API" },
        @{ Path = "/swagger"; Name = "Swagger UI" }
    )

    foreach ($endpoint in $endpoints) {
        $url = "$baseUrl$($endpoint.Path)"
        Write-Host "  Testing $($endpoint.Name)... " -NoNewline

        try {
            $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            $statusCode = $response.StatusCode

            if ($statusCode -ge 200 -and $statusCode -lt 300) {
                Write-Host "OK ($statusCode)" -ForegroundColor Green
            } else {
                Write-Host "WARN ($statusCode)" -ForegroundColor Yellow
            }
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode) {
                Write-Host "ERROR ($statusCode)" -ForegroundColor Red
            } else {
                Write-Host "UNREACHABLE" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Wait-For-Enter
}

function Do-API-OpenSwagger {
    $url = "http://localhost:$API_PORT/swagger"
    Write-Host ""
    Write-Host "[SWAGGER] Opening Swagger UI..." -ForegroundColor Cyan
    Write-Host "   URL: $url" -ForegroundColor White

    try {
        Start-Process $url
        Write-Host "[OK] Browser opened" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Could not open browser automatically" -ForegroundColor Yellow
        Write-Host "   Please open $url manually" -ForegroundColor Gray
    }

    Wait-For-Enter
}

function Get-HttpStatusMessage {
    param([int]$Code)
    switch ($Code) {
        401 { return "Unauthorized - Login required (use Swagger UI to authenticate)" }
        403 { return "Forbidden - You don't have permission for this resource" }
        404 { return "Not Found - Check the endpoint path" }
        429 { return "Too Many Requests - Rate limit exceeded, wait and retry" }
        { $_ -ge 500 } { return "Server Error - Check API logs (option 8)" }
        default { return $null }
    }
}

function Do-API-Request {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$Description
    )

    $url = "http://localhost:$API_PORT$Endpoint"
    Write-Host ""
    Write-Host "[$Method] $Description" -ForegroundColor Cyan
    Write-Host "   URL: $url" -ForegroundColor Gray
    Write-Host ""

    # Pre-check: is API running?
    $apiRunning = $false
    try {
        $conn = Get-NetTCPConnection -LocalPort $API_PORT -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' }
        if ($conn) { $apiRunning = $true }
    } catch {}

    if (-not $apiRunning) {
        Write-Host "[ERROR] API is not running on port $API_PORT" -ForegroundColor Red
        Write-Host "   Start the backend first (option 1)" -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    try {
        $response = Invoke-WebRequest -Uri $url -Method $Method -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop
        $statusCode = $response.StatusCode

        Write-Host "[RESPONSE] Status: $statusCode" -ForegroundColor Green
        Write-Host ""

        # Try to format JSON response
        try {
            $json = $response.Content | ConvertFrom-Json
            $formatted = $json | ConvertTo-Json -Depth 5
            $totalLen = $formatted.Length

            if ($totalLen -gt 2000) {
                $formatted = $formatted.Substring(0, 2000) + "`n... (truncated - showing 2000 of $totalLen characters)"
            }

            Write-Host $formatted -ForegroundColor White
        }
        catch {
            # Not JSON, show raw content
            $content = $response.Content
            $totalLen = $content.Length
            if ($totalLen -gt 2000) {
                $content = $content.Substring(0, 2000) + "`n... (truncated - showing 2000 of $totalLen characters)"
            }
            Write-Host $content -ForegroundColor White
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "[ERROR] Status: $statusCode" -ForegroundColor Red
            $statusMsg = Get-HttpStatusMessage -Code $statusCode
            if ($statusMsg) {
                Write-Host "   $statusMsg" -ForegroundColor Yellow
            }
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $errorContent = $reader.ReadToEnd()
                $reader.Dispose()
                Write-Host $errorContent -ForegroundColor Red
            } catch {}
        } else {
            Write-Host "[ERROR] Request failed" -ForegroundColor Red
            Write-Host "   Connection timed out or was refused" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Wait-For-Enter
}

function Do-API-CustomEndpoint {
    Write-Host ""
    Write-Host "[TEST] Custom Endpoint Test" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Base URL: http://localhost:$API_PORT" -ForegroundColor Gray
    Write-Host ""

    # Pre-check: is API running?
    $apiRunning = $false
    try {
        $conn = Get-NetTCPConnection -LocalPort $API_PORT -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' }
        if ($conn) { $apiRunning = $true }
    } catch {}

    if (-not $apiRunning) {
        Write-Host "[ERROR] API is not running on port $API_PORT" -ForegroundColor Red
        Write-Host "   Start the backend first (option 1)" -ForegroundColor Yellow
        Wait-For-Enter
        return
    }

    # Method selection
    Write-Host "HTTP Method:" -ForegroundColor White
    Write-Host "  1) GET"
    Write-Host "  2) POST"
    Write-Host "  3) PUT"
    Write-Host "  4) DELETE"
    Write-Host ""

    do {
        $methodChoice = Read-Host "Select method (1-4)"
    } while ($methodChoice -notmatch '^[1-4]$')

    $method = switch ($methodChoice) {
        "1" { "GET" }
        "2" { "POST" }
        "3" { "PUT" }
        "4" { "DELETE" }
    }

    Write-Host ""
    $endpoint = Read-Host "Enter endpoint path (e.g., /api/templates)"

    if (-not $endpoint.StartsWith("/")) {
        $endpoint = "/$endpoint"
    }

    $body = $null
    if ($method -eq "POST" -or $method -eq "PUT") {
        Write-Host ""
        Write-Host "Enter JSON body (or press Enter to skip):" -ForegroundColor Gray
        $bodyInput = Read-Host
        if (-not [string]::IsNullOrWhiteSpace($bodyInput)) {
            # Validate JSON
            try {
                $null = $bodyInput | ConvertFrom-Json -ErrorAction Stop
                $body = $bodyInput
            }
            catch {
                Write-Host "[ERROR] Invalid JSON format" -ForegroundColor Red
                Write-Host "   Check your syntax (quotes, brackets, commas)" -ForegroundColor Yellow
                Wait-For-Enter
                return
            }
        }
    }

    $url = "http://localhost:$API_PORT$endpoint"
    Write-Host ""
    Write-Host "[$method] $url" -ForegroundColor Cyan
    Write-Host ""

    try {
        $params = @{
            Uri = $url
            Method = $method
            TimeoutSec = 15
            UseBasicParsing = $true
            ContentType = "application/json"
            ErrorAction = "Stop"
        }

        if ($body) {
            $params.Body = $body
        }

        $response = Invoke-WebRequest @params
        $statusCode = $response.StatusCode

        Write-Host "[RESPONSE] Status: $statusCode" -ForegroundColor Green
        Write-Host ""

        try {
            $json = $response.Content | ConvertFrom-Json
            $formatted = $json | ConvertTo-Json -Depth 5
            $totalLen = $formatted.Length
            if ($totalLen -gt 2000) {
                $formatted = $formatted.Substring(0, 2000) + "`n... (truncated - showing 2000 of $totalLen characters)"
            }
            Write-Host $formatted -ForegroundColor White
        }
        catch {
            $content = $response.Content
            $totalLen = $content.Length
            if ($totalLen -gt 2000) {
                $content = $content.Substring(0, 2000) + "`n... (truncated - showing 2000 of $totalLen characters)"
            }
            Write-Host $content -ForegroundColor White
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "[ERROR] Status: $statusCode" -ForegroundColor Red
            $statusMsg = Get-HttpStatusMessage -Code $statusCode
            if ($statusMsg) {
                Write-Host "   $statusMsg" -ForegroundColor Yellow
            }
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $errorContent = $reader.ReadToEnd()
                $reader.Dispose()
                Write-Host $errorContent -ForegroundColor Red
            } catch {}
        } else {
            Write-Host "[ERROR] Request failed" -ForegroundColor Red
            Write-Host "   Connection timed out or was refused" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Wait-For-Enter
}

function Do-API-ShowEndpoints {
    Write-Host ""
    Write-Host "[INFO] Available API Endpoints" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Base URL: http://localhost:$API_PORT" -ForegroundColor White
    Write-Host ""
    Write-Host "Health & Status:" -ForegroundColor Yellow
    Write-Host "  GET  /health              - Health check endpoint"
    Write-Host "  GET  /swagger             - Swagger UI (API documentation)"
    Write-Host ""
    Write-Host "Templates:" -ForegroundColor Yellow
    Write-Host "  GET    /api/templates     - List all templates"
    Write-Host "  GET    /api/templates/{id} - Get template by ID"
    Write-Host "  POST   /api/templates     - Create new template"
    Write-Host "  PUT    /api/templates/{id} - Update template"
    Write-Host "  DELETE /api/templates/{id} - Delete template"
    Write-Host ""
    Write-Host "Documents:" -ForegroundColor Yellow
    Write-Host "  GET    /api/documents     - List all documents"
    Write-Host "  GET    /api/documents/{id} - Get document by ID"
    Write-Host "  POST   /api/documents     - Generate new document"
    Write-Host "  DELETE /api/documents/{id} - Delete document"
    Write-Host ""
    Write-Host "[TIP] Use Swagger UI (option 2) for interactive API testing" -ForegroundColor Cyan
    Write-Host "      with full request/response documentation." -ForegroundColor Cyan
    Write-Host ""
    Wait-For-Enter
}

function Do-Clear-Data {
    Write-Host "[WARN] WARNING: This will delete all data (Database & Generated Files)!" -ForegroundColor Red
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
Invoke-ProactiveDependencyCheck

# Main Loop
while ($true) {
    Print-Header

    # Show Docker recommendation for Windows if dependencies have issues
    if ($Global:DependencyStatus -ne 0) {
        Write-Host "[TIP] Having dependency issues? Try Docker setup (option 5) instead!" -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host "Services:" -ForegroundColor White
    Write-Host "  1) [START] Start Backend"
    Write-Host "  2) [WEB] Start Frontend"
    Write-Host "  3) [START] Start Both Services"
    Write-Host "  4) [STOP] Stop All Services"
    Write-Host ""
    Write-Host "Setup & Dependencies:" -ForegroundColor White
    Write-Host "  5) [DOCKER] Docker Quick Start" -ForegroundColor Green
    Write-Host "  6) [SETUP] Native Setup"
    Write-Host "  7) [CHECK] Check Dependencies"
    Write-Host ""
    Write-Host "Tools:" -ForegroundColor White
    Write-Host "  8) [LOGS] View Backend Logs"
    Write-Host "  9) [LOGS] View Frontend Logs"
    Write-Host "  0) [WEB] Open App in Browser"
    Write-Host "  a) [API] API Playground" -ForegroundColor Cyan
    Write-Host "  t) [TEST] Run Tests"
    Write-Host "  r) [CHECK] Refresh Status"
    Write-Host "  c) [WARN] Clear All Data"
    Write-Host "  q) [EXIT] Quit"
    Write-Host ""
    $option = Read-Host "Select an option"

    switch ($option) {
        "1" { Do-Start-Backend }
        "2" { Do-Start-Frontend }
        "3" {
            Do-Start-Backend
            Do-Start-Frontend
        }
        "4" { Do-Stop-All }
        "5" {
            # Launch Docker quick start
            $dockerScript = "$ScriptDir\scripts\docker-quick-start.ps1"
            if (Test-Path $dockerScript) {
                & $dockerScript
            } else {
                Write-Host "[ERROR] Docker quick start script not found at: $dockerScript" -ForegroundColor Red
                Write-Host "You can run it manually: .\scripts\docker-quick-start.ps1" -ForegroundColor Yellow
                Wait-For-Enter
            }
        }
        "6" {
            Do-Setup
            # Re-check dependencies after setup
            Invoke-ProactiveDependencyCheck
        }
        "7" {
            $dependencyChecker = "$ScriptDir\scripts\check-dependencies.ps1"
            if (Test-Path $dependencyChecker) {
                & $dependencyChecker
                if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) { $Global:DependencyStatus = 0 } else { $Global:DependencyStatus = 1 }
            } else {
                Write-Host "[ERROR] Dependency checker not found" -ForegroundColor Red
                Wait-For-Enter
            }
        }
        "8" { Do-View-Logs "api.log" "Backend" }
        "9" { Do-View-Logs "client.log" "Frontend" }
        "0" { Do-Open-Browser }
        "a" { Do-API-Playground }
        "t" { Do-Test }
        "r" { } # Just loop to refresh
        "c" { Do-Clear-Data }
        "q" {
            Write-Host "[EXIT] Goodbye!" -ForegroundColor Green
            exit
        }
        Default {
            Write-Host "[ERROR] Invalid option. Please select 0-9, a, t, r, c, or q." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
