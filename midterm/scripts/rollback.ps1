param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

$deployRoot = Join-Path $ProjectRoot "deployments"
$stateFile = Join-Path $deployRoot "deployment_state.json"
$activeSlotFile = Join-Path $deployRoot "active_slot.txt"

if (!(Test-Path $stateFile)) {
    throw "No deployment state found. Deploy first."
}

$state = Get-Content $stateFile | ConvertFrom-Json

if ($state.previous -eq "none") {
    throw "No previous slot available for rollback."
}

$newState = @{
    active = $state.previous
    previous = $state.active
    rolledBackAt = (Get-Date).ToString("s")
}

$newState | ConvertTo-Json | Set-Content -Path $stateFile
$state.previous | Set-Content -Path $activeSlotFile

Write-Host "Rollback complete. Active slot: $($state.previous)"
