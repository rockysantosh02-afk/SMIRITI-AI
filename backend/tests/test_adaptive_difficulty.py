"""Requirement-focused tests for the adaptive difficulty engine."""

from typing import Callable

from core_logic.adaptive_difficulty import AdaptiveDifficultyEngine, MAX_LEVEL, MIN_LEVEL


def assert_explained(decision) -> None:
    assert decision.explanation
    assert decision.reason
    assert decision.domain in decision.explanation
    assert str(decision.new_level) in decision.explanation


def test_initial_state(engine: AdaptiveDifficultyEngine) -> None:
    assert engine.get_current_level("memory") == MIN_LEVEL
    assert engine.get_scores("memory") is None
    decision = engine.update("memory", True, 10, 10)
    assert decision.previous_level == MIN_LEVEL
    assert decision.new_level == MIN_LEVEL
    assert_explained(decision)


def test_few_samples_no_change(engine: AdaptiveDifficultyEngine) -> None:
    decisions = [engine.update("memory", True, 5, 10) for _ in range(2)]
    for decision in decisions:
        assert decision.changed is False
        assert decision.new_level == MIN_LEVEL
        assert_explained(decision)


def test_promotion(engine: AdaptiveDifficultyEngine) -> None:
    decisions = [engine.update("memory", True, 5, 10) for _ in range(3)]
    decision = decisions[-1]
    assert decision.changed is True
    assert decision.previous_level == 1
    assert decision.new_level == 2
    assert_explained(decision)


def test_demotion(engine: AdaptiveDifficultyEngine) -> None:
    for _ in range(3):
        engine.update("memory", True, 5, 10)
    decision = engine.update("memory", False, 30, 10)
    assert decision.changed is True
    assert decision.previous_level == 2
    assert decision.new_level == 1
    assert_explained(decision)


def test_stable(engine: AdaptiveDifficultyEngine) -> None:
    decisions = [
        engine.update("memory", correct, 15, 10)
        for correct in (True, False, True, False)
    ]
    decision = decisions[-1]
    assert decision.changed is False
    assert decision.new_level == MIN_LEVEL
    assert_explained(decision)


def test_speed_impact(engine: AdaptiveDifficultyEngine) -> None:
    fast = engine.update("fast", True, 5, 10)
    slow = engine.update("slow", True, 20, 10)
    assert fast.speed_score > slow.speed_score
    assert fast.composite_score > slow.composite_score
    assert_explained(fast)
    assert_explained(slow)


def test_trend_impact(engine: AdaptiveDifficultyEngine) -> None:
    for correct in (False, False, True, True):
        improving_decision = engine.update("improving", correct, 10, 10)
    for correct in (True, True, False, False):
        declining_decision = engine.update("declining", correct, 10, 10)
    assert improving_decision.trend > declining_decision.trend
    assert improving_decision.composite_score > declining_decision.composite_score
    assert_explained(improving_decision)
    assert_explained(declining_decision)


def test_cap_at_level_5(engine: AdaptiveDifficultyEngine) -> None:
    for _ in range(20):
        decision = engine.update("memory", True, 1, 10)
    assert decision.new_level == MAX_LEVEL
    assert engine.get_current_level("memory") == MAX_LEVEL
    assert decision.changed is False
    assert_explained(decision)


def test_floor_at_level_1(engine: AdaptiveDifficultyEngine) -> None:
    for _ in range(3):
        decision = engine.update("memory", False, 30, 10)
    assert decision.new_level == MIN_LEVEL
    assert engine.get_current_level("memory") == MIN_LEVEL
    assert decision.changed is False
    assert_explained(decision)


def test_deterministic(sequence_factory: Callable[[], AdaptiveDifficultyEngine]) -> None:
    sequence = [(True, 5), (False, 12), (True, 4), (True, 6), (False, 20)]
    first = sequence_factory()
    second = sequence_factory()
    first_results = [first.update("memory", correct, response, 10) for correct, response in sequence]
    second_results = [second.update("memory", correct, response, 10) for correct, response in sequence]
    assert first_results == second_results
    for decision in first_results:
        assert_explained(decision)
