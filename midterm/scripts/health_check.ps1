param(
    [string]$Url = "http://127.0.0.1:5000/health",
    [int]$IntervalSeconds = 10,
    [int]$Iterations = 12,
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Continue"

$logDir = Join-Path $ProjectRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir "health_check.log"

for ($i = 1; $i -le $Iterations; $i++) {
    $timestamp = (Get-Date).ToString("s")
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 5
        $line = "$timestamp | status=$($response.StatusCode) | result=ok"
    }
    catch {
        $line = "$timestamp | status=down | result=error | message=$($_.Exception.Message)"
    }

    Add-Content -Path $logFile -Value $line
    Write-Host $line
    Start-Sleep -Seconds $IntervalSeconds
}
