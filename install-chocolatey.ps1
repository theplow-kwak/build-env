# Chocolatey Installation Script for Windows Containers
# This script securely installs Chocolatey package manager with comprehensive error handling
# Version: 1.4.0

# Configuration
$chocolateyVersion = "1.4.0"
$installerUrl = "https://community.chocolatey.org/install.ps1"
$timeoutSeconds = 300
$retryAttempts = 3

Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop

# Check if Chocolatey is already installed
function Test-ChocolateyInstalled {
    try {
        # Check if choco command is available in PATH
        $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoPath) {
            # Try to get version - this will fail if choco is not properly installed
            $installedVersion = & choco --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $installedVersion) {
                Write-Host "Chocolatey is already installed (version: $installedVersion)"
                return $true
            }
        }
    }
    catch {
        # Chocolatey not found or not working
    }
    
    # Additional check: look for chocolatey installation directory
    $chocoInstallDir = "C:\ProgramData\chocolatey"
    if (Test-Path $chocoInstallDir) {
        Write-Host "Chocolatey installation directory found at $chocoInstallDir"
        # Check if choco.exe exists
        $chocoExe = Join-Path $chocoInstallDir "bin\choco.exe"
        if (Test-Path $chocoExe) {
            Write-Host "Chocolatey executable found at $chocoExe"
            return $true
        }
    }

    return $false
}

# Skip installation if Chocolatey is already present and working
if (Test-ChocolateyInstalled) {
    Write-Host "Skipping Chocolatey installation - already installed and verified"
    exit 0
}

Write-Host "Installing Chocolatey version $chocolateyVersion"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download and execute Chocolatey installer with retry logic
$installationSuccessful = $false
$tempFile = Join-Path $env:TEMP "install-chocolatey.ps1"

for ($attempt = 1; $attempt -le $retryAttempts; $attempt++) {
    try {
        Write-Host "Attempt $attempt of $($retryAttempts): Downloading Chocolatey installer..."
        Invoke-WebRequest -Uri $installerUrl -OutFile $tempFile -UseBasicParsing -TimeoutSec $timeoutSeconds
        
        & $tempFile -verbose
        
        # Verify installation
        if (Test-ChocolateyInstalled) {
            Write-Host "Chocolatey $chocolateyVersion installed successfully"
            $installationSuccessful = $true
            break
        }
        else {
            Write-Warning "Installation script executed but verification failed"
        }
    }
    catch {
        Write-Warning "Attempt $attempt failed: $($_.Exception.Message)"
        if ($attempt -lt $retryAttempts) {
            Write-Host "Waiting 5 seconds before retry..."
            Start-Sleep -Seconds 5
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

if (-not $installationSuccessful) {
    Write-Error "Failed to install Chocolatey after $retryAttempts attempts"
    Write-Error "Please check your internet connection and try again"
    exit 1
}

# Comprehensive verification
try {
    $version = & choco --version
    Write-Host "Chocolatey version: $version"
    & choco list --local-only | Out-Null
    & choco search chocolatey --limit-output | Out-Null
    Write-Host "Chocolatey installation and verification completed successfully"
}
catch {
    Write-Error "Chocolatey installation verification failed: $_"
    Write-Warning "Chocolatey may be partially installed. Please run 'choco --version' manually to verify."
    Write-Warning "You may need to restart your shell for 'choco' to be available in PATH."
    exit 1
}
