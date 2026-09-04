"""Backward-compatible import for the service-owned difficulty engine."""

from app.services.adaptive_difficulty import (
    AdaptiveDifficultyEngine,
    DEMOTION_THRESHOLD,
    DifficultyDecision,
    MAX_LEVEL,
    MIN_ATTEMPTS,
    MIN_LEVEL,
    PROMOTION_THRESHOLD,
)

__all__ = [
    "AdaptiveDifficultyEngine",
    "DifficultyDecision",
    "MIN_ATTEMPTS",
    "PROMOTION_THRESHOLD",
    "DEMOTION_THRESHOLD",
    "MIN_LEVEL",
    "MAX_LEVEL",
]
