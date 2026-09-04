"""User-owned journal entry and story endpoints."""

from typing import Any, Dict, List
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore

from app.core.dependencies import get_current_user
from app.core.firestore_service import FirestoreService
from app.dependencies import get_firestore_service
from app.schemas.api import JournalEntryRequest, StoryAction, StoryRequest
from app.services.content_guard import passes_content_guard
from app.services.story_generator import generate_journal_story

router = APIRouter(prefix="/journal", tags=["journal"])


def _owned_entry(service: FirestoreService, entry_id: str, user_id: str) -> Dict[str, Any]:
    reference = service.client.collection("journal_entries").document(entry_id)
    snapshot = reference.get()
    if not snapshot.exists or (snapshot.to_dict() or {}).get("user_id") != user_id:
        raise HTTPException(status_code=404, detail="Journal entry not found")
    return {"id": snapshot.id, **(snapshot.to_dict() or {})}


@router.post("/entries")
def create_entry(
    request: JournalEntryRequest,
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, str]:
    """Create a journal entry owned by the authenticated user."""
    if not request.photo_url and not request.voice_note_url:
        raise HTTPException(status_code=422, detail="photo_url or voice_note_url is required")
    entry_id = uuid4().hex
    service.client.collection("journal_entries").document(entry_id).set(
        {**request.model_dump(), "entry_id": entry_id, "user_id": current_user["uid"], "created_at": firestore.SERVER_TIMESTAMP}
    )
    return {"entry_id": entry_id}


@router.get("/entries")
def list_entries(
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """List journal entries owned by the authenticated user."""
    return [{"id": item.id, **(item.to_dict() or {})} for item in service.client.collection("journal_entries").where("user_id", "==", current_user["uid"]).stream()]


@router.post("/stories/generate")
def create_story(
    request: StoryRequest,
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, str]:
    """Generate and save a guarded story from the user's own journal fields."""
    entries = [_owned_entry(service, entry_id, current_user["uid"]) for entry_id in request.entry_ids]
    entry = entries[0] if entries else {}
    text = generate_journal_story(
        entry.get("caption"), entry.get("tag_place"), entry.get("tag_occasion"), "English"
    )
    passed, _ = passes_content_guard(text)
    if not passed:
        text = f"What a lovely memory of {entry.get('tag_place') or 'this moment'}."
    if entry:
        service.client.collection("journal_entries").document(entry["id"]).update(
            {"ai_story_text": text, "ai_story_passed_content_guard": passed}
        )
    story_id = uuid4().hex
    service.client.collection("journal_stories").document(story_id).set(
        {"story_id": story_id, "user_id": current_user["uid"], "entry_ids": request.entry_ids,
         "content": text, "ai_story_passed_content_guard": passed, "status": "pending", "created_at": firestore.SERVER_TIMESTAMP}
    )
    return {"story_id": story_id, "status": "pending"}


@router.put("/stories/{story_id}/approve")
def approve_story(
    story_id: str,
    request: StoryAction,
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, str]:
    """Approve or reject the authenticated user's story."""
    if request.action not in {"approve", "reject"}:
        raise HTTPException(status_code=400, detail="action must be approve or reject")
    reference = service.client.collection("journal_stories").document(story_id)
    snapshot = reference.get()
    if not snapshot.exists or (snapshot.to_dict() or {}).get("user_id") != current_user["uid"]:
        raise HTTPException(status_code=404, detail="Story not found")
    status = "approved" if request.action == "approve" else "rejected"
    reference.update({"status": status, "updated_at": firestore.SERVER_TIMESTAMP})
    return {"story_id": story_id, "status": status}
