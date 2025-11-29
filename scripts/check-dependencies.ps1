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
$DependenciesConfig = Get-Content "$ScriptDir\dependencies.json" | ConvertFrom-Json
$PlatformConfig = Get-Content "$ScriptDir\platform-config.json" | ConvertFrom-Json

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

function Write-Progress {
    param([string]$Message, [int]$PercentComplete = 0)
    if (-not $Quiet) { Write-Progress -Activity "Checking Dependencies" -Status $Message -PercentComplete $PercentComplete }
}

# Dependency checking functions
function Test-Dependency {
    param(
        [string]$DependencyId,
        [object]$Dependency
    )

    Write-Progress "Checking $($Dependency.name)..." -PercentComplete 0

    try {
        $windowsConfig = $Dependency.windows
        $checkCommand = $windowsConfig.checkCommand

        if ([string]::IsNullOrEmpty($checkCommand)) {
            return @{ Status = "UNKNOWN"; Version = ""; Message = "No check command specified" }
        }

        # Execute check command
        $result = Invoke-Expression $checkCommand 2>$null

        if ($LASTEXITCODE -eq 0) {
            $version = Extract-VersionFromOutput $result
            $isValidVersion = Test-VersionRequirement $version $Dependency.version $Dependency.minVersion

            if ($isValidVersion) {
                Write-Success "✓ $($Dependency.name) ($version)"
                return @{
                    Status = "OK";
                    Version = $version;
                    Message = "Installed and valid"
                }
            } else {
                Write-Warning "⚠ $($Dependency.name) ($version) - version incompatible"
                return @{
                    Status = "WRONG_VERSION";
                    Version = $version;
                    Message = "Version $($Dependency.version) required, found $version"
                }
            }
        } else {
            Write-Error "✗ $($Dependency.name) - not found"
            return @{
                Status = "MISSING";
                Version = "";
                Message = "Not installed"
            }
        }
    }
    catch {
        Write-Error "✗ $($Dependency.name) - check failed: $($_.Exception.Message)"
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
            return $matches[1] ?? $matches[0]
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
        Write-Progress "Installing $($Dependency.name)..." -PercentComplete 50
        $result = Invoke-Expression $installCommand

        if ($LASTEXITCODE -eq 0) {
            Write-Success "✓ $($Dependency.name) installed successfully"

            # Verify installation
            Start-Sleep -Seconds 2
            $newStatus = Test-Dependency $DependencyId $Dependency
            if ($newStatus.Status -eq "OK") {
                Write-Success "✓ $($Dependency.name) verified: $($newStatus.Version)"
                return $true
            } else {
                Write-Warning "⚠ $($Dependency.name) installed but verification failed"
                return $false
            }
        } else {
            Write-Error "✗ Installation failed for $($Dependency.name)"
            Show-ManualInstallationInstructions $Dependency
            return $false
        }
    }
    catch {
        Write-Error "✗ Installation error for $($Dependency.name): $($_.Exception.Message)"
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
                Write-Success "✓ $($dep.Key): $($dep.Value.Version)"
                $ok++
            }
            "MISSING" {
                Write-Error "✗ $($dep.Key): Not installed"
                $issues++
            }
            "WRONG_VERSION" {
                Write-Warning "⚠ $($dep.Key): Wrong version ($($dep.Value.Version))"
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

    $depCount = $depsToCheck.Count
    $current = 0

    foreach ($depId in $depsToCheck) {
        $current++
        $progressPercent = [math]::Round(($current / $depCount) * 100)

        if (-not $DependenciesConfig.dependencies.PSObject.Properties.Name -contains $depId) {
            Write-Warning "Unknown dependency: $depId"
            continue
        }

        $dependency = $DependenciesConfig.dependencies.$depId
        Write-Progress "Checking $($dependency.name)..." -PercentComplete $progressPercent

        $status = Test-Dependency $depId $dependency
        $results[$depId] = $status

        # Auto-install if requested and needed
        if ($AutoInstall -and ($status.Status -ne "OK" -or $Force)) {
            if (-not (Install-Dependency $depId $dependency $status)) {
                $installIssues++
            }
        }
    }

    Write-Progress "Complete" -PercentComplete 100

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