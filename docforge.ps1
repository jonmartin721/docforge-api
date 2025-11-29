# docforge.ps1 - CLI for DocForge API
# Usage: .\docforge.ps1

$API_PORT = 5257
$CLIENT_PORT = 5173
$API_DIR = ".\DocumentGenerator.API"
$CLIENT_DIR = ".\DocumentGenerator.Client"

function Check-Port {
    param([int]$port)
    $tcp = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($tcp -and $tcp.State -eq 'Listen') {
        Write-Host "🟢 UP" -ForegroundColor Green -NoNewline
    } else {
        Write-Host "🔴 DOWN" -ForegroundColor Red -NoNewline
    }
}

function Print-Header {
    Clear-Host
    Write-Host "   DOCFORGE" -ForegroundColor Cyan
    Write-Host "==============================================="
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
    Write-Host "Running Setup..." -ForegroundColor Yellow
    if (Test-Path ".\scripts\setup-windows.ps1") {
        .\scripts\setup-windows.ps1
    } else {
        Write-Host "Error: scripts\setup-windows.ps1 not found!" -ForegroundColor Red
    }
    Wait-For-Enter
}

function Do-Start-Backend-NewWindow {
    Write-Host "Starting Backend in new window..." -ForegroundColor Yellow
    Start-Process dotnet -ArgumentList "run --project $API_DIR"
    
    # Wait for API to be ready (with timeout)
    Write-Host "Waiting for API to be ready..." -ForegroundColor Gray
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 1
        $tcp = Get-NetTCPConnection -LocalPort $API_PORT -ErrorAction SilentlyContinue
        if ($tcp -and $tcp.State -eq 'Listen') {
            Write-Host "✓ API is up and running!" -ForegroundColor Green
            Wait-For-Enter
            return
        }
    }
    
    Write-Host "⚠ API may not have started. Check the new window for errors." -ForegroundColor Red
    Wait-For-Enter
}

function Do-Start-Frontend-NewWindow {
    Write-Host "Starting Frontend in new window..." -ForegroundColor Yellow
    Push-Location $CLIENT_DIR
    Start-Process npm -ArgumentList "run dev"
    Pop-Location
    
    # Wait for Vite to be ready (with timeout)
    Write-Host "Waiting for Vite to be ready..." -ForegroundColor Gray
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 1
        $tcp = Get-NetTCPConnection -LocalPort $CLIENT_PORT -ErrorAction SilentlyContinue
        if ($tcp -and $tcp.State -eq 'Listen') {
            Write-Host "✓ Frontend is up and running!" -ForegroundColor Green
            Wait-For-Enter
            return
        }
    }
    
    Write-Host "⚠ Frontend may not have started. Check the new window for errors." -ForegroundColor Red
    Wait-For-Enter
}

function Do-Stop-All {
    Write-Host "Stopping services..." -ForegroundColor Yellow
    
    # Stop API
    $api = Get-NetTCPConnection -LocalPort $API_PORT -ErrorAction SilentlyContinue
    if ($api) { 
        Stop-Process -Id $api.OwningProcess -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Stopped API" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  API not running" -ForegroundColor Gray
    }
    
    # Stop Frontend (Vite/Node)
    $client = Get-NetTCPConnection -LocalPort $CLIENT_PORT -ErrorAction SilentlyContinue
    if ($client) { 
        Stop-Process -Id $client.OwningProcess -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Stopped Frontend" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Frontend not running" -ForegroundColor Gray
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
    Write-Host "⚠ WARNING: This will delete all data (Database & Generated Files)!" -ForegroundColor Red
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

# Main Loop
while ($true) {
    Print-Header
    Write-Host "Core Actions:" -ForegroundColor White
    Write-Host "  1) 🔧 Setup Dependencies"
    Write-Host "  2) 🚀 Start Backend"
    Write-Host "  3) 🌐 Start Frontend"
    Write-Host "  4) ⚡ Start Both"
    Write-Host "  5) 🛑 Stop All Services"
    Write-Host ""
    Write-Host "Tools:" -ForegroundColor White
    Write-Host "  6) 📄 View Backend Logs"
    Write-Host "  7) 📑 View Frontend Logs"
    Write-Host "  8) 🌍 Open App in Browser"
    Write-Host "  9) 🧪 Run Tests"
    Write-Host ""
    Write-Host "  r) 🔄 Refresh Status"
    Write-Host "  c) 🗑️ Clear All Data"
    Write-Host "  q) Quit"
    Write-Host ""
    $option = Read-Host "Select an option"

    switch ($option) {
        "1" { Do-Setup }
        "2" { Do-Start-Backend-NewWindow }
        "3" { Do-Start-Frontend-NewWindow }
        "4" { Do-Start-Backend-NewWindow; Do-Start-Frontend-NewWindow }
        "5" { Do-Stop-All }
        "6" { Do-View-Logs "api.log" "Backend" }
        "7" { Do-View-Logs "client.log" "Frontend" }
        "8" { Do-Open-Browser }
        "9" { Do-Test }
        "r" { } # Just loop to refresh
        "c" { Do-Clear-Data }
        "q" { exit }
        Default { Write-Host "Invalid option"; Start-Sleep -Seconds 1 }
    }
}
