# Start the observability lab and wait until core services respond.
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot

Write-Host "Starting observability stack..." -ForegroundColor Cyan

try {
    docker version | Out-Null
} catch {
    Write-Host "Docker is not running. Start Docker Desktop first." -ForegroundColor Red
    exit 1
}

docker compose down 2>$null

Write-Host ""
Write-Host "Building images and starting containers (first run: 3-10 min)..." -ForegroundColor Yellow
Write-Host "Docker is downloading images and building the app — this is normal." -ForegroundColor DarkGray
Write-Host ""

docker compose up -d --build

if ($LASTEXITCODE -ne 0) {
    Write-Host "docker compose failed. Run: docker compose logs" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Waiting for services (up to 2 minutes)..." -ForegroundColor Yellow

$targets = @(
    @{ Name = "App";        Url = "http://localhost:8080/health" },
    @{ Name = "Grafana";    Url = "http://localhost:3000/api/health" },
    @{ Name = "Prometheus"; Url = "http://localhost:9090/-/healthy" }
)

$deadline = (Get-Date).AddMinutes(2)
$allReady = $false

while ((Get-Date) -lt $deadline) {
    $ready = 0
    foreach ($t in $targets) {
        try {
            $r = Invoke-WebRequest -Uri $t.Url -UseBasicParsing -TimeoutSec 3
            if ($r.StatusCode -eq 200) { $ready++ }
        } catch { }
    }
    if ($ready -eq $targets.Count) {
        $allReady = $true
        break
    }
    Start-Sleep -Seconds 5
    Write-Host "  ...$ready/$($targets.Count) services ready"
}

Write-Host ""
docker compose ps

if ($allReady) {
    Write-Host ""
    Write-Host "All core services are up!" -ForegroundColor Green
    Write-Host "  App:        http://localhost:8080"
    Write-Host "  Grafana:    http://localhost:3000  (admin / admin)"
    Write-Host "  Prometheus: http://localhost:9090"
    Write-Host ""
    Write-Host "Trigger test alert: .\scripts\trigger-alert.ps1"
} else {
    Write-Host ""
    Write-Host "Services did not all become ready in time." -ForegroundColor Red
    Write-Host "Run diagnostics: .\scripts\diagnose.ps1"
}

Pop-Location
