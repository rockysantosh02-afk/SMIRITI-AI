"""Authenticated synchronization for offline user-owned writes."""

from datetime import datetime
from typing import Any, Dict, List

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore

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
    "game_attempts": "game_attempts",
    "attempts": "game_attempts",
}


@router.post("")
@router.post("/batch")
def sync_records(
    request: SyncRequest,
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> SyncResponse:
    """Synchronize user-owned records supporting create, update, and delete operations."""
    results: List[SyncResult] = []
    successful_record_ids: List[str] = []
    user_id = current_user["uid"]

    for record in request.records:
        record_id = record.client_generated_id
        if record.collection not in _COLLECTIONS:
            results.append(
                SyncResult(
                    client_generated_id=record_id,
                    status="validation_error",
                    error="unsupported collection",
                )
            )
            continue

        if record.data.get("user_id") not in (None, user_id):
            results.append(
                SyncResult(
                    client_generated_id=record_id,
                    status="validation_error",
                    error="user_id does not match authenticated user",
                )
            )
            continue

        if not _valid_record(record.collection, record.data, record.operation):
            results.append(
                SyncResult(
                    client_generated_id=record_id,
                    status="validation_error",
                    error="required fields or timestamp are invalid",
                )
            )
            continue

        try:
            collection = _COLLECTIONS[record.collection]
            reference = service.client.collection(collection).document(record_id)
            existing = reference.get()
            existing_data = existing.to_dict() or {} if existing.exists else None

            # Cross-user modification prevention
            if existing_data is not None and existing_data.get("user_id") != user_id:
                results.append(
                    SyncResult(
                        client_generated_id=record_id,
                        status="validation_error",
                        error="record belongs to another user",
                    )
                )
                continue

            # Operation-aware synchronization:
            if record.operation == "delete":
                if existing.exists:
                    reference.set(
                        {
                            "deleted": True,
                            "updated_at": firestore.SERVER_TIMESTAMP,
                        },
                        merge=True,
                    )
                results.append(SyncResult(client_generated_id=record_id, status="success"))
                successful_record_ids.append(record_id)

            elif record.operation == "update":
                data = {key: value for key, value in record.data.items() if key != "user_id"}
                data.update({
                    "user_id": user_id,
                    "client_generated_id": record_id,
                    "updated_at": firestore.SERVER_TIMESTAMP,
                })
                if not existing.exists:
                    data.setdefault("created_at", firestore.SERVER_TIMESTAMP)
                    data.setdefault("deleted", False)
                    reference.set(data)
                else:
                    reference.set(data, merge=True)
                results.append(SyncResult(client_generated_id=record_id, status="success"))
                successful_record_ids.append(record_id)

            else:  # "create" (default)
                if existing.exists:
                    # Idempotent duplicate: existing record already saved for this user
                    results.append(SyncResult(client_generated_id=record_id, status="duplicate"))
                    successful_record_ids.append(record_id)
                else:
                    data = {key: value for key, value in record.data.items() if key != "user_id"}
                    data.update({
                        "user_id": user_id,
                        "client_generated_id": record_id,
                        "created_at": firestore.SERVER_TIMESTAMP,
                        "updated_at": firestore.SERVER_TIMESTAMP,
                        "deleted": False,
                    })
                    reference.set(data)
                    results.append(SyncResult(client_generated_id=record_id, status="success"))
                    successful_record_ids.append(record_id)

        except Exception:
            results.append(
                SyncResult(
                    client_generated_id=record_id,
                    status="failed",
                    error="record could not be stored",
                )
            )

    return SyncResponse(results=results, successful_record_ids=successful_record_ids)


@router.get("/journal-entries")
def pull_journal_entries(
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, Any]:
    """Pull journal entries owned by the authenticated user."""
    return _pull_collection_records(service, "journal_entries", current_user["uid"])


@router.get("/reminders")
def pull_reminders(
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, Any]:
    """Pull reminders owned by the authenticated user."""
    return _pull_collection_records(service, "reminders", current_user["uid"])


@router.get("/cognitive-scores")
def pull_cognitive_scores(
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, Any]:
    """Pull cognitive scores owned by the authenticated user."""
    return _pull_collection_records(service, "user_scores", current_user["uid"])


@router.get("/game-sessions")
def pull_game_sessions(
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, Any]:
    """Pull game sessions owned by the authenticated user."""
    return _pull_collection_records(service, "game_sessions", current_user["uid"])


@router.get("/{collection_name}")
def pull_generic_collection(
    collection_name: str,
    service: FirestoreService = Depends(get_firestore_service),
    current_user: Dict[str, Any] = Depends(get_current_user),
) -> Dict[str, Any]:
    """Pull records from any supported collection owned by the authenticated user."""
    if collection_name not in _COLLECTIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported collection: {collection_name}",
        )
    target = _COLLECTIONS[collection_name]
    return _pull_collection_records(service, target, current_user["uid"])


def _pull_collection_records(
    service: FirestoreService, collection: str, user_id: str
) -> Dict[str, Any]:
    """Helper to query Firestore collection by user_id and return serialized items."""
    try:
        docs = (
            service.client.collection(collection)
            .where("user_id", "==", user_id)
            .stream()
        )
        items = []
        for doc in docs:
            d = doc.to_dict() or {}
            d.setdefault("id", doc.id)
            d.setdefault("client_generated_id", doc.id)
            for k in (
                "created_at",
                "updated_at",
                "scheduled_time",
                "completed_at",
                "started_at",
                "last_fired_at",
            ):
                val = d.get(k)
                if isinstance(val, datetime):
                    d[k] = val.isoformat()
                elif hasattr(val, "isoformat"):
                    d[k] = val.isoformat()
            items.append(d)
        return {"items": items, "count": len(items)}
    except Exception as e:
        return {"items": [], "count": 0, "error": str(e)}


def _valid_record(collection: str, data: Dict[str, Any], operation: str = "create") -> bool:
    """Validate only fields required to safely persist an offline record."""
    if operation == "delete":
        return True

    timestamp = (
        data.get("created_at")
        or data.get("played_at")
        or data.get("scheduled_time")
        or data.get("started_at")
    )
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
        "reminders": ("label", "title"),
        "game_attempts": ("session_id",),
        "attempts": ("session_id",),
    }.get(collection, ())

    return any(field in data and data[field] not in (None, "") for field in required) if required else True
