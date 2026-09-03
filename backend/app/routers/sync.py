"""Authenticated synchronization for offline user-owned writes."""

from typing import Any, Dict, List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.dependencies import get_current_user
from app.dependencies import get_firestore_service
from app.core.firestore_service import FirestoreService

router = APIRouter(prefix="/sync", tags=["sync"])
_ALLOWED_COLLECTIONS = {"journal_entries", "reminders"}


class SyncRecord(BaseModel):
    collection: str
    client_generated_id: str = Field(min_length=1)
    data: Dict[str, Any] = Field(default_factory=dict)


class SyncRequest(BaseModel):
    records: List[SyncRecord] = Field(default_factory=list)


@router.post("")
@router.post("/batch")
def sync_records(
    request: SyncRequest,
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, List[str]]:
    """Write offline records for the authenticated user without cross-user merging."""
    synced: List[str] = []
    user_id = current_user["uid"]
    for record in request.records:
        if record.collection not in _ALLOWED_COLLECTIONS:
            raise HTTPException(status_code=400, detail="Unsupported sync collection")
        reference = service.client.collection(record.collection).document(record.client_generated_id)
        existing = reference.get()
        if existing.exists:
            existing_data = existing.to_dict() or {}
            if existing_data.get("user_id") != user_id:
                raise HTTPException(status_code=404, detail="Synchronized record not found")
            synced.append(record.client_generated_id)
            continue
        reference.set({**record.data, "user_id": user_id, "client_generated_id": record.client_generated_id})
        synced.append(record.client_generated_id)
    return {"synced": synced}
