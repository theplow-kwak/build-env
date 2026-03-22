# Chocolatey Installation Script for Windows Containers
# Optimized version with minimal dependencies and robust error handling
# Version: 2.0.0

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Configuration
$installerUrl = "https://community.chocolatey.org/install.ps1"
$timeoutSeconds = 300

# Check if Chocolatey is already installed
function Test-ChocolateyInstalled {
    try {
        $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoPath) {
            $installedVersion = & choco --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $installedVersion) {
                Write-Host "Chocolatey already installed (version: $installedVersion)"
                return $true
            }
        }
    }
    catch { }
    
    # Check installation directory
    $chocoInstallDir = "C:\ProgramData\chocolatey"
    if ((Test-Path $chocoInstallDir) -and (Test-Path (Join-Path $chocoInstallDir "bin\choco.exe"))) {
        Write-Host "Chocolatey installation found at $chocoInstallDir"
        return $true
    }
    return $false
}

# Skip if already installed
if (Test-ChocolateyInstalled) {
    Write-Host "Chocolatey installation skipped - already present"
    exit 0
}

Write-Host "Installing Chocolatey..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download and execute installer
$tempFile = Join-Path $env:TEMP "install-chocolatey.ps1"

try {
    Write-Host "Downloading installer..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $tempFile -UseBasicParsing -TimeoutSec $timeoutSeconds
    & $tempFile -verbose
    
    if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey installed successfully"
    } else {
        Write-Error "Installation verification failed"
        exit 1
    }
}
catch {
    Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
}

# Final verification
try {
    $version = & choco --version
    Write-Host "Chocolatey $version verified successfully"
}
catch {
    Write-Error "Installation verification failed: $_"
    exit 1
}
