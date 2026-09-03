"""Tests for journal AI generation and conservative content guarding."""

from datetime import datetime, timezone

from app.services import content_guard, reminder_logic
from app.services.story_generator import generate_journal_story, generate_recall_quiz
from tests.mocks.firestore_mock import FakeFirestore


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
