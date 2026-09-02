"""FastAPI dependencies for authenticated application requests."""

from typing import Any, Dict

from fastapi import Depends

from app.core.security import (
    get_current_active_user,
    get_current_user,
    oauth2_scheme,
)


def get_authenticated_user(
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, Any]:
    """Return the authenticated Firestore user for a protected route."""
    return current_user


__all__ = [
    "get_authenticated_user",
    "get_current_active_user",
    "get_current_user",
    "oauth2_scheme",
]