param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

Write-Host "Preparing environment at: $ProjectRoot"
Set-Location $ProjectRoot

$venvPath = Join-Path $ProjectRoot ".venv"
$deployPath = Join-Path $ProjectRoot "deployments"
$logPath = Join-Path $ProjectRoot "logs"

if (!(Test-Path $venvPath)) {
    python -m venv .venv
}

New-Item -ItemType Directory -Force -Path $deployPath | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $deployPath "blue") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $deployPath "green") | Out-Null
New-Item -ItemType Directory -Force -Path $logPath | Out-Null

& "$venvPath\Scripts\python.exe" -m pip install --upgrade pip
& "$venvPath\Scripts\python.exe" -m pip install -r requirements.txt

if (!(Test-Path (Join-Path $deployPath "active_slot.txt"))) {
    "none" | Set-Content -Path (Join-Path $deployPath "active_slot.txt")
}

Write-Host "Environment setup completed."
