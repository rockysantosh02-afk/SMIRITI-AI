"""Development and automated-test setup endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore
from uuid import uuid4

from app.core.firestore_service import FirestoreService
from app.dependencies import get_firestore_service
from app.core.dependencies import get_current_user
from app.routers.games import _engines
from core_logic.adaptive_difficulty import AdaptiveDifficultyEngine
from core_logic.game_engine import GAMES

router = APIRouter(prefix="/test", tags=["test helpers"])


def _create_game_session(service: FirestoreService, user_id: str, game_code: str) -> str:
    if game_code not in GAMES:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Game not found")
    session_id = uuid4().hex
    service.client.collection("game_sessions").document(session_id).set(
        {"user_id": user_id, "game_code": game_code, "difficulty": 1,
         "status": "active", "created_at": firestore.SERVER_TIMESTAMP}
    )
    _engines[session_id] = AdaptiveDifficultyEngine()
    return session_id


@router.get("/setup")
def setup_test_data(service: FirestoreService = Depends(get_firestore_service), current_user: dict = Depends(get_current_user)) -> dict[str, str]:
    """Create a user-owned profile and default game session for testing."""
    user_id = current_user["uid"]
    service.create_patient(user_id, {"name": "Test User", "status": "active"})
    session_id = _create_game_session(service, user_id, "matching_image")
    return {"user_id": user_id, "session_id": session_id, "game_code": "matching_image"}


@router.post("/create-session/{game_code}")
def create_test_session(
    game_code: str,
    service: FirestoreService = Depends(get_firestore_service),
    current_user: dict = Depends(get_current_user),
) -> dict[str, str]:
    """Create a session for any game in the public catalog."""
    if game_code not in GAMES:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Game not found")
    user_id = current_user["uid"]
    service.create_patient(user_id, {"name": "Test User", "status": "active"})
    return {"session_id": _create_game_session(service, user_id, game_code)}