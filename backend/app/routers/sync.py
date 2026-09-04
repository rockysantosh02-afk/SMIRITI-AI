"""Authenticated synchronization for offline user-owned writes."""

from datetime import datetime
from typing import Any, Dict, List

from fastapi import APIRouter, Depends, HTTPException

from app.core.dependencies import get_current_user
from app.dependencies import get_firestore_service
from app.core.firestore_service import FirestoreService
from app.schemas.api import SyncRequest, SyncResponse, SyncResult

router = APIRouter(prefix="/sync", tags=["sync"])
_COLLECTIONS = {
    "game_sessions": "game_sessions",
    "cognitive_scores": "user_scores",
    "journal_entries": "journal_entries",
    "reminders": "reminders",
}




@router.post("")
@router.post("/batch")
def sync_records(
    request: SyncRequest,
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> SyncResponse:
    """Synchronize user-owned records without cross-user merging."""
    results: List[SyncResult] = []
    successful_record_ids: List[str] = []
    user_id = current_user["uid"]
    for record in request.records:
        record_id = record.client_generated_id
        if record.collection not in _COLLECTIONS:
            results.append(SyncResult(client_generated_id=record_id, status="validation_error", error="unsupported collection"))
            continue
        if record.data.get("user_id") not in (None, user_id):
            results.append(SyncResult(client_generated_id=record_id, status="validation_error", error="user_id does not match authenticated user"))
            continue
        if not _valid_record(record.collection, record.data):
            results.append(SyncResult(client_generated_id=record_id, status="validation_error", error="required fields or timestamp are invalid"))
            continue
        try:
            collection = _COLLECTIONS[record.collection]
            reference = service.client.collection(collection).document(record_id)
            existing = reference.get()
            if existing.exists:
                existing_data = existing.to_dict() or {}
                if existing_data.get("user_id") != user_id:
                    results.append(SyncResult(client_generated_id=record_id, status="validation_error", error="record belongs to another user"))
                else:
                    results.append(SyncResult(client_generated_id=record_id, status="duplicate"))
                    successful_record_ids.append(record_id)
                continue
            data = {key: value for key, value in record.data.items() if key != "user_id"}
            data.update({"user_id": user_id, "client_generated_id": record_id})
            reference.set(data)
            results.append(SyncResult(client_generated_id=record_id, status="success"))
            successful_record_ids.append(record_id)
        except Exception:
            results.append(SyncResult(client_generated_id=record_id, status="failed", error="record could not be stored"))
    return SyncResponse(results=results, successful_record_ids=successful_record_ids)


def _valid_record(collection: str, data: Dict[str, Any]) -> bool:
    """Validate only fields required to safely persist an offline record."""
    timestamp = data.get("created_at") or data.get("played_at") or data.get("scheduled_time")
    if timestamp is not None:
        if isinstance(timestamp, datetime):
            pass
        elif isinstance(timestamp, str):
            try:
                datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
            except ValueError:
                return False
        else:
            return False
    required = {
        "game_sessions": ("game_id", "game_code"),
        "cognitive_scores": ("domain",),
        "journal_entries": (),
        "reminders": ("label", "type", "scheduled_time"),
    }[collection]
    return any(field in data and data[field] not in (None, "") for field in required) if required else True
