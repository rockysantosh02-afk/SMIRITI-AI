"""FastAPI dependencies shared by routers."""

from typing import Any, Dict

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.firebase_admin import verify_firebase_token
from app.core.firestore_service import FirestoreService
from app.core.security import get_current_active_user, get_current_user

bearer_scheme = HTTPBearer(auto_error=False)


def get_firestore_service() -> FirestoreService:
    """Provide a Firestore service instance for a request."""
    return FirestoreService()


def get_current_firebase_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> Dict[str, Any]:
    """Validate a Firebase bearer token and return Firebase claims."""
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Bearer token required")
    claims = verify_firebase_token(credentials.credentials)
    if claims is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired Firebase token")
    return claims