"""Memory Vault safety and route tests."""

from fastapi.testclient import TestClient

from app.main import app
from app.services.content_guard import guard_content, is_safe_content


def test_content_guard_allows_safe_text() -> None:
    assert is_safe_content("A warm family memory")
    assert guard_content("A warm family memory") == "A warm family memory"


def test_content_guard_blocks_unsafe_text() -> None:
    assert not is_safe_content("A violent memory")
    try:
        guard_content("A violent memory")
    except ValueError as exc:
        assert "blocked" in str(exc)
    else:
        raise AssertionError("unsafe content was not blocked")


def test_memory_routes_are_documented() -> None:
    paths = TestClient(app).get("/openapi.json").json()["paths"]
    assert "/memory/persons" in paths
    assert "/memory/stories/generate" in paths
    assert "/memory/stories/{story_id}/approve" in paths
