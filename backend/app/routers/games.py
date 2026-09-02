"""Game catalog, session, round, and attempt endpoints."""

from typing import Any, Dict
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from firebase_admin import firestore

from app.core.firestore_service import FirestoreService
from app.dependencies import get_firestore_service
from core_logic.adaptive_difficulty import AdaptiveDifficultyEngine
from core_logic.game_engine import GAMES, get_next_round, score_round

router = APIRouter(prefix="/games", tags=["games"])
_engines: Dict[str, AdaptiveDifficultyEngine] = {}


class GameSessionRequest(BaseModel):
    patient_id: str
    game_code: str


class AttemptRequest(BaseModel):
    session_id: str
    selected_index: int = Field(ge=0)
    response_time_ms: int = Field(ge=0)


@router.get("")
def list_games() -> list[dict[str, Any]]:
    """Return the public catalog of all available games."""
    return [
        {"code": game.code, "title": game.title, "domain": game.domain, "description": game.description}
        for game in GAMES.values()
    ]


@router.post("/session")
def create_session(
    request: GameSessionRequest,
    service: FirestoreService = Depends(get_firestore_service),
) -> dict[str, Any]:
    """Create a game session at the initial difficulty level."""
    if request.game_code not in GAMES:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Game not found")
    session_id = uuid4().hex
    service.client.collection("game_sessions").document(session_id).set(
        {"patient_id": request.patient_id, "game_code": request.game_code, "difficulty": 1,
         "status": "active", "created_at": firestore.SERVER_TIMESTAMP}
    )
    _engines[session_id] = AdaptiveDifficultyEngine()
    return {"session_id": session_id, "difficulty": 1, "game_code": request.game_code}


@router.get("/next-round/{session_id}")
def next_round(session_id: str, service: FirestoreService = Depends(get_firestore_service)) -> dict[str, Any]:
    """Return the next round for an active session."""
    snapshot = service.client.collection("game_sessions").document(session_id).get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Game session not found")
    session = snapshot.to_dict() or {}
    return get_next_round(str(session["game_code"]), int(session.get("difficulty", 1)))


@router.post("/attempt")
def submit_attempt(
    request: AttemptRequest,
    service: FirestoreService = Depends(get_firestore_service),
) -> dict[str, Any]:
    """Score an attempt, persist it, and update adaptive difficulty."""
    session_ref = service.client.collection("game_sessions").document(request.session_id)
    snapshot = session_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Game session not found")
    session = snapshot.to_dict() or {}
    difficulty = int(session.get("difficulty", 1))
    round_data = get_next_round(str(session["game_code"]), difficulty)
    result = score_round(round_data, request.selected_index)
    engine = _engines.setdefault(request.session_id, AdaptiveDifficultyEngine())
    decision = engine.update(str(GAMES[str(session["game_code"])].domain), result["correct"], request.response_time_ms / 1000, result["expected_time_ms"] / 1000)
    service.client.collection("game_attempts").add(
        {"session_id": request.session_id, "correct": result["correct"], "response_time_ms": request.response_time_ms,
         "difficulty": difficulty, "created_at": firestore.SERVER_TIMESTAMP}
    )
    session_ref.update({"difficulty": decision.new_level, "updated_at": firestore.SERVER_TIMESTAMP})
    service.update_cognitive_score(str(session["patient_id"]), decision.domain, {"composite": decision.composite_score, "accuracy": decision.accuracy, "speed_score": decision.speed_score, "trend": decision.trend})
    return {**result, "decision": decision.__dict__, "difficulty": decision.new_level}


@router.get("/scores/{patient_id}")
def patient_scores(patient_id: str, service: FirestoreService = Depends(get_firestore_service)) -> dict[str, Any]:
    """Return all cognitive scores for a patient."""
    return service.get_cognitive_scores(patient_id)
