"""Deterministic, dependency-free adaptive difficulty engine."""

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple


PROMOTE_THRESHOLD = 0.78
DEMOTE_THRESHOLD = 0.45
MIN_SAMPLES = 3
EWMA_ALPHA = 0.35
MAX_LEVEL = 5
MIN_LEVEL = 1


@dataclass(frozen=True)
class DomainScore:
    """Current performance metrics for one cognitive domain."""

    accuracy: float
    speed_score: float
    trend: float
    sample_count: int
    composite: float


@dataclass(frozen=True)
class DifficultyDecision:
    """Difficulty change and the metrics that produced it."""

    domain: str
    previous_level: int
    new_level: int
    changed: bool
    composite_score: float
    accuracy: float
    speed_score: float
    trend: float
    sample_count: int
    reason: str
    explanation: str


class AdaptiveDifficultyEngine:
    """Track domain performance and adjust levels from 1 through 5."""

    def __init__(self) -> None:
        self._levels: Dict[str, int] = {}
        self._scores: Dict[str, DomainScore] = {}
        self._attempts: Dict[str, List[float]] = {}

    @staticmethod
    def _clamp(value: float, lower: float = 0.0, upper: float = 1.0) -> float:
        return max(lower, min(upper, value))

    @staticmethod
    def _trend(attempts: List[float]) -> float:
        """Compare the first and second halves of the recent attempt window."""
        recent = attempts[-5:]
        if len(recent) < 2:
            return 0.0
        midpoint = len(recent) // 2
        first_half = recent[:midpoint]
        second_half = recent[midpoint:]
        difference = sum(second_half) / len(second_half) - sum(first_half) / len(first_half)
        return max(-1.0, min(1.0, difference))

    def update(
        self,
        domain: str,
        correct: bool,
        response_time: float,
        expected_time: float,
    ) -> DifficultyDecision:
        """Record an attempt and return the resulting difficulty decision.

        Args:
            domain: Cognitive domain being assessed.
            correct: Whether the attempt was answered correctly.
            response_time: Attempt duration in seconds.
            expected_time: Expected duration in seconds for the attempt.

        Returns:
            A decision containing updated scores, level, and explanation.

        Raises:
            ValueError: If domain is empty or expected time is not positive.
        """
        if not domain or not domain.strip():
            raise ValueError("domain must be a non-empty string")
        if expected_time <= 0:
            raise ValueError("expected_time must be greater than zero")
        if response_time < 0:
            raise ValueError("response_time cannot be negative")

        previous_score = self._scores.get(domain)
        sample_value = 1.0 if correct else 0.0
        accuracy = sample_value if previous_score is None else (
            EWMA_ALPHA * sample_value + (1.0 - EWMA_ALPHA) * previous_score.accuracy
        )
        speed_score = self._clamp(2.0 - (response_time / expected_time))
        attempts = self._attempts.setdefault(domain, [])
        attempts.append(sample_value)
        trend = self._trend(attempts)
        sample_count = len(attempts)
        composite = self._clamp(
            0.6 * accuracy + 0.3 * speed_score + 0.1 * ((trend + 1.0) / 2.0)
        )
        score = DomainScore(accuracy, speed_score, trend, sample_count, composite)
        self._scores[domain] = score

        previous_level = self._levels.setdefault(domain, MIN_LEVEL)
        new_level = previous_level
        reason = "No level change"
        if sample_count >= MIN_SAMPLES and composite >= PROMOTE_THRESHOLD and previous_level < MAX_LEVEL:
            new_level += 1
            reason = "Performance is consistently strong"
        elif sample_count >= MIN_SAMPLES and composite <= DEMOTE_THRESHOLD and previous_level > MIN_LEVEL:
            new_level -= 1
            reason = "Performance indicates the difficulty should decrease"
        elif sample_count < MIN_SAMPLES:
            reason = f"Collecting evidence ({sample_count}/{MIN_SAMPLES} attempts)"
        elif composite >= PROMOTE_THRESHOLD and previous_level == MAX_LEVEL:
            reason = "Performance is strong, but the maximum level is already reached"
        elif composite <= DEMOTE_THRESHOLD and previous_level == MIN_LEVEL:
            reason = "Performance is low, but the minimum level is already reached"
        else:
            reason = "Performance is within the current level range"

        self._levels[domain] = new_level
        changed = new_level != previous_level
        explanation = (
            f"{domain}: accuracy {accuracy:.2f}, speed {speed_score:.2f}, "
            f"trend {trend:+.2f}, composite {composite:.2f} over {sample_count} attempt(s). "
            f"Level {previous_level} -> {new_level}: {reason}."
        )
        return DifficultyDecision(
            domain=domain,
            previous_level=previous_level,
            new_level=new_level,
            changed=changed,
            composite_score=composite,
            accuracy=accuracy,
            speed_score=speed_score,
            trend=trend,
            sample_count=sample_count,
            reason=reason,
            explanation=explanation,
        )

    def get_current_level(self, domain: str) -> int:
        """Return the current level for a domain, defaulting to level 1."""
        return self._levels.get(domain, MIN_LEVEL)

    def get_scores(self, domain: str) -> Optional[DomainScore]:
        """Return the current score for a domain, or None if never attempted."""
        return self._scores.get(domain)