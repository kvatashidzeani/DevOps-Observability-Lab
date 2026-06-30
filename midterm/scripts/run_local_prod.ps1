param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [int]$Port = 5000
)

$ErrorActionPreference = "Stop"

$deployRoot = Join-Path $ProjectRoot "deployments"
$activeSlotFile = Join-Path $deployRoot "active_slot.txt"
$venvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"

if (!(Test-Path $activeSlotFile)) {
    throw "Run setup and deployment first."
}

$activeSlot = (Get-Content $activeSlotFile).Trim()
if ($activeSlot -eq "none" -or [string]::IsNullOrWhiteSpace($activeSlot)) {
    throw "No active deployment slot found. Run deploy script first."
}

$activeDir = Join-Path $deployRoot $activeSlot
if (!(Test-Path (Join-Path $activeDir "app.py"))) {
    throw "Active slot does not contain deployed app."
}

Set-Location $activeDir
$env:FLASK_APP = "app.py"
$env:FLASK_RUN_HOST = "0.0.0.0"
$env:FLASK_RUN_PORT = "$Port"

& $venvPython -m flask run
