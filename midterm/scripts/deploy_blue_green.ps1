param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

Set-Location $ProjectRoot
$deployRoot = Join-Path $ProjectRoot "deployments"
$activeSlotFile = Join-Path $deployRoot "active_slot.txt"

if (!(Test-Path $activeSlotFile)) {
    throw "Run setup first: scripts/setup_env.ps1"
}

$activeSlot = (Get-Content $activeSlotFile -ErrorAction Stop).Trim().ToLower()

if ($activeSlot -eq "blue") {
    $targetSlot = "green"
    $previousSlot = "blue"
}
else {
    $targetSlot = "blue"
    $previousSlot = if ($activeSlot -eq "green") { "green" } else { "none" }
}

$targetDir = Join-Path $deployRoot $targetSlot
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

Get-ChildItem -Path $targetDir -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Copy-Item -Path (Join-Path $ProjectRoot "app.py") -Destination $targetDir -Force
Copy-Item -Path (Join-Path $ProjectRoot "requirements.txt") -Destination $targetDir -Force
Copy-Item -Path (Join-Path $ProjectRoot "templates") -Destination (Join-Path $targetDir "templates") -Recurse -Force

$state = @{
    active = $targetSlot
    previous = $previousSlot
    deployedAt = (Get-Date).ToString("s")
}
$state | ConvertTo-Json | Set-Content -Path (Join-Path $deployRoot "deployment_state.json")

$targetSlot | Set-Content -Path $activeSlotFile

Write-Host "Blue-Green deployment complete. Active slot: $targetSlot"
