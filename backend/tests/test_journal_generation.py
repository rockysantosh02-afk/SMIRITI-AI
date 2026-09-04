"""Tests for journal AI generation and conservative content guarding."""

from datetime import datetime, timezone

from app.services import content_guard, reminder_logic
from app.services.story_generator import (
    generate_journal_story,
    generate_recall_quiz,
    generate_story_from_memory,
)
from tests.mocks.firestore_mock import FakeFirestore


def test_generate_story_from_memory_valid(monkeypatch):
    monkeypatch.setattr("app.services.story_generator.settings.GEMINI_API_KEY", "")

    story = generate_story_from_memory(
        title="Walk near Brahmaputra",
        content="The morning breeze was cool and the water was calm.",
        language="English",
    )

    assert "Walk near Brahmaputra" in story or "brahmaputra" in story.lower()
    assert "memory" in story.lower() or "peace" in story.lower()


def test_generate_story_from_memory_assamese(monkeypatch):
    monkeypatch.setattr("app.services.story_generator.settings.GEMINI_API_KEY", "")

    story = generate_story_from_memory(
        title="বিহু উৎসৱ",
        content="পৰিয়ালৰ সকলো একেলগে আছিলো।",
        language="Assamese",
    )

    assert "স্মৃতি" in story
    assert "আনন্দ" in story or "শান্তি" in story


def test_generate_story_from_memory_empty(monkeypatch):
    monkeypatch.setattr("app.services.story_generator.settings.GEMINI_API_KEY", "")

    story = generate_story_from_memory(None, None, language="English")
    assert story
    assert len(story) > 10


def test_generate_story_gemini_failure_uses_fallback(monkeypatch):
    monkeypatch.setattr("app.services.story_generator.settings.GEMINI_API_KEY", "fake-api-key")

    class FailingModel:
        def generate_content(self, prompt):
            raise RuntimeError("Gemini API connection error")

    class FakeGenAI:
        def configure(self, api_key):
            pass
        def GenerativeModel(self, name):
            return FailingModel()

    import sys
    monkeypatch.setitem(sys.modules, "google.generativeai", FakeGenAI())

    story = generate_story_from_memory(
        title="Tea Garden Walk",
        content="Smelled fresh green leaves.",
        language="English",
    )
    assert "Tea Garden Walk" in story
    assert "gentle warmth" in story


def test_generate_story_content_guard_blocks_distressing_ai_output(monkeypatch):
    monkeypatch.setattr("app.services.story_generator.settings.GEMINI_API_KEY", "fake-api-key")

    class UnsafeModel:
        def generate_content(self, prompt):
            class Resp:
                text = "This story mentions illness and death and funeral at hospital."
            return Resp()

    class FakeGenAI:
        def configure(self, api_key):
            pass
        def GenerativeModel(self, name):
            return UnsafeModel()

    import sys
    monkeypatch.setitem(sys.modules, "google.generativeai", FakeGenAI())

    story = generate_story_from_memory(
        title="Hospital visit",
        content="Worrying news.",
        language="English",
    )
    # The unsafe output must be blocked by passes_content_guard and safe fallback returned
    assert "illness" not in story
    assert "death" not in story
    assert "funeral" not in story
    assert "precious part of our journey" in story or "gentle warmth and peace" in story


def test_api_generate_story_endpoint():
    from fastapi.testclient import TestClient
    from app.main import app
    from app.core.dependencies import get_current_user

    app.dependency_overrides[get_current_user] = lambda: {"uid": "test-user"}
    try:
        client = TestClient(app)
        response = client.post(
            "/journal/generate-story",
            headers={"Authorization": "Bearer valid-token"},
            json={
                "title": "Evening Tea with Family",
                "content": "We sat together on the veranda drinking warm chai.",
                "language": "English",
            },
        )
        assert response.status_code == 200
        data = response.json()
        assert "story" in data
        assert len(data["story"]) > 10
    finally:
        app.dependency_overrides.pop(get_current_user, None)


def test_journal_story_prompt_fallback_uses_journal_fields(monkeypatch):
    monkeypatch.setattr("app.services.story_generator.settings.GEMINI_API_KEY", "")

    story = generate_journal_story("A quiet walk", "the garden", "Sunday", "English")

    assert "A quiet walk" in story
    assert "the garden" in story
    assert "Sunday" in story


def test_recall_quiz_uses_entry_tags():
    quiz = generate_recall_quiz([
        {"tag_place": "the garden", "tag_occasion": "Sunday", "tag_object": "camera"},
        {"tag_place": "the market", "tag_occasion": "festival"},
    ])

    assert quiz
    assert any(item["expected_answer"] == "the garden" for item in quiz)
    assert any("the market" in item["options"] for item in quiz if item["prompt"] == "What did you call this place?")


def test_content_guard_returns_reason_for_distress_and_length():
    assert content_guard.passes_content_guard("A happy garden visit.") == (True, "")
    assert content_guard.passes_content_guard("This mentions death.")[0] is False
    assert content_guard.passes_content_guard("word " * 81)[1]


def test_missed_reminder_updates_status_without_alert_collection(monkeypatch):
    client = FakeFirestore()
    client.collection("reminders").document("reminder-1").set({
        "user_id": "user-a",
        "status": "active",
        "scheduled_time": datetime.now(timezone.utc),
    })
    monkeypatch.setattr(reminder_logic, "get_firestore", lambda: client)

    result = reminder_logic.process_missed_reminder({"id": "reminder-1", "user_id": "user-a"})
    stored = client.collection("reminders").document("reminder-1").get().to_dict()

    assert result["follow_up_message"]
    assert stored["status"] == "missed"
    assert stored["follow_up_message"] == result["follow_up_message"]
    assert list(client.collection("alerts").stream()) == []
