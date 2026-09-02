"""Small rule-based safety guard for generated memory content."""

import re
from typing import Any, Dict, List, Optional

_BLOCKED_TERMS = ("explicit", "sexual", "abuse", "violence", "violent", "weapon")
_MAX_CONTENT_LENGTH = 5000


def is_safe_content(text: str) -> bool:
    """Return whether generated text contains no blocked safety terms."""
    normalized = text.casefold()
    return not any(re.search(rf"\b{re.escape(term)}\b", normalized) for term in _BLOCKED_TERMS)


def check_content(text: str, relationship: Optional[str] = None, allowed_relationships: Optional[List[str]] = None) -> Dict[str, Any]:
    """Return a safety result with actionable reasons for rejected content."""
    reasons: List[str] = []
    normalized = text.casefold()
    if len(text) > _MAX_CONTENT_LENGTH:
        reasons.append("content exceeds the maximum allowed length")
    blocked = [term for term in _BLOCKED_TERMS if re.search(rf"\b{re.escape(term)}\b", normalized)]
    if blocked:
        reasons.append("content contains distressing or unsafe language")
    if allowed_relationships is not None and relationship not in allowed_relationships:
        reasons.append("relationship is not allowed for this memory")
    return {"safe": not reasons, "reasons": reasons}


def guard_content(text: str) -> str:
    """Return text when safe, otherwise raise ValueError."""
    result = check_content(text)
    if not result["safe"]:
        raise ValueError("Generated content was blocked: " + "; ".join(result["reasons"]))
    return text
