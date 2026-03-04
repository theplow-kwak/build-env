# Chocolatey installation script for Windows containers
# This script installs Chocolatey package manager

Set-ExecutionPolicy Bypass -Scope Process -Force

# Set Chocolatey version to 1.4.0
$env:ChocolateyVersion = "1.4.0"

# Download and install Chocolatey
$installChocolateyExpression = "iex ((New-Object System.Net.ServicePointManager).SecurityProtocol = 3072; iex(New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

try {
    Invoke-Expression $installChocolateyExpression
    Write-Host "Chocolatey 1.4.0 installed successfully"
}
catch {
    Write-Error "Failed to install Chocolatey: $_"
    exit 1
}

# Verify installation
try {
    & choco --version
    Write-Host "Chocolatey verification successful"
}
catch {
    Write-Error "Chocolatey installation verification failed: $_"
    exit 1
}
