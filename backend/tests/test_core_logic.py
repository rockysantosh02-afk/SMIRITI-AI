"""Fast unit tests for all dependency-free core logic."""

from datetime import datetime, timedelta, timezone

import pytest

from app.core.outbox_manager import OutboxManager
from app.services.content_guard import check_content, guard_content
from app.services.reminder_logic import should_escalate
from app.services.sync_service import SyncService
from core_logic.adaptive_difficulty import AdaptiveDifficultyEngine, MAX_LEVEL, MIN_LEVEL
from core_logic.game_engine import get_next_round, score_round


def _decision_text(decision) -> None:
    assert decision.reason and decision.explanation


def test_new_domain_starts_level_1(engine):
    assert engine.get_current_level("memory") == MIN_LEVEL
    decision = engine.update("memory", True, 10, 10)
    assert decision.new_level == MIN_LEVEL
    _decision_text(decision)


def test_few_samples_no_change(engine):
    for _ in range(2):
        decision = engine.update("memory", True, 5, 10)
        assert decision.new_level == MIN_LEVEL
        assert not decision.changed
        _decision_text(decision)


def test_promotion_to_level_2(engine):
    for _ in range(3):
        decision = engine.update("memory", True, 5, 10)
    assert decision.new_level == 2 and decision.changed
    _decision_text(decision)


def test_demotion_to_level_1(engine):
    for _ in range(3):
        engine.update("memory", True, 5, 10)
    decision = engine.update("memory", False, 30, 10)
    assert decision.previous_level == 2 and decision.new_level == 1
    _decision_text(decision)


def test_stable_performance(engine):
    decisions = [engine.update("memory", value, 15, 10) for value in (True, False, True, False)]
    assert decisions[-1].new_level == MIN_LEVEL and not decisions[-1].changed
    for decision in decisions:
        _decision_text(decision)


def test_cap_at_level_5(engine):
    for _ in range(20):
        decision = engine.update("memory", True, 1, 10)
    assert decision.new_level == MAX_LEVEL
    assert not decision.changed
    _decision_text(decision)


def test_floor_at_level_1(engine):
    for _ in range(3):
        decision = engine.update("memory", False, 30, 10)
    assert decision.new_level == MIN_LEVEL and not decision.changed
    _decision_text(decision)


def test_speed_affects_composite(engine):
    fast = engine.update("fast", True, 5, 10)
    slow = engine.update("slow", True, 20, 10)
    assert fast.composite_score > slow.composite_score
    _decision_text(fast); _decision_text(slow)


def test_trend_affects_composite(engine):
    for value in (False, False, True, True):
        improving = engine.update("improving", value, 10, 10)
    for value in (True, True, False, False):
        declining = engine.update("declining", value, 10, 10)
    assert improving.trend > declining.trend
    assert improving.composite_score > declining.composite_score
    _decision_text(improving); _decision_text(declining)


def test_deterministic_behavior():
    sequence = [(True, 5), (False, 12), (True, 4), (True, 6)]
    results = []
    for _ in range(2):
        local = AdaptiveDifficultyEngine()
        results.append([local.update("memory", correct, response, 10) for correct, response in sequence])
    assert results[0] == results[1]
    for decision in results[0]: _decision_text(decision)


def test_get_next_round_returns_content():
    round_data = get_next_round("matching_image", 1)
    assert round_data["prompt"] and round_data["options"]
    assert score_round(round_data, round_data["expected_answer"])["correct"]


def test_different_difficulty_returns_different_content():
    assert get_next_round("number_compare", 1)["prompt"] != get_next_round("number_compare", 2)["prompt"]


def test_memory_generated_game_with_data():
    result = get_next_round("recall_my_memories", 1, {"entries": [{"caption": "garden visit", "tag_place": "garden"}]})
    assert result["memory_generated"] and result["expected_answer"] == "garden"


def test_memory_generated_game_without_data_fallback():
    result = get_next_round("recall_my_memories", 1)
    assert result["memory_generated"] is False and result["expected_answer"]


def test_scoring_correct_answer():
    round_data = get_next_round("matching_image", 1)
    assert score_round(round_data, round_data["expected_answer"])["correct"] is True


def test_scoring_incorrect_answer():
    round_data = get_next_round("matching_image", 1)
    assert score_round(round_data, "wrong")["correct"] is False


def test_all_9_games_exist():
    from core_logic.game_engine import GAMES
    assert len(GAMES) == 9


def test_clean_content_passes():
    assert check_content("A happy family memory") == {"safe": True, "reasons": []}
    assert guard_content("A happy family memory")


def test_distressing_content_blocked():
    result = check_content("A violent event")
    assert not result["safe"] and result["reasons"]


def test_too_long_content_blocked():
    assert not check_content("x " * 81)["safe"]


def test_wrong_relationship_blocked():
    result = check_content("A family memory", "stranger", ["mother", "sister"])
    assert not result["safe"] and any("relationship" in reason for reason in result["reasons"])


def test_content_guard_returns_reasons():
    result = check_content("violent " + "x " * 81, "stranger", ["mother"])
    assert len(result["reasons"]) == 2


def test_below_threshold_no_escalation():
    now = datetime.now(timezone.utc)
    assert not should_escalate({"status": "active", "scheduled_time": now + timedelta(minutes=1)}, now)


def test_at_threshold_escalates():
    now = datetime.now(timezone.utc)
    assert should_escalate({"status": "active", "scheduled_time": now}, now)


def test_acknowledged_reminder_no_escalation():
    now = datetime.now(timezone.utc)
    assert not should_escalate({"status": "acknowledged", "scheduled_time": now - timedelta(minutes=1)}, now)


def test_mixed_history_correctly_evaluated():
    now = datetime.now(timezone.utc)
    assert should_escalate({"status": "active", "scheduled_time": now}, now)
    assert not should_escalate({"status": "acknowledged", "scheduled_time": now}, now)


def test_outbox_sync_and_conflicts():
    outbox = OutboxManager(); service = SyncService(outbox)
    entry_id = outbox.enqueue("events", {"id": "1"}, "entry-1")
    assert outbox.enqueue("events", {"id": "changed"}, "entry-1") == entry_id
    written = []; assert service.sync(lambda collection, data: written.append((collection, data))) == [entry_id]
    assert not outbox.pending()
    assert service.resolve_last_write_wins({"updated_at": 2}, {"updated_at": 1})["updated_at"] == 2
    assert len(service.merge_append_only([{"id": "a"}], [{"id": "a"}, {"id": "b"}])) == 2
