from app import create_app


def test_health_endpoint():
    app = create_app()
    client = app.test_client()

    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "ok"


def test_dynamic_route():
    app = create_app()
    client = app.test_client()

    response = client.get("/hello/Ani")
    assert response.status_code == 200
    payload = response.get_json()
    assert payload["message"] == "Hello, Ani!"
    assert "timestamp" in payload


def test_submit_form_success():
    app = create_app()
    client = app.test_client()

    response = client.post("/submit", data={"name": "Ani", "task": "Deploy app"})
    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "success"


def test_submit_form_validation():
    app = create_app()
    client = app.test_client()

    response = client.post("/submit", data={"name": "", "task": ""})
    assert response.status_code == 400
    assert response.get_json()["status"] == "error"
