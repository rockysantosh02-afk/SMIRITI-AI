"""Pure Python content and scoring engine for Smriti AI cognitive games."""

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional


@dataclass(frozen=True)
class GameContent:
    """Definition and seeded rounds for one cognitive game."""

    code: str
    title: str
    domain: str
    description: str
    is_memory_generated: bool
    content: List[Dict[str, Any]]


class GameEngine:
    """Serve deterministic game rounds and score submitted answers."""

    def __init__(self, games: Optional[Dict[str, GameContent]] = None) -> None:
        self.games = games if games is not None else self._load_games()

    @staticmethod
    def _load_games() -> Dict[str, GameContent]:
        content_path = Path(__file__).resolve().parents[1] / "data" / "game_content.json"
        with content_path.open(encoding="utf-8") as content_file:
            raw_games = json.load(content_file)
        return {
            code: GameContent(
                code=code,
                title=definition["title"],
                domain=definition["domain"],
                description=definition["description"],
                is_memory_generated=definition["is_memory_generated"],
                content=definition["content"],
            )
            for code, definition in raw_games.items()
        }

    def get_next_round(
        self,
        game_code: str,
        difficulty: int,
        memory_graph: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Return a round for a game and difficulty level.

        Recall games use the user's journal entries when supplied; otherwise
        their seeded static round is returned.
        """
        if game_code not in self.games:
            raise ValueError(f"Unknown game code: {game_code}")
        if difficulty < 1 or difficulty > 3:
            raise ValueError("difficulty must be between 1 and 3")

        game = self.games[game_code]
        round_data = dict(game.content[difficulty - 1])
        round_data["memory_generated"] = False
        if game.is_memory_generated and memory_graph:
            entries = memory_graph.get("entries") or []
            if entries:
                entry = entries[0]
                caption = entry.get("caption") or entry.get("tag_occasion") or entry.get("tag_place") or "this journal entry"
                answer = entry.get("tag_object") or entry.get("tag_place") or caption
                round_data["prompt"] = f"What do you remember about {caption}?"
                round_data["expected_answer"] = answer
                round_data["memory_generated"] = True
                if answer not in round_data.get("options", []):
                    round_data["options"] = [answer] + list(round_data.get("options", []))
        round_data["game_code"] = game_code
        round_data["domain"] = game.domain
        return round_data

    @staticmethod
    def score_round(round_data: Dict[str, Any], answer: Any) -> Dict[str, Any]:
        """Score an answer and return correctness plus the expected time.

        An integer answer is treated as an option index when the round has
        options; all other answers are compared directly to expected_answer.
        """
        submitted_answer = answer
        options = round_data.get("options", [])
        if isinstance(answer, int) and 0 <= answer < len(options):
            submitted_answer = options[answer]
        expected = round_data.get("expected_answer")
        if isinstance(expected, list) and isinstance(submitted_answer, list):
            correct = submitted_answer == expected
        else:
            correct = submitted_answer == expected
        return {
            "correct": correct,
            "expected_time_ms": int(round_data.get("expected_time_ms", 15000)),
        }


_default_engine = GameEngine()


def get_next_round(
    game_code: str,
    difficulty: int,
    memory_graph: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Return the next deterministic round from the default game engine."""
    return _default_engine.get_next_round(game_code, difficulty, memory_graph)


def score_round(round_data: Dict[str, Any], answer: Any) -> Dict[str, Any]:
    """Score a round using the default game engine."""
    return _default_engine.score_round(round_data, answer)


GAMES = _default_engine.games
