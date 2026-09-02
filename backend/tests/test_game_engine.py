"""Tests for the dependency-free cognitive game engine."""

import pytest

from core_logic.game_engine import GAMES, GameContent, GameEngine, get_next_round, score_round


@pytest.fixture
def engine() -> GameEngine:
    return GameEngine()


def test_all_nine_games_have_three_levels(engine: GameEngine) -> None:
    assert len(GAMES) == 9
    assert len(engine.games) == 9
    assert all(len(game.content) == 3 for game in engine.games.values())


def test_round_matches_requested_difficulty(engine: GameEngine) -> None:
    round_data = engine.get_next_round("number_compare", 2)
    assert round_data["level"] == 2
    assert round_data["game_code"] == "number_compare"
    assert round_data["domain"] == "NUMERACY"


def test_memory_game_uses_memory_graph(engine: GameEngine) -> None:
    round_data = engine.get_next_round(
        "family_quiz", 1, {"persons": [{"name": "Asha", "relationship": "daughter"}]}
    )
    assert round_data["memory_generated"] is True
    assert round_data["expected_answer"] == "daughter"
    assert "daughter" in round_data["options"]


def test_memory_game_falls_back_to_seeded_content(engine: GameEngine) -> None:
    round_data = engine.get_next_round("family_quiz", 2, {})
    assert round_data["memory_generated"] is not True
    assert round_data["expected_answer"] == "daughter"


def test_score_round_accepts_option_index(engine: GameEngine) -> None:
    round_data = engine.get_next_round("number_compare", 1)
    result = engine.score_round(round_data, 0)
    assert result == {"correct": True, "expected_time_ms": 12000}


def test_score_round_rejects_wrong_answer(engine: GameEngine) -> None:
    round_data = engine.get_next_round("number_compare", 1)
    result = score_round(round_data, "4")
    assert result["correct"] is False
    assert result["expected_time_ms"] == 12000


def test_module_helpers_use_default_engine() -> None:
    round_data = get_next_round("matching_image", 3)
    assert round_data["level"] == 3
    assert score_round(round_data, round_data["expected_answer"])["correct"] is True


def test_invalid_game_and_difficulty_are_actionable(engine: GameEngine) -> None:
    with pytest.raises(ValueError, match="Unknown game code"):
        engine.get_next_round("missing", 1)
    with pytest.raises(ValueError, match="between 1 and 3"):
        engine.get_next_round("matching_image", 4)


def test_game_content_can_be_injected() -> None:
    custom_game = GameContent("custom", "Custom", "RECALL", "Test", False, [{"level": 1}])
    engine = GameEngine({"custom": custom_game})
    assert engine.get_next_round("custom", 1)["level"] == 1
