# Windows Container-based Development Environment PowerShell Script
# Equivalent to Dockerfile functionality
# Version: 1.0.0

# Bypass execution policy for containerized environments
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Environment variables
$NODE_VERSION = "14.16.1"
$NODE_BASE_PATH = "C:\deps\third-party-lib\node-cache\v14.16.0"
$VCPKG_ROOT = "C:\deps\vcpkg"
$VS_INSTALL_PATH = "C:\deps\vs2022"

# Directories
$depsDir = "C:\deps"
$workspaceDir = "C:\workspace"
$tempDir = "C:\temp"

# Ensure directories exist
New-Item -ItemType Directory -Path $depsDir -Force | Out-Null
New-Item -ItemType Directory -Path $workspaceDir -Force | Out-Null
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Function to add to PATH
function Add-ToPath {
    param(
        [string]$PathToAdd,
        [string]$Description = ""
    )
    
    $currentPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    if ($currentPath -notlike "*$PathToAdd*") {
        $newPath = "$PathToAdd;$currentPath"
        [Environment]::SetEnvironmentVariable('PATH', $newPath, 'Machine')
        Write-Host "Added to PATH: $PathToAdd ($Description)"
    }
}

# Function to set environment variable
function Set-EnvVar {
    param(
        [string]$Name,
        [string]$Value
    )
    
    [Environment]::SetEnvironmentVariable($Name, $Value, 'Machine')
    Write-Host "Set environment variable: $Name = $Value"
}

# Install Chocolatey
Write-Host "Installing Chocolatey..."
Copy-Item -Path "install-chocolatey.ps1" -Destination "$tempDir\install-chocolatey.ps1" -Force
& "$tempDir\install-chocolatey.ps1"

# Install basic development tools
Write-Host "Installing development tools via Chocolatey..."
choco install -y cmake --version=3.31.10
choco install -y llvm --version=14.0.6
choco install -y python --version=3.10.11
choco install -y git
choco install -y vscode
choco install -y beyondcompare

# Add Python to PATH immediately
Add-ToPath -Path "C:\Python310" -Description "Python 3.10"

# Install Visual Studio Build Tools
Write-Host "Installing Visual Studio Build Tools..."
choco install -y visualstudio2022buildtools `
    --package-parameters "--installPath $VS_INSTALL_PATH --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.Windows11SDK.22621"

# Add VS tools to PATH
Add-ToPath -Path "$VS_INSTALL_PATH\VC\Tools\MSVC\bin\Hostx64\x64" -Description "MSVC Compiler"
Add-ToPath -Path "$VS_INSTALL_PATH\Common7\IDE\VC\VCPackages" -Description "VC Packages"
Add-ToPath -Path "$VS_INSTALL_PATH\Common7\IDE\CommonExtensions\Microsoft\TestWindow" -Description "Test Window"

# Install Node.js
Write-Host "Installing Node.js..."
choco install -y nodejs --version=14.16.1

# Configure Node.js environment
Add-ToPath -Path "C:\Program Files\nodejs" -Description "Node.js"

# Refresh environment variables to include newly installed Node.js
$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine')

# Configure npm (now available in PATH)
npm config set msvs_version 2022 --global
npm config set python "C:\Python310\python.exe"
npm config set strict-ssl false
npm install -g node-gyp@9.4.1

# Clean up chocolatey cache
# choco source remove -n=chocolatey

# Install Python packages
Write-Host "Installing Python packages..."
python -m pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org --upgrade pip
python -m pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org colorama==0.4.3 minio==5.0.10

# Clone and bootstrap vcpkg
Write-Host "Setting up vcpkg..."
git config --global http.sslVerify false
git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT
& "$VCPKG_ROOT\bootstrap-vcpkg.bat"

# Create symbolic links for vcpkg in user home directories
$adminHome = "C:\Users\Administrator"
$containerAdminHome = "C:\Users\ContainerAdministrator"

if (-not (Test-Path "$adminHome\vcpkg")) {
    New-Item -ItemType SymbolicLink -Path "$adminHome\vcpkg" -Target $VCPKG_ROOT -Force | Out-Null
}

if (-not (Test-Path "$containerAdminHome\vcpkg")) {
    New-Item -ItemType SymbolicLink -Path "$containerAdminHome\vcpkg" -Target $VCPKG_ROOT -Force | Out-Null
}

# Download and extract Node headers
Write-Host "Setting up Node.js headers..."
New-Item -ItemType Directory -Path "$NODE_BASE_PATH\x64" -Force | Out-Null

$nodeHeadersUrl = "https://nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-headers.tar.gz"
$nodeLibUrl = "https://nodejs.org/download/release/v$NODE_VERSION/win-x64/node.lib"

Invoke-WebRequest -Uri $nodeHeadersUrl -OutFile "C:\node_headers.tar.gz" -UseBasicParsing
tar -xf "C:\node_headers.tar.gz" -C "$NODE_BASE_PATH" --strip-components=1
Invoke-WebRequest -Uri $nodeLibUrl -OutFile "$NODE_BASE_PATH\x64\node.lib" -UseBasicParsing
Remove-Item "C:\node_headers.tar.gz" -Force

# Set environment variables
Set-EnvVar -Name "GYP_MSVS_VERSION" -Value "2022"
Set-EnvVar -Name "VCINSTALLDIR" -Value "$VS_INSTALL_PATH\VC"
Set-EnvVar -Name "PYTHON" -Value "C:\Python310\python.exe"
Set-EnvVar -Name "VSCMD_ARG_host_arch" -Value "x64"
Set-EnvVar -Name "VSCMD_ARG_target_arch" -Value "x64"
Set-EnvVar -Name "VCPKG_ROOT" -Value $VCPKG_ROOT

# Update INCLUDE and LIB paths
$currentInclude = [Environment]::GetEnvironmentVariable('INCLUDE', 'Machine')
Set-EnvVar -Name "INCLUDE" -Value "$NODE_BASE_PATH\include;$currentInclude"

$currentLib = [Environment]::GetEnvironmentVariable('LIB', 'Machine')
Set-EnvVar -Name "LIB" -Value "$NODE_BASE_PATH\x64;$currentLib"

# Set NODE_TLS_REJECT_UNAUTHORIZED
Set-EnvVar -Name "NODE_TLS_REJECT_UNAUTHORIZED" -Value "0"

# Add Windows SDK to PATH
Add-ToPath -Path "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64" -Description "Windows SDK"

# Copy entrypoint script
Copy-Item -Path "entrypoint.ps1" -Destination "$tempDir\entrypoint.ps1" -Force

# Set working directory
Set-Location $workspaceDir

# Function to run entrypoint
function Start-Entrypoint {
    param(
        [string[]]$Arguments = @()
    )
    
    # Copy headers if needed (from entrypoint.ps1 logic)
    $headersInImage = "C:\deps\third-party-lib"
    $headersInVolume = "C:\workspace\third-party-lib"

    if (-not (Test-Path -Path $headersInVolume)) {
        Write-Host "Headers not found in host volume. Creating symbolic link..."
        Copy-Item -Path $headersInImage -Destination $headersInVolume -Recurse -Force
    }
    else {
        Write-Host "Headers already exist in host volume. Skipping symlink creation."
    }

    if ($Arguments.Count -gt 0) {
        Write-Host "Executing main process: $Arguments"
        & $Arguments[0] $Arguments[1..($Arguments.Count - 1)]
    }
}

# Auto-refresh environment variables for immediate use
$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
$env:INCLUDE = [Environment]::GetEnvironmentVariable('INCLUDE', 'Machine')
$env:LIB = [Environment]::GetEnvironmentVariable('LIB', 'Machine')

Write-Host "Development environment setup completed successfully!"
Write-Host "Environment variables refreshed for immediate use."
Write-Host "Use Start-Entrypoint to run commands in this environment."
