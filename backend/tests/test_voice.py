"""Tests for Voice Assistant conversational chat endpoint."""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_voice_chat_english_fallback(monkeypatch):
    monkeypatch.setattr("app.routers.voice.settings.GEMINI_API_KEY", None)

    response = client.post(
        "/voice/chat",
        json={
            "message": "How are you doing today?",
            "language": "en-US",
            "history": [],
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert len(data["response"]) > 5
    assert "doing well" in data["response"].lower() or "pleasure" in data["response"].lower() or "glad" in data["response"].lower()


def test_voice_chat_telugu_fallback(monkeypatch):
    monkeypatch.setattr("app.routers.voice.settings.GEMINI_API_KEY", None)

    response = client.post(
        "/voice/chat",
        json={
            "message": "ఎలా ఉన్నారు?",
            "language": "te-IN",
            "history": [],
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert "బాగున్నాను" in data["response"] or "సంతోషంగా" in data["response"]


def test_voice_chat_hindi_fallback(monkeypatch):
    monkeypatch.setattr("app.routers.voice.settings.GEMINI_API_KEY", None)

    response = client.post(
        "/voice/chat",
        json={
            "message": "आप कैसे हो?",
            "language": "hi-IN",
            "history": [],
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert "ठीक" in data["response"] or "खुशी" in data["response"]


def test_voice_chat_with_history(monkeypatch):
    monkeypatch.setattr("app.routers.voice.settings.GEMINI_API_KEY", None)

    history = [
        {"role": "user", "content": "I went to the garden earlier."},
        {"role": "assistant", "content": "Gardens are very peaceful."},
    ]

    response = client.post(
        "/voice/chat",
        json={
            "message": "Thank you very much.",
            "language": "en-US",
            "history": history,
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert len(data["response"]) > 0


def test_voice_chat_empty_message():
    response = client.post(
        "/voice/chat",
        json={
            "message": "   ",
            "language": "en-US",
            "history": [],
        },
    )
    assert response.status_code == 422


def test_voice_chat_invalid_payload():
    response = client.post(
        "/voice/chat",
        json={"wrong_field": 123},
    )
    assert response.status_code == 422


def test_voice_chat_gemini_mock(monkeypatch):
    monkeypatch.setattr("app.routers.voice.settings.GEMINI_API_KEY", "mock-test-key")

    class MockCandidate:
        text = "Hello! It is wonderful to talk with you today. The sun is shining brightly."

    class MockModel:
        def generate_content(self, prompt):
            return MockCandidate()

    class MockGenAI:
        def configure(self, api_key):
            pass

        def GenerativeModel(self, name):
            return MockModel()

    import sys
    monkeypatch.setitem(sys.modules, "google.generativeai", MockGenAI())

    response = client.post(
        "/voice/chat",
        json={
            "message": "Hello Smriti",
            "language": "en-US",
            "history": [],
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert "wonderful to talk with you" in data["response"]


def test_voice_chat_gemini_failure_falls_back(monkeypatch):
    monkeypatch.setattr("app.routers.voice.settings.GEMINI_API_KEY", "mock-test-key")

    class FailingModel:
        def generate_content(self, prompt):
            raise RuntimeError("API quota exceeded")

    class MockGenAI:
        def configure(self, api_key):
            pass

        def GenerativeModel(self, name):
            return FailingModel()

    import sys
    monkeypatch.setitem(sys.modules, "google.generativeai", MockGenAI())

    response = client.post(
        "/voice/chat",
        json={
            "message": "Hello Smriti",
            "language": "en-US",
            "history": [],
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert len(data["response"]) > 0
    assert "Smriti" in data["response"] or "companion" in data["response"]
