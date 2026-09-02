"""Memory Vault endpoints."""

from typing import Any, Dict, List
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore
from pydantic import BaseModel, Field

from app.core.firestore_service import FirestoreService
from app.dependencies import get_firestore_service
from app.core.dependencies import get_current_active_user
from app.services.content_guard import guard_content
from app.services.story_generator import generate_story

router = APIRouter(prefix="/memory", tags=["memory"])


class PersonRequest(BaseModel):
    patient_id: str
    name: str
    relationship: str


class PhotoRequest(BaseModel):
    patient_id: str
    storage_path: str
    caption: str = ""
    face_clusters: List[Dict[str, Any]] = Field(default_factory=list)


class StoryRequest(BaseModel):
    patient_id: str
    person_ids: List[str] = Field(default_factory=list)
    event_ids: List[str] = Field(default_factory=list)


class StoryAction(BaseModel):
    action: str


class EventRequest(BaseModel):
    patient_id: str
    title: str
    description: str = ""


def _create(service: FirestoreService, collection: str, data: Dict[str, Any]) -> str:
    reference = service.client.collection(collection).document(uuid4().hex)
    reference.set({**data, "created_at": firestore.SERVER_TIMESTAMP})
    return reference.id


def _list(service: FirestoreService, collection: str, patient_id: str) -> List[Dict[str, Any]]:
    return [{"id": doc.id, **(doc.to_dict() or {})} for doc in service.client.collection(collection).where("patient_id", "==", patient_id).stream()]


@router.post("/persons")
def create_person(request: PersonRequest, service: FirestoreService = Depends(get_firestore_service)) -> Dict[str, str]:
    """Create a Memory Vault person."""
    return {"person_id": _create(service, "memory_persons", request.model_dump())}


@router.get("/persons/{patient_id}")
def list_persons(patient_id: str, service: FirestoreService = Depends(get_firestore_service)) -> List[Dict[str, Any]]:
    """List Memory Vault persons for a patient."""
    return _list(service, "memory_persons", patient_id)


@router.post("/photos")
def create_photo(request: PhotoRequest, service: FirestoreService = Depends(get_firestore_service)) -> Dict[str, str]:
    """Create a photo record."""
    return {"photo_id": _create(service, "memory_photos", request.model_dump())}


@router.get("/photos/{patient_id}")
def list_photos(patient_id: str, service: FirestoreService = Depends(get_firestore_service)) -> List[Dict[str, Any]]:
    """List photo records for a patient."""
    return _list(service, "memory_photos", patient_id)


@router.post("/events")
def create_event(request: EventRequest, service: FirestoreService = Depends(get_firestore_service)) -> Dict[str, str]:
    """Create a Memory Vault event."""
    return {"event_id": _create(service, "memory_events", request.model_dump())}


@router.get("/events/{patient_id}")
def list_events(patient_id: str, service: FirestoreService = Depends(get_firestore_service)) -> List[Dict[str, Any]]:
    """List Memory Vault events for a patient."""
    return _list(service, "memory_events", patient_id)


@router.post("/stories/generate")
def create_story(request: StoryRequest, service: FirestoreService = Depends(get_firestore_service)) -> Dict[str, str]:
    """Generate and save a pending, safety-checked story."""
    persons = [service.client.collection("memory_persons").document(item).get().to_dict() or {} for item in request.person_ids]
    events = [service.client.collection("memory_events").document(item).get().to_dict() or {} for item in request.event_ids]
    text = guard_content(generate_story(persons, events))
    story_id = _create(service, "memory_stories", {"patient_id": request.patient_id, "content": text, "status": "pending"})
    return {"story_id": story_id, "status": "pending"}


@router.put("/stories/{story_id}/approve")
def approve_story(story_id: str, request: StoryAction, service: FirestoreService = Depends(get_firestore_service), current_user: Dict[str, Any] = Depends(get_current_active_user)) -> Dict[str, str]:
    """Approve or reject a story; only caregiver users may perform this action."""
    if current_user.get("role") != "caregiver":
        raise HTTPException(status_code=403, detail="Only caregivers can approve stories")
    if request.action not in {"approve", "reject"}:
        raise HTTPException(status_code=400, detail="action must be approve or reject")
    reference = service.client.collection("memory_stories").document(story_id)
    if not reference.get().exists:
        raise HTTPException(status_code=404, detail="Story not found")
    reference.update({"status": "approved" if request.action == "approve" else "rejected", "updated_at": firestore.SERVER_TIMESTAMP})
    return {"story_id": story_id, "status": "approved" if request.action == "approve" else "rejected"}
