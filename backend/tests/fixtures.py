"""Reusable integration-test fixtures."""

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def test_client() -> TestClient:
    """Return an isolated FastAPI test client."""
    with TestClient(app) as client:
        yield client


@pytest.fixture
def test_user() -> dict[str, str]:
    return {"uid": "integration-user", "email": "test@example.com"}


@pytest.fixture
def test_patient() -> dict[str, str]:
    return {"user_id": "integration-user"}
