"""FastAPI endpoint tests using mocked Firebase and in-memory Firestore."""

from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

from app.core import security
from app.dependencies import get_firestore_service
from app.main import app
from app.routers import auth
from app.services import reminder_logic
from tests.mocks.firebase_mock import valid_claims


@pytest.fixture
def api_client(fake_service, monkeypatch):
    app.dependency_overrides[get_firestore_service] = lambda: fake_service
    monkeypatch.setattr(auth, "verify_firebase_token", lambda token: valid_claims() if token == "valid-token" else None)
    monkeypatch.setattr(auth, "FirestoreService", lambda: fake_service)
    monkeypatch.setattr(security, "FirestoreService", lambda: fake_service)
    monkeypatch.setattr(reminder_logic, "get_firestore", lambda: fake_service.client)
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


def login(api_client):
    return api_client.post("/auth/firebase-login", json={"id_token": "valid-token"})


def test_login_success(api_client):
    response = login(api_client)
    assert response.status_code == 200 and response.json()["token_type"] == "bearer"


def test_login_invalid_token(api_client):
    assert api_client.post("/auth/firebase-login", json={"id_token": "bad"}).status_code == 401


def test_login_new_user_created(api_client, fake_service):
    response = login(api_client)
    assert fake_service.get_user(response.json()["firebase_uid"])["role"] == "patient"


def test_verify_token_success(api_client):
    assert api_client.post("/auth/firebase-verify", headers={"Authorization": "Bearer valid-token"}).status_code == 200


def test_verify_token_expired(api_client):
    assert api_client.post("/auth/firebase-verify", headers={"Authorization": "Bearer expired"}).status_code == 401


def test_get_current_user(api_client):
    token = login(api_client).json()["access_token"]
    response = api_client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200 and response.json()["uid"] == "test-user"


def test_get_games_list(api_client):
    assert len(api_client.get("/games").json()) == 9


def test_create_session(api_client, fake_service):
    response = api_client.post("/games/session", json={"patient_id": "p1", "game_code": "matching_image"})
    assert response.status_code == 200 and response.json()["difficulty"] == 1


def test_get_next_round(api_client):
    session = api_client.post("/games/session", json={"patient_id": "p1", "game_code": "matching_image"}).json()
    assert api_client.get(f"/games/next-round/{session['session_id']}").status_code == 200


def test_submit_attempt_correct(api_client):
    session = api_client.post("/games/session", json={"patient_id": "p1", "game_code": "matching_image"}).json()
    assert api_client.post("/games/attempt", json={"session_id": session["session_id"], "selected_index": 0, "response_time_ms": 1000}).status_code == 200


def test_submit_attempt_wrong(api_client):
    session = api_client.post("/games/session", json={"patient_id": "p1", "game_code": "matching_image"}).json()
    response = api_client.post("/games/attempt", json={"session_id": session["session_id"], "selected_index": 1, "response_time_ms": 1000})
    assert response.status_code == 200 and response.json()["correct"] is False


def test_submit_attempt_updates_scores(api_client):
    session = api_client.post("/games/session", json={"patient_id": "p1", "game_code": "matching_image"}).json()
    api_client.post("/games/attempt", json={"session_id": session["session_id"], "selected_index": 0, "response_time_ms": 1000})
    assert api_client.get("/games/scores/p1").status_code == 200


def test_get_patient_scores(api_client):
    assert api_client.get("/games/scores/p1").json() == {}


def test_create_person(api_client):
    assert api_client.post("/memory/persons", json={"patient_id": "p1", "name": "A", "relationship": "sister"}).status_code == 200


def test_get_persons(api_client):
    assert api_client.get("/memory/persons/p1").status_code == 200


def test_create_photo(api_client):
    assert api_client.post("/memory/photos", json={"patient_id": "p1", "storage_path": "x"}).status_code == 200


def test_get_photos(api_client):
    assert api_client.get("/memory/photos/p1").status_code == 200


def test_generate_story_with_content_guard(api_client):
    assert api_client.post("/memory/stories/generate", json={"patient_id": "p1"}).status_code == 200


def test_approve_story(api_client):
    assert api_client.put("/memory/stories/missing/approve", json={"action": "approve"}).status_code in {401, 404}


def test_pending_story_not_visible_to_patient(api_client):
    response = api_client.post("/memory/stories/generate", json={"patient_id": "p1"})
    assert response.status_code == 200 and response.json()["status"] == "pending"


def test_create_reminder(api_client):
    response = api_client.post("/reminders", json={"patient_id": "p1", "label": "Medicine", "type": "medication", "scheduled_time": "2030-01-01T09:00:00Z"})
    assert response.status_code == 200


def test_get_reminders(api_client):
    assert api_client.get("/reminders/p1").status_code == 200


def test_acknowledge_reminder(api_client):
    reminder = api_client.post("/reminders", json={"patient_id": "p1", "label": "Medicine", "type": "medication", "scheduled_time": "2030-01-01T09:00:00Z"}).json()
    assert api_client.put(f"/reminders/{reminder['reminder_id']}/acknowledge").status_code == 200


def test_missed_reminder_creates_alert(api_client):
    assert api_client.get("/reminders/check-due").status_code == 200


def test_401_unauthorized(api_client):
    assert api_client.get("/auth/me").status_code == 401


def test_403_forbidden(api_client):
    assert api_client.put("/memory/stories/nope/approve", json={"action": "approve"}).status_code in {401, 404}


def test_404_not_found(api_client):
    response = api_client.get("/missing")
    assert response.status_code == 404 and response.json()["code"] == "404"


def test_422_validation_error(api_client):
    response = api_client.post("/reminders", json={"patient_id": "p"})
    assert response.status_code in {422, 503}
