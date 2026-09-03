"""Credential-free integration smoke tests for the public API surface."""


def test_health_check(test_client) -> None:
    response = test_client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_auth_flow(test_client, test_user) -> None:
    response = test_client.post("/auth/firebase-login", json={"id_token": "invalid"})
    assert response.status_code in {401, 503}
    assert "role" not in test_user


def test_game_session_flow(test_client, test_patient, test_user) -> None:
    assert test_client.get("/games").status_code == 200
    assert test_patient["user_id"] == test_user["uid"]
    assert test_client.post("/games/session", json={"game_code": "matching_image"}).status_code in {401, 503}


def test_memory_flow(test_client, test_patient) -> None:
    response = test_client.post("/journal/entries", json={"photo_url": "photo.jpg", "caption": "Test entry"})
    assert response.status_code in {401, 503}


def test_reminder_flow(test_client, test_patient) -> None:
    response = test_client.post("/reminders", json={"label": "Medication", "type": "medication", "scheduled_time": "2030-01-01T09:00:00Z"})
    assert response.status_code in {401, 503}


def test_security_rules(test_client) -> None:
    response = test_client.get("/auth/me")
    assert response.status_code == 401
    assert response.json()["code"] in {"401", "unauthorized"}


def test_swagger_contains_all_router_groups(test_client) -> None:
    paths = test_client.get("/openapi.json").json()["paths"]
    assert any(path.startswith("/auth") for path in paths)
    assert any(path.startswith("/games") for path in paths)
    assert any(path.startswith("/journal") for path in paths)
    assert any(path.startswith("/sync") for path in paths)
    assert any(path.startswith("/reminders") for path in paths)
