# Simulates traffic and triggers the CRITICAL error-rate alert (>5 errors/min).
$baseUrl = "http://localhost:8080"

function Test-AppReady {
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/health" -Method Get -TimeoutSec 5 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

if (-not (Test-AppReady)) {
    Write-Host "ERROR: Cannot reach the app at $baseUrl" -ForegroundColor Red
    Write-Host ""
    Write-Host "Start the stack first (from the project root):"
    Write-Host "  docker compose up -d --build"
    Write-Host ""
    Write-Host "Then verify containers are running:"
    Write-Host "  docker compose ps"
    Write-Host ""
    Write-Host "And test the app directly:"
    Write-Host "  Invoke-RestMethod http://localhost:8080/health"
    exit 1
}

Write-Host "Generating normal traffic..."
1..20 | ForEach-Object {
    Invoke-RestMethod -Uri "$baseUrl/work" -Method Get | Out-Null
    Start-Sleep -Milliseconds 200
}

Write-Host "Bursting errors to exceed the 5/min threshold..."
Invoke-RestMethod -Uri "$baseUrl/burst-errors?count=10" -Method Get

Write-Host ""
Write-Host "Done. Check alerts at:"
Write-Host "  Prometheus:    http://localhost:9090/alerts"
Write-Host "  Alertmanager:  http://localhost:9093"
Write-Host "  Grafana:       http://localhost:3000/alerting/list (admin/admin)"
