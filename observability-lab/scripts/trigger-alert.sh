#!/usr/bin/env bash
# Simulates traffic and triggers the CRITICAL error-rate alert (>5 errors/min).
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"

echo "Generating normal traffic..."
for _ in $(seq 1 20); do
  curl -s "$BASE_URL/work" > /dev/null
  sleep 0.2
done

echo "Bursting errors to exceed the 5/min threshold..."
curl -s "$BASE_URL/burst-errors?count=10"

echo ""
echo "Done. Check alerts at:"
echo "  Prometheus:    http://localhost:9090/alerts"
echo "  Alertmanager:  http://localhost:9093"
echo "  Grafana:       http://localhost:3000/alerting/list (admin/admin)"
