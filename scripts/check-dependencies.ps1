# DocForge Dependency Checker for Windows
# This script checks for and optionally installs required dependencies

param(
    [switch]$AutoInstall,
    [switch]$Quiet,
    [switch]$Force,
    [string]$DependencyId = ""
)

# Import configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = $PSScriptRoot
}
if (-not $ScriptDir) {
    $ScriptDir = "."
}

# Check for required config files
$DependenciesFile = "$ScriptDir\dependencies.json"
$PlatformFile = "$ScriptDir\platform-config.json"

if (-not (Test-Path $DependenciesFile)) {
    Write-Host "[ERROR] dependencies.json not found at: $DependenciesFile" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $PlatformFile)) {
    Write-Host "[ERROR] platform-config.json not found at: $PlatformFile" -ForegroundColor Red
    exit 1
}

$DependenciesConfig = Get-Content $DependenciesFile -Raw | ConvertFrom-Json
$PlatformConfig = Get-Content $PlatformFile -Raw | ConvertFrom-Json

# Color output functions
function Write-Success {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message -ForegroundColor Green }
}

function Write-Warning {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message -ForegroundColor Yellow }
}

function Write-Error {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message -ForegroundColor Red }
}

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message -ForegroundColor Cyan }
}

function Write-ProgressStatus {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Gray -NoNewline
        Write-Host "`r" -NoNewline
    }
}

function Clear-ProgressLine {
    if (-not $Quiet) {
        Write-Host ("`r" + (" " * 60) + "`r") -NoNewline
    }
}

# Dependency checking functions
function Test-Dependency {
    param(
        [string]$DependencyId,
        [object]$Dependency
    )

    Write-ProgressStatus "Checking $($Dependency.name)..."

    try {
        $windowsConfig = $Dependency.windows
        $checkCommand = $windowsConfig.checkCommand

        if ([string]::IsNullOrEmpty($checkCommand)) {
            return @{ Status = "UNKNOWN"; Version = ""; Message = "No check command specified" }
        }

        # Execute check command
        $result = Invoke-Expression $checkCommand 2>$null

        if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
            $version = Extract-VersionFromOutput $result
            $isValidVersion = Test-VersionRequirement $version $Dependency.version $Dependency.minVersion

            if ($isValidVersion) {
                Clear-ProgressLine
                Write-Success "[OK] $($Dependency.name) ($version)"
                return @{
                    Status = "OK";
                    Version = $version;
                    Message = "Installed and valid"
                }
            } else {
                Clear-ProgressLine
                Write-Warning "[WARN] $($Dependency.name) ($version) - version incompatible"
                return @{
                    Status = "WRONG_VERSION";
                    Version = $version;
                    Message = "Version $($Dependency.version) required, found $version"
                }
            }
        } else {
            Clear-ProgressLine
            Write-Error "[MISSING] $($Dependency.name) - not found"
            return @{
                Status = "MISSING";
                Version = "";
                Message = "Not installed"
            }
        }
    }
    catch {
        Clear-ProgressLine
        Write-Error "[ERROR] $($Dependency.name) - check failed: $($_.Exception.Message)"
        return @{
            Status = "ERROR";
            Version = "";
            Message = "Check failed: $($_.Exception.Message)"
        }
    }
}

function Extract-VersionFromOutput {
    param([string]$Output)

    if ([string]::IsNullOrEmpty($Output)) { return "" }

    # Common version patterns
    $patterns = @(
        "\d+\.\d+\.\d+",
        "\d+\.\d+\.\d+\.\d+",
        "v(\d+\.\d+\.\d+)",
        "version (\d+\.\d+\.\d+)"
    )

    foreach ($pattern in $patterns) {
        if ($Output -match $pattern) {
            # PS5.1 compatible - avoid ?? operator
            if ($matches[1]) { return $matches[1] } else { return $matches[0] }
        }
    }

    # Return first line if no pattern matches
    return ($Output -split "`n")[0].Trim()
}

function Test-VersionRequirement {
    param([string]$InstalledVersion, [string]$RequiredPattern, [string]$MinVersion)

    if ([string]::IsNullOrEmpty($InstalledVersion)) { return $false }

    # Try regex pattern match first
    if (-not [string]::IsNullOrEmpty($RequiredPattern)) {
        try {
            if ($InstalledVersion -match $RequiredPattern) {
                return $true
            }
        }
        catch { }
    }

    # Try version comparison
    if (-not [string]::IsNullOrEmpty($MinVersion)) {
        try {
            $installed = [Version]$InstalledVersion
            $minimum = [Version]$MinVersion
            return $installed -ge $minimum
        }
        catch { }
    }

    # Default to true if we can't validate
    return $true
}

function Install-Dependency {
    param(
        [string]$DependencyId,
        [object]$Dependency,
        [object]$Status
    )

    if ($Status.Status -eq "OK" -and -not $Force) {
        Write-Info "$($Dependency.name) is already installed and valid"
        return $true
    }

    $windowsConfig = $Dependency.windows
    $installCommand = $windowsConfig.installCommand

    if ([string]::IsNullOrEmpty($installCommand)) {
        Write-Error "No automatic installation available for $($Dependency.name)"
        Show-ManualInstallationInstructions $Dependency
        return $false
    }

    try {
        Write-Info "Installing $($Dependency.name)..."

        # Check if we have winget available
        if ($installCommand -like "winget*") {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                Write-Error "winget is not available. Please install from Microsoft Store or run Windows Update."
                return $false
            }
        }

        # Execute installation
        Write-ProgressStatus "Installing $($Dependency.name)..."
        $result = Invoke-Expression $installCommand

        if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
            Write-Success "[OK] $($Dependency.name) installed successfully"

            # Verify installation
            Start-Sleep -Seconds 2
            $newStatus = Test-Dependency $DependencyId $Dependency
            if ($newStatus.Status -eq "OK") {
                Write-Success "[OK] $($Dependency.name) verified: $($newStatus.Version)"
                return $true
            } else {
                Write-Warning "[WARN] $($Dependency.name) installed but verification failed"
                return $false
            }
        } else {
            Write-Error "[ERROR] Installation failed for $($Dependency.name)"
            Show-ManualInstallationInstructions $Dependency
            return $false
        }
    }
    catch {
        Write-Error "[ERROR] Installation error for $($Dependency.name): $($_.Exception.Message)"
        Show-ManualInstallationInstructions $Dependency
        return $false
    }
}

function Show-ManualInstallationInstructions {
    param([object]$Dependency)

    $windowsConfig = $Dependency.windows
    $manualUrl = $windowsConfig.manualInstallUrl

    Write-Info ""
    Write-Info "Manual installation required for $($Dependency.name):"
    Write-Info "----------------------------------------------------"
    Write-Info "Required version: $($Dependency.version)"
    Write-Info "Description: $($Dependency.description)"

    if (-not [string]::IsNullOrEmpty($manualUrl)) {
        Write-Info ""
        Write-Info "Download URL: $manualUrl"
    }

    if (-not [string]::IsNullOrEmpty($Dependency.notes)) {
        Write-Info ""
        Write-Info "Notes: $($Dependency.notes)"
    }

    Write-Info ""
}

function Show-DependencySummary {
    param([hashtable]$Results)

    Write-Info ""
    Write-Info "Dependency Summary:"
    Write-Info "==================="

    $total = 0
    $ok = 0
    $issues = 0

    foreach ($dep in $Results.GetEnumerator()) {
        $total++
        $status = $dep.Value.Status

        switch ($status) {
            "OK" {
                Write-Success "[OK] $($dep.Key): $($dep.Value.Version)"
                $ok++
            }
            "MISSING" {
                Write-Error "[MISSING] $($dep.Key): Not installed"
                $issues++
            }
            "WRONG_VERSION" {
                Write-Warning "[WARN] $($dep.Key): Wrong version ($($dep.Value.Version))"
                $issues++
            }
            default {
                Write-Warning "? $($dep.Key): $($dep.Value.Message)"
                $issues++
            }
        }
    }

    Write-Info ""
    Write-Info "Total: $total, OK: $ok, Issues: $issues"

    if ($issues -eq 0) {
        Write-Success "All dependencies are satisfied!"
    } else {
        Write-Warning "Found $issues dependency issue(s)"
        Write-Host ""
        Write-Host "Manual Download Links:" -ForegroundColor Yellow
        Write-Host "----------------------" -ForegroundColor Yellow

        foreach ($dep in $Results.GetEnumerator()) {
            if ($dep.Value.Status -ne "OK") {
                $depConfig = $DependenciesConfig.dependencies.($dep.Key)
                $url = $depConfig.windows.manualInstallUrl
                if ($url) {
                    Write-Host "  $($depConfig.name): " -NoNewline -ForegroundColor White
                    Write-Host $url -ForegroundColor Cyan
                }
            }
        }

        Write-Host ""
        Write-Host "[TIP] Or use Docker for an easier setup experience:" -ForegroundColor Green
        Write-Host "      https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "After installing, restart your terminal and run this check again." -ForegroundColor Gray
    }
}

function Install-Winget {
    Write-Info "Installing Windows Package Manager (winget)..."

    # Check if winget is already available
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Success "winget is already available"
        return $true
    }

    # Try to install winget via Microsoft Store (user-friendly method)
    try {
        Write-Info "Attempting to install winget from Microsoft Store..."
        Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
        Write-Info "Please install 'App Installer' from Microsoft Store, then run this script again."
        return $false
    }
    catch {
        Write-Warning "Could not open Microsoft Store. Please install winget manually:"
        Write-Info "1. Open Microsoft Store"
        Write-Info "2. Search for 'App Installer'"
        Write-Info "3. Click Install"
        Write-Info "4. Run this script again"
        return $false
    }
}

# Main execution
function Main {
    Write-Info "DocForge Dependency Checker for Windows"
    Write-Info "======================================"

    $results = @{}
    $installIssues = 0

    # Check for winget first if auto-install is requested
    if ($AutoInstall -and -not (Get-Command winget -ErrorAction SilentlyContinue)) {
        if (-not (Install-Winget)) {
            Write-Warning "Cannot proceed with automatic installation without winget"
            Write-Info "Please install winget and try again, or run without -AutoInstall"
            return
        }
    }

    # Get list of dependencies to check
    $depsToCheck = if ([string]::IsNullOrEmpty($DependencyId)) {
        $PlatformConfig.platforms.windows.dependencies
    } else {
        @($DependencyId)
    }

    foreach ($depId in $depsToCheck) {
        if (-not $DependenciesConfig.dependencies.PSObject.Properties.Name -contains $depId) {
            Write-Warning "Unknown dependency: $depId"
            continue
        }

        $dependency = $DependenciesConfig.dependencies.$depId
        $status = Test-Dependency $depId $dependency
        $results[$depId] = $status

        # Auto-install if requested and needed
        if ($AutoInstall -and ($status.Status -ne "OK" -or $Force)) {
            if (-not (Install-Dependency $depId $dependency $status)) {
                $installIssues++
            }
        }
    }

    # Show summary
    if (-not $Quiet) {
        Show-DependencySummary $results
    }

    # Return appropriate exit code
    if ($installIssues -gt 0) {
        Write-Error "Some dependencies could not be installed"
        exit 1
    }

    $hasIssues = ($results.Values | Where-Object { $_.Status -ne "OK" }).Count -gt 0
    if ($hasIssues) {
        exit 1
    } else {
        exit 0
    }
}

# Run main function
Main