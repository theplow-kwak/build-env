#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Windows build environment setup script (Dockerfile conversion)
  Installs CMake, LLVM, Python, Git, VS Build Tools, Node.js, vcpkg

.EXAMPLE
  .\build-env.ps1                    # Full install (same as Dockerfile build)
  .\build-env.ps1 -Entry -Command cmd,/c,install.bat
#>
param(
    [string[]]$Command   # Command to execute (Entry mode)
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$deps = 'C:\deps'
$workspace = 'C:\workspace'
$nodeVersion = '14.16.1'
$nodeBasePath = "$deps\third-party-lib\node-cache\v14.16.0"

function Update-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Install-Chocolatey {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.ScriptFileName }
    if (Test-Path "$scriptDir\install-chocolatey.ps1") {
        & "$scriptDir\install-chocolatey.ps1"
    }
    else {
        if (Get-Command choco -ErrorAction SilentlyContinue) { Write-Host 'Chocolatey already installed'; return }
        $chocoDir = 'C:\ProgramData\chocolatey'
        if ((Test-Path $chocoDir) -and (Test-Path "$chocoDir\bin\choco.exe")) { Write-Host 'Chocolatey found'; return }
        Write-Host 'Installing Chocolatey...'
        $tmp = Join-Path $env:TEMP 'choco-install.ps1'
        Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -OutFile $tmp -UseBasicParsing -TimeoutSec 300
        & $tmp; Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
    Update-Path
}

function Invoke-Entrypoint {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.ScriptFileName }
    if (Test-Path "$scriptDir\entrypoint.ps1") {
        $cmdArgs = $Command
        if ($cmdArgs) { & "$scriptDir\entrypoint.ps1" @cmdArgs } else { & "$scriptDir\entrypoint.ps1" }
    }
    else {
        $headersInImage = "$deps\third-party-lib"; $headersInVolume = "$workspace\third-party-lib"
        if (-not (Test-Path $headersInVolume)) { Copy-Item -Path $headersInImage -Destination $headersInVolume -Recurse -Force }
        if ($Command.Count -gt 0) {
            $exe = $Command[0]; $rest = $Command[1..($Command.Count - 1)]
            & $exe @rest
        }
    }
}

New-Item $deps -ItemType Directory -Force | Out-Null

Install-Chocolatey
choco install -y cmake --version=3.31.10
choco install -y llvm --version=14.0.6
choco install -y python --version=3.10.11
choco install -y git
choco install -y vscode
choco install -y visualstudio2022buildtools --package-parameters="'--installPath C:\deps\vs2022 --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.Windows11SDK.22621'"
choco install -y nodejs --version=14.16.1
choco install -y beyondcompare
Update-Path

$env:PATH = 'C:\Program Files\nodejs;' + $env:PATH
npm config set msvs_version 2022 --global
npm config set python 'C:\Python310\python.exe'
npm config set strict-ssl false
npm install -g node-gyp@9.4.1
Update-Path

python -m pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org --upgrade pip
python -m pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org colorama==0.4.3 minio==5.0.10

git config --global http.sslVerify false
git clone https://github.com/microsoft/vcpkg.git "$deps\vcpkg"
& "$deps\vcpkg\bootstrap-vcpkg.bat"
Update-Path

$userDirs = @('C:\Users\ContainerAdministrator', 'C:\Users\Administrator')
foreach ($u in $userDirs) {
    if (Test-Path $u) {
        $vcpkgLink = Join-Path $u 'vcpkg'
        if (-not (Test-Path $vcpkgLink)) { 
            New-Item -ItemType SymbolicLink -Path $vcpkgLink -Target "$deps\vcpkg" -Force
        }
    }
}

New-Item -Path "$nodeBasePath\x64" -ItemType Directory -Force | Out-Null
Invoke-WebRequest "https://nodejs.org/download/release/v$nodeVersion/node-v$nodeVersion-headers.tar.gz" -OutFile C:\node_headers.tar.gz
tar -xf C:\node_headers.tar.gz -C $nodeBasePath --strip-components=1
Invoke-WebRequest "https://nodejs.org/download/release/v$nodeVersion/win-x64/node.lib" -OutFile "$nodeBasePath\x64\node.lib"
Remove-Item C:\node_headers.tar.gz -Force

$existingInclude = [Environment]::GetEnvironmentVariable('INCLUDE', 'Machine'); if (-not $existingInclude) { $existingInclude = '' }
$existingLib = [Environment]::GetEnvironmentVariable('LIB', 'Machine'); if (-not $existingLib) { $existingLib = '' }
@{
    GYP_MSVS_VERSION = '2022'; VCINSTALLDIR = "$deps\vs2022\VC"; PYTHON = 'C:\Python310\python.exe'
    VSCMD_ARG_host_arch = 'x64'; VSCMD_ARG_target_arch = 'x64'; VCPKG_ROOT = "$deps\vcpkg"
    NODE_BASE_PATH = $nodeBasePath
    INCLUDE = "$nodeBasePath\include;$existingInclude"
    LIB = "$nodeBasePath\x64;$existingLib"
}.GetEnumerator() | ForEach-Object { [Environment]::SetEnvironmentVariable($_.Key, $_.Value, 'Machine') }
[Environment]::SetEnvironmentVariable('NODE_TLS_REJECT_UNAUTHORIZED', '0', 'Machine')
$kitPath = 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64'
$currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
[Environment]::SetEnvironmentVariable('Path', "$currentPath;$kitPath", 'Machine')
Update-Path
Invoke-Entrypoint

Set-Location $workspace
Write-Host 'Setup complete. Open a new terminal or run refreshenv, then use -Entry or -Entry -Command.'
