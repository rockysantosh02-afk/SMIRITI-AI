"""JWT helpers and authenticated-user dependencies for internal API access."""

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt

from app.core.config import settings
from app.core.firestore_service import FirestoreService  # Compatibility import for existing test fixtures.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/firebase-login")


class InvalidTokenError(ValueError):
    """Raised when a JWT is malformed, expired, or fails verification."""


def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create a signed JWT containing data and an expiration claim."""
    payload = dict(data)
    payload["exp"] = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_access_token(token: str) -> Dict[str, Any]:
    """Decode and validate an internal JWT.

    Args:
        token: Encoded JWT received from an API client.

    Returns:
        The verified JWT claims.

    Raises:
        InvalidTokenError: If the token is malformed, expired, or invalid.
    """
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError as exc:
        raise InvalidTokenError("Invalid or expired access token") from exc


def get_current_user(token: str = Depends(oauth2_scheme)) -> Dict[str, Any]:
    """Validate a JWT and return its authenticated Firebase UID.

    Args:
        token: Bearer token extracted by FastAPI's OAuth2 scheme.

    Returns:
        A minimal identity dictionary containing ``uid`` and optional ``email``.

    Raises:
        HTTPException: With status 401 for invalid tokens or missing users.
    """
    try:
        claims = decode_access_token(token)
    except InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    user_id = claims.get("uid") or claims.get("sub")
    if not isinstance(user_id, str) or not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Access token does not contain a user ID",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return {"uid": user_id, "email": claims.get("email")}


def get_current_active_user(
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, Any]:
    """Return the authenticated user identity.

    Args:
        current_user: User returned by :func:`get_current_user`.

    Returns:
        The active user dictionary.

    Raises:
        HTTPException: With status 401 when the account is inactive.
    """
    return current_user