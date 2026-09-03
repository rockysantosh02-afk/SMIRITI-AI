"""Conservative validation for AI-generated journal content."""

import re
from typing import Any, Dict, List, Optional

_BLOCKED_TERMS = (
    "explicit", "sexual", "abuse", "violence", "violent", "weapon",
    "illness", "disease", "death", "dead", "died", "dying", "funeral",
    "suicide", "self-harm", "murder",
)
_MAX_WORDS = 80


def is_safe_content(text: str) -> bool:
    """Return whether generated text contains no blocked safety terms."""
    normalized = text.casefold()
    return not any(re.search(rf"\b{re.escape(term)}\b", normalized) for term in _BLOCKED_TERMS)


def passes_content_guard(text: str) -> tuple[bool, str]:
    """Return ``(True, '')`` for safe text, or ``(False, reason)`` otherwise."""
    if len(text.split()) > _MAX_WORDS:
        return False, "content exceeds the maximum of 80 words"
    normalized = text.casefold()
    if any(re.search(rf"\b{re.escape(term)}\b", normalized) for term in _BLOCKED_TERMS):
        return False, "content contains distressing or unsafe language"
    return True, ""


def check_content(text: str, relationship: Optional[str] = None, allowed_relationships: Optional[List[str]] = None) -> Dict[str, Any]:
    """Return a safety result with actionable reasons for rejected content."""
    reasons: List[str] = []
    normalized = text.casefold()
    passed, reason = passes_content_guard(text)
    if not passed:
        reasons.append(reason)
    if allowed_relationships is not None and relationship not in allowed_relationships:
        reasons.append("relationship is not allowed for this memory")
    return {"safe": not reasons, "reasons": reasons}


def guard_content(text: str) -> str:
    """Return text when safe, otherwise raise ValueError."""
    result = check_content(text)
    if not result["safe"]:
        raise ValueError("Generated content was blocked: " + "; ".join(result["reasons"]))
    return text
