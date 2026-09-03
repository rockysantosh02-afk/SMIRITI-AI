"""Public games API tests."""

from fastapi.testclient import TestClient

from app.main import app


def test_game_catalog_is_public_and_complete() -> None:
    response = TestClient(app).get("/games")
    assert response.status_code == 200
    games = response.json()
    assert len(games) == 9
    assert {game["code"] for game in games} >= {"matching_image", "recall_my_memories", "number_compare"}


def test_game_routes_are_documented() -> None:
    paths = TestClient(app).get("/openapi.json").json()["paths"]
    assert {"/games", "/games/session", "/games/sessions", "/games/next-round/{session_id}", "/games/attempt", "/games/scores", "/journal/entries", "/sync", "/test/setup", "/test/create-session/{game_code}"}.issubset(paths)
