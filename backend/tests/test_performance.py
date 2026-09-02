"""Lightweight response-time checks; marked load tests are opt-in."""

import time

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.dependencies import get_firestore_service


def timed(client, method, path, **kwargs):
    started = time.perf_counter()
    response = getattr(client, method)(path, **kwargs)
    return response, (time.perf_counter() - started) * 1000


def test_root_endpoint_under_50ms():
    response, elapsed = timed(TestClient(app), "get", "/")
    assert response.status_code == 200 and elapsed < 50


def test_health_check_under_50ms():
    response, elapsed = timed(TestClient(app), "get", "/health")
    assert response.status_code == 200 and elapsed < 50


def test_get_games_under_100ms():
    response, elapsed = timed(TestClient(app), "get", "/games")
    assert response.status_code == 200 and elapsed < 100


@pytest.mark.parametrize("name", ["test_next_round_under_200ms", "test_submit_attempt_under_300ms", "test_cognitive_scores_under_200ms"])
def test_performance_placeholders(name):
    pytest.skip("Requires a live or injected Firestore session fixture")


@pytest.mark.slow
@pytest.mark.parametrize("count", [10, 50])
def test_concurrent_read_requests(count):
    pytest.skip("Run load tests with Locust for concurrency measurement")


def test_10_concurrent_game_requests():
    pytest.skip("Run load tests with Locust for concurrency measurement")


def test_50_concurrent_read_requests():
    pytest.skip("Run load tests with Locust for concurrency measurement")


def test_batch_reminder_processing():
    pytest.skip("Requires a live Firestore fixture")


def test_patient_query_efficient():
    pytest.skip("Requires Firestore emulator profiling")


def test_scores_query_efficient():
    pytest.skip("Requires Firestore emulator profiling")


def test_alerts_query_efficient():
    pytest.skip("Requires Firestore emulator profiling")
