# docforge.ps1 - TUI for DocForge API
# Usage: .\docforge.ps1

$API_PORT = 5257
$CLIENT_PORT = 5173
$API_DIR = ".\DocumentGenerator.API"
$CLIENT_DIR = ".\DocumentGenerator.Client"

function Check-Port {
    param([int]$port)
    $tcp = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($tcp -and $tcp.State -eq 'Listen') {
        Write-Host "UP" -ForegroundColor Green -NoNewline
    } else {
        Write-Host "DOWN" -ForegroundColor Red -NoNewline
    }
}

function Print-Header {
    Clear-Host
    Write-Host "  ____             ______                      " -ForegroundColor Cyan
    Write-Host " |  _ \  ___   ___|  ____|___  _ __ __ _  ___  " -ForegroundColor Cyan
    Write-Host " | | | |/ _ \ / __| |__  / _ \| '__/ _\` |/ _ \ " -ForegroundColor Cyan
    Write-Host " | |_| | (_) | (__|  __|| (_) | | | (_| |  __/ " -ForegroundColor Cyan
    Write-Host " |____/ \___/ \___|_|    \___/|_|  \__, |\___| " -ForegroundColor Cyan
    Write-Host "                                    __/ |      " -ForegroundColor Cyan
    Write-Host "                                   |___/       " -ForegroundColor Cyan
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

function Do-Test {
    Write-Host "Running Tests..." -ForegroundColor Yellow
    dotnet test
    Wait-For-Enter
}

# Main Loop
while ($true) {
    Print-Header
    Write-Host "1) 🔧 Setup (Install Dependencies)"
    Write-Host "2) 🚀 Start Backend (New Window)"
    Write-Host "3) 🌐 Start Frontend (New Window)"
    Write-Host "4) ⚡ Start Both"
    Write-Host "5) 🛑 Stop All (Manual)"
    Write-Host "6) 🧪 Run Tests"
    Write-Host "q) Quit"
    Write-Host ""
    $option = Read-Host "Select an option"

    switch ($option) {
        "1" { Do-Setup }
        "2" { Do-Start-Backend-NewWindow }
        "3" { Do-Start-Frontend-NewWindow }
        "4" { Do-Start-Backend-NewWindow; Do-Start-Frontend-NewWindow }
        "5" { Do-Stop-All }
        "6" { Do-Test }
        "q" { exit }
        Default { Write-Host "Invalid option"; Start-Sleep -Seconds 1 }
    }
}
