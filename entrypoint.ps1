# entrypoint.ps1

$headersInImage = "C:\deps\third-party-lib"
$headersInVolume = "C:\workspace\third-party-lib"

if (-not (Test-Path -Path $headersInVolume)) {
    Write-Host "Headers not found in host volume. Creating symbolic link..."
    Copy-Item -Path $headersInImage -Destination $headersInVolume -Recurse -Force
} else {
    Write-Host "Headers already exist in host volume. Skipping symlink creation."
}

if ($args.Count -gt 0) {
    Write-Host "Executing main process: $args"
    & $args[0] $args[1..($args.Count - 1)]
}
