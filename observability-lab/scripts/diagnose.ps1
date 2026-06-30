# Diagnose why localhost services are not reachable.
$ErrorActionPreference = "Continue"

Write-Host "=== DevOps Observability Lab - Diagnostics ===" -ForegroundColor Cyan
Write-Host ""

# 1. Docker CLI
Write-Host "[1/5] Docker installed and running?" -ForegroundColor Yellow
try {
    $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
    if ($LASTEXITCODE -eq 0 -and $dockerVersion) {
        Write-Host "  OK - Docker server version: $dockerVersion" -ForegroundColor Green
    } else {
        Write-Host "  FAIL - Docker is not running." -ForegroundColor Red
        Write-Host "  Fix: Open Docker Desktop and wait until it shows 'Running'." -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host "  FAIL - Docker not found. Install Docker Desktop for Windows." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/5] Compose services status" -ForegroundColor Yellow
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
docker compose ps -a
Pop-Location

Write-Host ""
Write-Host "[3/5] Port listeners (8080 app, 3000 grafana, 9090 prometheus)" -ForegroundColor Yellow
$ports = @(8080, 3000, 9090, 9093, 3100)
foreach ($port in $ports) {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) {
        Write-Host "  OK - Port $port is listening" -ForegroundColor Green
    } else {
        Write-Host "  -- - Port $port is NOT listening" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[4/5] HTTP health checks" -ForegroundColor Yellow
$endpoints = @(
    @{ Name = "App";        Url = "http://localhost:8080/health" },
    @{ Name = "Grafana";    Url = "http://localhost:3000/api/health" },
    @{ Name = "Prometheus"; Url = "http://localhost:9090/-/healthy" },
    @{ Name = "Loki";       Url = "http://localhost:3100/ready" }
)
foreach ($ep in $endpoints) {
    try {
        $r = Invoke-WebRequest -Uri $ep.Url -UseBasicParsing -TimeoutSec 5
        Write-Host "  OK - $($ep.Name) ($($ep.Url)) -> $($r.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "  FAIL - $($ep.Name) ($($ep.Url))" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[5/5] Recent container errors (last 20 lines per service)" -ForegroundColor Yellow
Push-Location $projectRoot
foreach ($svc in @("app", "grafana", "prometheus", "loki", "promtail")) {
    Write-Host "--- logs: $svc ---" -ForegroundColor DarkGray
    docker compose logs --tail=20 $svc 2>$null
}
Pop-Location

Write-Host ""
Write-Host "=== Next steps ===" -ForegroundColor Cyan
Write-Host "If ports are not listening, run from project root:"
Write-Host "  docker compose down"
Write-Host "  docker compose up -d --build"
Write-Host ""
Write-Host "Then wait 60 seconds and run this script again:"
Write-Host "  .\scripts\diagnose.ps1"
