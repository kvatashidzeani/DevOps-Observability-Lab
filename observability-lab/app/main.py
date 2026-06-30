import logging
import os
import random
import sys
import time
from datetime import datetime, timezone

from flask import Flask, jsonify, request
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from pythonjsonlogger.json import JsonFormatter

app = Flask(__name__)

REQUESTS_TOTAL = Counter(
    "app_requests_total",
    "Total number of HTTP requests handled by the application",
    ["method", "endpoint", "status"],
)
ERRORS_TOTAL = Counter(
    "app_errors_total",
    "Total number of application errors",
    ["error_type"],
)


def setup_json_logging() -> None:
    handler = logging.StreamHandler(sys.stdout)
    formatter = JsonFormatter(
        fmt="%(asctime)s %(levelname)s %(name)s %(message)s",
        rename_fields={"asctime": "timestamp", "levelname": "level"},
    )
    handler.setFormatter(formatter)

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(logging.INFO)

    app.logger.handlers.clear()
    app.logger.propagate = True


setup_json_logging()
logger = logging.getLogger("observability-app")


@app.before_request
def log_request_start() -> None:
    request.start_time = time.time()


@app.after_request
def log_and_count_request(response):
    duration_ms = round((time.time() - request.start_time) * 1000, 2)
    endpoint = request.endpoint or "unknown"
    status = str(response.status_code)

    REQUESTS_TOTAL.labels(
        method=request.method,
        endpoint=endpoint,
        status=status,
    ).inc()

    log_data = {
        "event": "http_request",
        "method": request.method,
        "path": request.path,
        "endpoint": endpoint,
        "status_code": response.status_code,
        "duration_ms": duration_ms,
        "client_ip": request.remote_addr,
    }

    if response.status_code >= 500:
        logger.error("Request completed with server error", extra=log_data)
    elif response.status_code >= 400:
        logger.warning("Request completed with client error", extra=log_data)
    else:
        logger.info("Request completed", extra=log_data)

    return response


@app.route("/")
def index():
    return jsonify(
        {
            "service": "observability-lab-app",
            "status": "running",
            "endpoints": {
                "health": "/health",
                "metrics": "/metrics",
                "simulate_error": "/error",
                "burst_errors": "/burst-errors?count=10",
            },
        }
    )


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()})


@app.route("/work")
def work():
    """Simulates normal traffic."""
    delay = random.uniform(0.01, 0.15)
    time.sleep(delay)
    return jsonify({"status": "ok", "delay_ms": round(delay * 1000, 2)})


@app.route("/error")
def simulate_error():
    error_type = random.choice(["validation", "timeout", "upstream"])
    ERRORS_TOTAL.labels(error_type=error_type).inc()
    logger.error(
        "Simulated application error",
        extra={
            "event": "application_error",
            "error_type": error_type,
            "path": request.path,
            "severity": "error",
        },
    )
    return jsonify({"status": "error", "error_type": error_type}), 500


@app.route("/burst-errors")
def burst_errors():
    """Generate multiple errors quickly to trigger the CRITICAL alert."""
    count = request.args.get("count", default=10, type=int)
    count = max(1, min(count, 100))

    for _ in range(count):
        error_type = random.choice(["validation", "timeout", "upstream"])
        ERRORS_TOTAL.labels(error_type=error_type).inc()
        logger.error(
            "Burst simulated error",
            extra={
                "event": "application_error",
                "error_type": error_type,
                "path": request.path,
                "severity": "critical",
            },
        )

    return jsonify({"status": "errors_generated", "count": count})


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
