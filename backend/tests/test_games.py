"""Public games API tests."""

from fastapi.testclient import TestClient

from app.main import app


def test_game_catalog_is_public_and_complete() -> None:
    response = TestClient(app).get("/games")
    assert response.status_code == 200
    games = response.json()
    assert len(games) == 9
    assert {game["code"] for game in games} >= {"matching_image", "family_quiz", "number_compare"}


def test_game_routes_are_documented() -> None:
    paths = TestClient(app).get("/openapi.json").json()["paths"]
    assert {"/games", "/games/session", "/games/attempt", "/games/scores/{patient_id}"}.issubset(paths)
