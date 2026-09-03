"""Automated checks for the single-user API surface."""

from fastapi.testclient import TestClient

from app.main import app


def test_public_catalog_exposes_personal_recall_game():
    response = TestClient(app).get("/games")
    assert response.status_code == 200
    assert "recall_my_memories" in {game["code"] for game in response.json()}


def test_protected_routes_require_authentication():
    client = TestClient(app)
    assert client.get("/journal/entries").status_code in {401, 503}
    assert client.post("/sync", json={"records": []}).status_code in {401, 503}
    assert client.get("/reminders").status_code in {401, 503}
