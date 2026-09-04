"""Deterministic, dependency-free adaptive difficulty for cognitive games."""

from dataclasses import dataclass
from typing import Dict, List, Optional

MIN_ATTEMPTS = 3
PROMOTION_THRESHOLD = 0.78
DEMOTION_THRESHOLD = 0.45
MIN_LEVEL = 1
MAX_LEVEL = 5


@dataclass(frozen=True)
class DifficultyDecision:
    """Difficulty outcome and the metrics used to produce it."""

    domain: str
    previous_level: int
    new_level: int
    changed: bool
    reason: str
    composite_score: float
    attempt_count: int
    accuracy: float
    response_time_performance: float
    consistency: float
    trend: float
    explanation: str

    @property
    def speed_score(self) -> float:
        """Compatibility alias for the persisted score field."""
        return self.response_time_performance


class AdaptiveDifficultyEngine:
    """Track one user's domain performance and adjust levels from 1 through 5."""

    def __init__(self) -> None:
        self._levels: Dict[str, int] = {}
        self._results: Dict[str, List[float]] = {}
        self._speed: Dict[str, List[float]] = {}
        self._last: Dict[str, DifficultyDecision] = {}

    @staticmethod
    def _clamp(value: float) -> float:
        return max(0.0, min(1.0, value))

    def update(self, domain: str, correct: bool, response_time: float, expected_time: float) -> DifficultyDecision:
        """Record an attempt using 60/30/10 accuracy, speed, consistency weights."""
        if not domain.strip():
            raise ValueError("domain must be a non-empty string")
        if response_time < 0 or expected_time <= 0:
            raise ValueError("response_time must be non-negative and expected_time must be positive")

        results = self._results.setdefault(domain, [])
        speeds = self._speed.setdefault(domain, [])
        results.append(1.0 if correct else 0.0)
        speeds.append(self._clamp(1.0 - response_time / expected_time))
        recent_results = results[-5:]
        accuracy = sum(recent_results) / len(recent_results)
        speed = speeds[-1]
        consistency = recent_results[-1]
        midpoint = len(recent_results) // 2
        if midpoint == 0:
            trend = 0.0
        else:
            trend = self._clamp(
                (sum(recent_results[midpoint:]) / len(recent_results[midpoint:]))
                - (sum(recent_results[:midpoint]) / len(recent_results[:midpoint]))
            )
        composite = self._clamp(0.6 * accuracy + 0.3 * speed + 0.1 * consistency)
        level = self._levels.setdefault(domain, MIN_LEVEL)
        new_level = level
        if len(results) < MIN_ATTEMPTS:
            reason = f"Let's gather a little more practice ({len(results)}/{MIN_ATTEMPTS} attempts)."
        elif composite >= PROMOTION_THRESHOLD and level < MAX_LEVEL:
            new_level += 1
            reason = "You are doing well, so a little more challenge may be a good fit."
        elif composite <= DEMOTION_THRESHOLD and level > MIN_LEVEL:
            new_level -= 1
            reason = "A gentler level may feel more comfortable right now."
        else:
            reason = "This level looks like a good match for now."
        self._levels[domain] = new_level
        decision = DifficultyDecision(
            domain=domain,
            previous_level=level,
            new_level=new_level,
            changed=new_level != level,
            reason=reason,
            composite_score=composite,
            attempt_count=len(results),
            accuracy=accuracy,
            response_time_performance=speed,
            consistency=consistency,
            trend=trend,
            explanation=f"{domain}: score {composite:.2f} after {len(results)} attempt(s); level {level} to {new_level}.",
        )
        self._last[domain] = decision
        return decision

    def get_current_level(self, domain: str) -> int:
        return self._levels.get(domain, MIN_LEVEL)

    def get_scores(self, domain: str) -> Optional[DifficultyDecision]:
        return self._last.get(domain)


__all__ = [
    "AdaptiveDifficultyEngine",
    "DifficultyDecision",
    "MIN_ATTEMPTS",
    "PROMOTION_THRESHOLD",
    "DEMOTION_THRESHOLD",
    "MIN_LEVEL",
    "MAX_LEVEL",
]
