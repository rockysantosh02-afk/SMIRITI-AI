"""Single-user API contract tests."""

import pytest
from fastapi.testclient import TestClient

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
    monkeypatch.setattr(reminder_logic, "get_firestore", lambda: fake_service.client)
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


def auth_headers(client):
    token = client.post("/auth/firebase-login", json={"id_token": "valid-token"}).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_auth_returns_uid_and_email_only(api_client):
    login = api_client.post("/auth/firebase-login", json={"id_token": "valid-token"})
    assert login.status_code == 200
    assert set(login.json()) == {"access_token", "token_type", "user_id"}
    verified = api_client.post("/auth/firebase-verify", headers={"Authorization": "Bearer valid-token"})
    assert verified.json()["user"] == {"uid": "test-user", "email": "test@example.com"}


def test_journal_entry_and_story(api_client):
    headers = auth_headers(api_client)
    entry = api_client.post("/journal/entries", headers=headers, json={"photo_url": "photo.jpg", "caption": "A garden walk", "tag_place": "garden", "tag_occasion": "Sunday"})
    assert entry.status_code == 200
    entry_id = entry.json()["entry_id"]
    assert api_client.get("/journal/entries", headers=headers).json()[0]["user_id"] == "test-user"
    story = api_client.post("/journal/stories/generate", headers=headers, json={"entry_ids": [entry_id]})
    assert story.status_code == 200 and story.json()["story_id"]


def test_game_session_uses_token_uid(api_client, fake_service):
    headers = auth_headers(api_client)
    session = api_client.post("/games/sessions", headers=headers, json={"game_code": "recall_my_memories"})
    assert session.status_code == 200
    stored = fake_service.client.collection("game_sessions").document(session.json()["session_id"]).get().to_dict()
    assert stored["user_id"] == "test-user"
    assert "patient_id" not in stored


def test_sync_is_idempotent_and_user_owned(api_client, fake_service):
    headers = auth_headers(api_client)
    payload = {"records": [{"collection": "journal_entries", "client_generated_id": "offline-1", "data": {"caption": "Offline note"}}]}
    assert api_client.post("/sync", headers=headers, json=payload).json() == {"synced": ["offline-1"]}
    assert api_client.post("/sync", headers=headers, json=payload).json() == {"synced": ["offline-1"]}
    assert fake_service.client.collection("journal_entries").document("offline-1").get().to_dict()["user_id"] == "test-user"


def test_reminder_missed_follow_up_and_no_escalation_endpoint(api_client):
    headers = auth_headers(api_client)
    reminder = api_client.post("/reminders", headers=headers, json={"label": "Medicine", "type": "medication", "scheduled_time": "2000-01-01T09:00:00Z"})
    assert reminder.status_code == 200
    check = api_client.get("/reminders/check-due", headers=headers)
    assert check.status_code == 200 and check.json()["reminders"][0]["status"] == "missed"
    assert api_client.post(f"/reminders/{reminder.json()['reminder_id']}/escalate", headers=headers).status_code == 404
