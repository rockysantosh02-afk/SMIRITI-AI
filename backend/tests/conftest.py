"""Shared pytest fixtures for backend tests."""

pytest_plugins = ("tests.fixtures",)

import pytest
from app.core.firestore_service import FirestoreService
from tests.mocks.firestore_mock import FakeFirestore

from core_logic.adaptive_difficulty import AdaptiveDifficultyEngine


@pytest.fixture
def engine() -> AdaptiveDifficultyEngine:
    """Return a fresh in-memory adaptive difficulty engine."""
    return AdaptiveDifficultyEngine()


@pytest.fixture
def sequence_factory():
    """Return a factory that creates independent engine instances."""
    return AdaptiveDifficultyEngine


@pytest.fixture
def fake_service():
    """Return a Firestore service backed by an isolated in-memory store."""
    return FirestoreService(client=FakeFirestore())
