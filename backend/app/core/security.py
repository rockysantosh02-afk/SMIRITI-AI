"""Firebase ID-token authentication dependencies."""

from typing import Any, Dict

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.firebase_admin import FirebaseInitializationError, verify_firebase_token

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> Dict[str, Any]:
    """Verify a Firebase ID token and return only its authenticated identity."""
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Bearer Firebase ID token required",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        claims = verify_firebase_token(credentials.credentials)
    except FirebaseInitializationError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc
    if not claims or not isinstance(claims.get("uid"), str) or not claims["uid"]:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Firebase ID token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return {"uid": claims["uid"], "email": claims.get("email")}


def get_current_active_user(
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, Any]:
    """Return the authenticated Firebase identity."""
    return current_user


__all__ = ["bearer_scheme", "get_current_active_user", "get_current_user"]
