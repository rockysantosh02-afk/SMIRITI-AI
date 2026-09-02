"""FastAPI authentication route tests that do not require Firebase credentials."""

from fastapi.testclient import TestClient

from app.main import app


def test_auth_routes_are_registered() -> None:
    client = TestClient(app)
    paths = client.get("/openapi.json").json()["paths"]
    assert "/auth/firebase-login" in paths
    assert "/auth/firebase-verify" in paths
    assert "/auth/logout" in paths
    assert "/auth/me" in paths


def test_logout_is_stateless() -> None:
    response = TestClient(app).post("/auth/logout")
    assert response.status_code == 200
    assert response.json()["status"] == "success"


def test_missing_bearer_token_is_unauthorized() -> None:
    response = TestClient(app).get("/auth/me")
    assert response.status_code == 401
    assert response.json()["code"] in {"401", "unauthorized"}
