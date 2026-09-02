"""Reminder scheduling, acknowledgement, and escalation endpoints."""

from datetime import datetime
from typing import Any, Dict, List
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore
from pydantic import BaseModel

from app.core.firestore_service import FirestoreService
from app.dependencies import get_firestore_service
from app.services.reminder_logic import check_due_reminders, process_escalation

router = APIRouter(prefix="/reminders", tags=["reminders"])


class ReminderRequest(BaseModel):
    patient_id: str
    label: str
    type: str
    scheduled_time: datetime


@router.post("")
def create_reminder(request: ReminderRequest, service: FirestoreService = Depends(get_firestore_service)) -> Dict[str, str]:
    """Create a reminder and schedule its local notification metadata."""
    reminder_id = uuid4().hex
    service.client.collection("reminders").document(reminder_id).set({**request.model_dump(), "status": "active", "created_at": firestore.SERVER_TIMESTAMP})
    return {"reminder_id": reminder_id, "status": "scheduled"}


@router.get("/check-due")
def check_due() -> Dict[str, Any]:
    """Check due reminders; intended for periodic Celery invocation."""
    due = check_due_reminders()
    return {"checked": len(due), "reminders": due}


@router.get("/{patient_id}")
def list_reminders(patient_id: str, service: FirestoreService = Depends(get_firestore_service)) -> List[Dict[str, Any]]:
    """Return active reminders for a patient."""
    return [{"id": item.id, **(item.to_dict() or {})} for item in service.client.collection("reminders").where("patient_id", "==", patient_id).where("status", "==", "active").stream()]


@router.put("/{reminder_id}/acknowledge")
def acknowledge_reminder(reminder_id: str, service: FirestoreService = Depends(get_firestore_service)) -> Dict[str, str]:
    """Record an acknowledgement and mark a reminder complete."""
    reference = service.client.collection("reminders").document(reminder_id)
    if not reference.get().exists:
        raise HTTPException(status_code=404, detail="Reminder not found")
    reference.update({"status": "acknowledged", "acknowledged_at": firestore.SERVER_TIMESTAMP})
    return {"reminder_id": reminder_id, "status": "acknowledged"}


@router.post("/{reminder_id}/escalate")
def escalate_reminder(reminder_id: str) -> Dict[str, str]:
    """Manually escalate a reminder and notify connected caregivers."""
    try:
        process_escalation(reminder_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return {"reminder_id": reminder_id, "status": "escalated"}
