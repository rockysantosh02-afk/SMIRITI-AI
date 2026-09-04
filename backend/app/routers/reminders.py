"""Reminder scheduling, acknowledgement, and self-directed follow-up endpoints."""

from datetime import datetime
from typing import Any, Dict, List
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore

from app.core.firestore_service import FirestoreService
from app.core.dependencies import get_current_user
from app.dependencies import get_firestore_service
from app.schemas.api import ReminderRequest
from app.services.reminder_logic import check_due_reminders

router = APIRouter(prefix="/reminders", tags=["reminders"])


@router.post("")
def create_reminder(request: ReminderRequest, service: FirestoreService = Depends(get_firestore_service), current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, str]:
    """Create a reminder owned by the authenticated user."""
    reminder_id = uuid4().hex
    service.client.collection("reminders").document(reminder_id).set({**request.model_dump(), "user_id": current_user["uid"], "status": "active", "created_at": firestore.SERVER_TIMESTAMP})
    return {"reminder_id": reminder_id, "status": "scheduled"}


@router.get("/check-due")
def check_due(current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
    """Check reminders belonging to the authenticated user."""
    due = check_due_reminders(current_user["uid"])
    return {"checked": len(due), "reminders": due}


@router.get("")
def list_reminders(service: FirestoreService = Depends(get_firestore_service), current_user: Dict[str, Any] = Depends(get_current_user)) -> List[Dict[str, Any]]:
    """Return active reminders owned by the authenticated user."""
    return [{"id": item.id, **(item.to_dict() or {})} for item in service.client.collection("reminders").where("user_id", "==", current_user["uid"]).where("status", "==", "active").stream()]


@router.put("/{reminder_id}/acknowledge")
def acknowledge_reminder(reminder_id: str, service: FirestoreService = Depends(get_firestore_service), current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, str]:
    """Record an acknowledgement and mark a reminder complete."""
    reference = service.client.collection("reminders").document(reminder_id)
    snapshot = reference.get()
    if not snapshot.exists or (snapshot.to_dict() or {}).get("user_id") != current_user["uid"]:
        raise HTTPException(status_code=404, detail="Reminder not found")
    reference.update({"status": "acknowledged", "acknowledged_at": firestore.SERVER_TIMESTAMP})
    return {"reminder_id": reminder_id, "status": "acknowledged"}


