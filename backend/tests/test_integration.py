"""Credential-free integration smoke tests for the public API surface."""


def test_health_check(test_client) -> None:
    response = test_client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_auth_flow(test_client, test_user) -> None:
    response = test_client.post("/auth/firebase-login", json={"id_token": "invalid"})
    assert response.status_code in {401, 503}
    assert test_user["role"] == "patient"


def test_game_session_flow(test_client, test_patient) -> None:
    assert test_client.get("/games").status_code == 200
    response = test_client.post("/games/session", json={"patient_id": test_patient["patient_id"], "game_code": "matching_image"})
    assert response.status_code in {200, 503}


def test_memory_flow(test_client, test_patient) -> None:
    response = test_client.post("/memory/persons", json={"patient_id": test_patient["patient_id"], "name": "Test Person", "relationship": "friend"})
    assert response.status_code in {200, 503}


def test_reminder_flow(test_client, test_patient) -> None:
    response = test_client.post("/reminders", json={"patient_id": test_patient["patient_id"], "label": "Medication", "type": "medication", "scheduled_time": "2030-01-01T09:00:00Z"})
    assert response.status_code in {200, 503}


def test_security_rules(test_client) -> None:
    response = test_client.get("/auth/me")
    assert response.status_code == 401
    assert response.json()["code"] in {"401", "unauthorized"}


def test_swagger_contains_all_router_groups(test_client) -> None:
    paths = test_client.get("/openapi.json").json()["paths"]
    assert any(path.startswith("/auth") for path in paths)
    assert any(path.startswith("/games") for path in paths)
    assert any(path.startswith("/memory") for path in paths)
    assert any(path.startswith("/reminders") for path in paths)
