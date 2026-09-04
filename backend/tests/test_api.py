"""Single-user API contract tests."""

import pytest
from fastapi.testclient import TestClient

from app.dependencies import get_firestore_service
from app.core import security
from app.main import app
from app.routers import auth
from app.services import reminder_logic
from tests.mocks.firebase_mock import valid_claims


@pytest.fixture
def api_client(fake_service, monkeypatch):
    app.dependency_overrides[get_firestore_service] = lambda: fake_service
    monkeypatch.setattr(auth, "verify_firebase_token", lambda token: valid_claims() if token == "valid-token" else None)
    monkeypatch.setattr(security, "verify_firebase_token", lambda token: valid_claims() if token == "valid-token" else None)
    monkeypatch.setattr(auth, "FirestoreService", lambda: fake_service)
    monkeypatch.setattr(reminder_logic, "get_firestore", lambda: fake_service.client)
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


def auth_headers(client):
    return {"Authorization": "Bearer valid-token"}


def test_auth_returns_uid_and_email_only(api_client):
    login = api_client.post("/auth/firebase-login", json={"id_token": "valid-token"})
    assert login.status_code == 200
    assert set(login.json()) == {"user_id", "email"}
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
    first = api_client.post("/sync/batch", headers=headers, json=payload).json()
    second = api_client.post("/sync/batch", headers=headers, json=payload).json()
    assert first["results"][0]["status"] == "success"
    assert second["results"][0]["status"] == "duplicate"
    assert first["successful_record_ids"] == ["offline-1"]
    assert fake_service.client.collection("journal_entries").document("offline-1").get().to_dict()["user_id"] == "test-user"


def test_sync_returns_partial_results_and_rejects_other_user(api_client, fake_service):
    headers = auth_headers(api_client)
    fake_service.client.collection("journal_entries").document("owned-by-b").set({"user_id": "user-b", "caption": "private"})
    response = api_client.post("/sync/batch", headers=headers, json={"records": [
        {"collection": "journal_entries", "client_generated_id": "good", "data": {"caption": "saved"}},
        {"collection": "unknown", "client_generated_id": "bad-type", "data": {}},
        {"collection": "journal_entries", "client_generated_id": "owned-by-b", "data": {}},
    ]})
    payload = response.json()
    assert response.status_code == 200
    assert [item["status"] for item in payload["results"]] == ["success", "validation_error", "validation_error"]
    assert payload["successful_record_ids"] == ["good"]


def test_reminder_missed_follow_up_and_no_escalation_endpoint(api_client):
    headers = auth_headers(api_client)
    reminder = api_client.post("/reminders", headers=headers, json={"label": "Medicine", "type": "medication", "scheduled_time": "2000-01-01T09:00:00Z"})
    assert reminder.status_code == 200
    check = api_client.get("/reminders/check-due", headers=headers)
    assert check.status_code == 200 and check.json()["reminders"][0]["status"] == "missed"
    assert api_client.post(f"/reminders/{reminder.json()['reminder_id']}/escalate", headers=headers).status_code == 404


def test_sync_operations_update_and_delete(api_client, fake_service):
    headers = auth_headers(api_client)

    # 1. Create a journal entry via sync
    create_payload = {
        "records": [
            {
                "collection": "journal_entries",
                "client_generated_id": "op-entry-1",
                "operation": "create",
                "data": {"title": "Original Title", "body": "Original Body"},
            }
        ]
    }
    res1 = api_client.post("/sync/batch", headers=headers, json=create_payload).json()
    assert res1["results"][0]["status"] == "success"
    doc1 = fake_service.client.collection("journal_entries").document("op-entry-1").get().to_dict()
    assert doc1["title"] == "Original Title"
    assert doc1["deleted"] is False

    # 2. Update the journal entry via sync
    update_payload = {
        "records": [
            {
                "collection": "journal_entries",
                "client_generated_id": "op-entry-1",
                "operation": "update",
                "data": {"title": "Updated Title", "body": "Updated Body"},
            }
        ]
    }
    res2 = api_client.post("/sync/batch", headers=headers, json=update_payload).json()
    assert res2["results"][0]["status"] == "success"
    doc2 = fake_service.client.collection("journal_entries").document("op-entry-1").get().to_dict()
    assert doc2["title"] == "Updated Title"
    assert doc2["body"] == "Updated Body"

    # 3. Soft-delete the journal entry via sync
    delete_payload = {
        "records": [
            {
                "collection": "journal_entries",
                "client_generated_id": "op-entry-1",
                "operation": "delete",
                "data": {},
            }
        ]
    }
    res3 = api_client.post("/sync/batch", headers=headers, json=delete_payload).json()
    assert res3["results"][0]["status"] == "success"
    doc3 = fake_service.client.collection("journal_entries").document("op-entry-1").get().to_dict()
    assert doc3["deleted"] is True


def test_sync_game_attempts(api_client, fake_service):
    headers = auth_headers(api_client)
    payload = {
        "records": [
            {
                "collection": "game_attempts",
                "client_generated_id": "attempt-sync-1",
                "operation": "create",
                "data": {
                    "session_id": "sess-123",
                    "game_id": "recall_my_memories",
                    "round_number": 1,
                    "correct": True,
                    "response_time_ms": 1200,
                    "difficulty_level": 1,
                },
            }
        ]
    }
    res = api_client.post("/sync/batch", headers=headers, json=payload).json()
    assert res["results"][0]["status"] == "success"
    assert "attempt-sync-1" in res["successful_record_ids"]
    stored = fake_service.client.collection("game_attempts").document("attempt-sync-1").get().to_dict()
    assert stored["user_id"] == "test-user"
    assert stored["correct"] is True


def test_pull_endpoints_authenticated_and_isolated(api_client, fake_service):
    headers = auth_headers(api_client)

    # Seed records for test-user and another user
    fake_service.client.collection("journal_entries").document("entry-user-a").set({
        "user_id": "test-user",
        "title": "My Note",
        "body": "User A content",
        "created_at": "2026-01-01T10:00:00Z",
        "updated_at": "2026-01-01T10:00:00Z",
        "deleted": False,
    })
    fake_service.client.collection("journal_entries").document("entry-user-b").set({
        "user_id": "other-user",
        "title": "Other Note",
        "body": "User B secret",
        "created_at": "2026-01-01T10:00:00Z",
        "updated_at": "2026-01-01T10:00:00Z",
        "deleted": False,
    })

    # Pull journal-entries for test-user
    resp = api_client.get("/sync/journal-entries", headers=headers)
    assert resp.status_code == 200
    items = resp.json()["items"]
    assert len(items) == 1
    assert items[0]["id"] == "entry-user-a"
    assert items[0]["title"] == "My Note"

    # Test generic collection pull
    generic_resp = api_client.get("/sync/journal_entries", headers=headers)
    assert generic_resp.status_code == 200
    assert generic_resp.json()["count"] == 1


def test_readiness_endpoint(api_client):
    resp = api_client.get("/ready")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ready"
    assert data["service"] == "smriti-ai"

