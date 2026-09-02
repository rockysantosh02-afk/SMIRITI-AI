"""Firebase authentication endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.firebase_admin import verify_firebase_token
from app.core.firestore_service import FirestoreService
from app.core.security import create_access_token
from app.core.dependencies import get_current_active_user
from app.models.auth_models import (
    FirebaseLoginRequest,
    FirebaseLoginResponse,
    FirebaseVerifyResponse,
    UserResponse,
)

router = APIRouter(prefix="/auth", tags=["authentication"])
bearer_scheme = HTTPBearer(auto_error=False)


@router.post("/firebase-login", response_model=FirebaseLoginResponse)
def firebase_login(request: FirebaseLoginRequest) -> FirebaseLoginResponse:
    """Verify a Firebase ID token, provision its user, and issue an internal JWT."""
    claims = verify_firebase_token(request.id_token)
    if claims is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired Firebase token")
    service = FirestoreService()
    uid = str(claims["uid"])
    user = service.get_user(uid)
    role = str((user or {}).get("role", "patient"))
    if user is None:
        service.create_user(uid, {"email": claims.get("email"), "name": claims.get("name"), "role": role, "is_active": True})
    token = create_access_token({"sub": uid, "firebase_uid": uid, "role": role})
    return FirebaseLoginResponse(access_token=token, user_id=uid, role=role, firebase_uid=uid)


@router.post("/firebase-verify", response_model=FirebaseVerifyResponse)
def firebase_verify(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> FirebaseVerifyResponse:
    """Verify a Firebase bearer token supplied through the Authorization header."""
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Bearer token required")
    claims = verify_firebase_token(credentials.credentials)
    if claims is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired Firebase token")
    return FirebaseVerifyResponse(user=UserResponse(uid=str(claims["uid"]), email=claims.get("email"), name=claims.get("name"), role=str(claims.get("role", "patient")), language=claims.get("language")))


@router.post("/logout")
def logout() -> dict[str, str]:
    """End a stateless session; clients discard their JWT locally."""
    return {"status": "success", "message": "Logged out"}


@router.get("/me", response_model=UserResponse)
def me(current_user: dict = Depends(get_current_active_user)) -> UserResponse:
    """Return the active authenticated user's Firestore profile."""
    return UserResponse(
        uid=str(current_user.get("uid", current_user.get("id", ""))),
        email=current_user.get("email"),
        name=current_user.get("name"),
        role=str(current_user.get("role", "patient")),
        language=current_user.get("language"),
    )