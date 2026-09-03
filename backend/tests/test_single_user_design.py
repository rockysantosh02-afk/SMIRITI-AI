"""Focused tests for single-user ownership and journal-backed games."""

from core_logic.game_engine import get_next_round


def test_recall_my_memories_uses_owned_journal_entry():
    round_data = get_next_round(
        "recall_my_memories",
        1,
        {"entries": [{"caption": "my garden visit", "tag_object": "camera"}]},
    )

    assert round_data["memory_generated"] is True
    assert round_data["expected_answer"] == "camera"
    assert round_data["game_code"] == "recall_my_memories"


def test_recall_my_memories_falls_back_without_journal_entries():
    round_data = get_next_round("recall_my_memories", 1, {"entries": []})

    assert round_data["memory_generated"] is False
    assert round_data["prompt"]
    assert round_data["options"]


def test_user_scores_are_isolated(fake_service):
    fake_service.update_cognitive_score("user-a", "recall", {"accuracy": 1.0})
    fake_service.update_cognitive_score("user-b", "recall", {"accuracy": 0.0})

    assert fake_service.get_cognitive_scores("user-a")["recall"]["user_id"] == "user-a"
    assert fake_service.get_cognitive_scores("user-b")["recall"]["user_id"] == "user-b"
    assert fake_service.get_cognitive_scores("user-a")["recall"]["accuracy"] == 1.0
