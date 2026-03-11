[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern("^[^:]+:\d+$")]
    [string]$Registry
)

$configPath = "C:\ProgramData\docker\config"
$configFile = "$configPath\daemon.json"
$newRegistry = $Registry

# Validate registry is provided
if ([string]::IsNullOrWhiteSpace($newRegistry)) {
    Write-Error "Error: Registry paramter is required. Usage: .\insecure-docker.ps1 -Registry server-ip:port"
    exit 1
}

if (!(Test-Path $configPath)) { 
    New-Item -ItemType Directory -Path $configPath | Out-Null 
}

if (Test-Path $configFile) {
    $currentConfig = Get-Content $configFile -Raw | ConvertFrom-Json
} else {
    $currentConfig = @{} | Select-Object -Property "insecure-registries"
}

# 4. insecure-registries updates
if ($null -eq $currentConfig."insecure-registries") {
    $currentConfig | Add-Member -MemberType NoteProperty -Name "insecure-registries" -Value @($newRegistry)
} else {
    if ($currentConfig."insecure-registries" -notcontains $newRegistry) {
        $currentConfig."insecure-registries" += $newRegistry
    }
}

$currentConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile

Write-Host "Success: $newRegistry has been merged into $configFile." -ForegroundColor Green

# 6. restart Docker service
Restart-Service docker

# 7. check result
docker info | Select-String "Insecure Registries" -Context 0,1
