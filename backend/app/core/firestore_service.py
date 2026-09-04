"""Application service for Smriti AI Firestore operations."""

import logging
from typing import Any, Dict, Optional

from google.cloud.exceptions import GoogleCloudError
from firebase_admin import firestore

from app.core.firebase_admin import get_firestore

logger = logging.getLogger(__name__)


class FirestoreServiceError(RuntimeError):
    """Raised when a Firestore operation cannot be completed."""


class FirestoreService:
    """Encapsulate all application-facing Firestore reads and writes."""

    def __init__(self, client: Optional[firestore.Client] = None) -> None:
        self.client = client or get_firestore()

    @staticmethod
    def _with_id(document: firestore.DocumentSnapshot) -> Dict[str, Any]:
        data = document.to_dict() or {}
        data["id"] = document.id
        return data

    def create_user(self, uid: str, user_data: Dict[str, Any]) -> str:
        """Create or overwrite a user document and return its document ID."""
        try:
            data = dict(user_data)
            data["uid"] = uid
            data["user_id"] = uid
            data["created_at"] = firestore.SERVER_TIMESTAMP
            data["updated_at"] = firestore.SERVER_TIMESTAMP
            self.client.collection("users").document(uid).set(data)
            return uid
        except GoogleCloudError as exc:
            logger.exception("Failed to create user %s", uid)
            raise FirestoreServiceError(f"Could not create user '{uid}': {exc}") from exc

    def get_user(self, uid: str) -> Optional[Dict[str, Any]]:
        """Return a user by Firebase UID, or None when it does not exist."""
        try:
            document = self.client.collection("users").document(uid).get()
            return self._with_id(document) if document.exists else None
        except GoogleCloudError as exc:
            logger.exception("Failed to read user %s", uid)
            raise FirestoreServiceError(f"Could not read user '{uid}': {exc}") from exc

    def update_user(self, uid: str, user_data: Dict[str, Any]) -> None:
        """Update fields on a user document and refresh its update timestamp."""
        try:
            data = dict(user_data)
            data["user_id"] = uid
            data.pop("uid", None)
            data["updated_at"] = firestore.SERVER_TIMESTAMP
            self.client.collection("users").document(uid).update(data)
        except GoogleCloudError as exc:
            logger.exception("Failed to update user %s", uid)
            raise FirestoreServiceError(f"Could not update user '{uid}': {exc}") from exc

    def create_patient(self, user_id: str, patient_data: Dict[str, Any]) -> str:
        """Create a user-owned patient document and return its generated ID."""
        try:
            data = dict(patient_data)
            data["user_id"] = user_id
            data["created_at"] = firestore.SERVER_TIMESTAMP
            data["updated_at"] = firestore.SERVER_TIMESTAMP
            return self.client.collection("patients").add(data)[1].id
        except GoogleCloudError as exc:
            logger.exception("Failed to create patient")
            raise FirestoreServiceError(f"Could not create patient: {exc}") from exc

    def get_patient(self, patient_id: str) -> Optional[Dict[str, Any]]:
        """Return a patient by ID, or None when it does not exist."""
        try:
            document = self.client.collection("patients").document(patient_id).get()
            return self._with_id(document) if document.exists else None
        except GoogleCloudError as exc:
            logger.exception("Failed to read patient %s", patient_id)
            raise FirestoreServiceError(f"Could not read patient '{patient_id}': {exc}") from exc

    def update_cognitive_score(self, user_id: str, domain: str, score_data: Dict[str, Any]) -> None:
        """Create or update a user-owned domain score."""
        try:
            data = dict(score_data)
            data["user_id"] = user_id
            data["domain"] = domain
            data.setdefault("score_id", f"{user_id}_{domain}")
            data.setdefault("attempt_count", 0)
            data.setdefault("difficulty_level", 1)
            data.setdefault("reason", "This level looks like a good match for now.")
            data.setdefault("composite_score", data.get("composite", 0.0))
            data["updated_at"] = firestore.SERVER_TIMESTAMP
            self.client.collection("user_scores").document(f"{user_id}_{domain}").set(data, merge=True)
        except GoogleCloudError as exc:
            logger.exception("Failed to update %s score for user %s", domain, user_id)
            raise FirestoreServiceError(f"Could not update cognitive score '{domain}': {exc}") from exc

    def get_cognitive_scores(self, user_id: str) -> Dict[str, Any]:
        """Return cognitive scores keyed by domain for a user."""
        try:
            scores: Dict[str, Any] = {}
            for document in self.client.collection("user_scores").where("user_id", "==", user_id).stream():
                scores[document.to_dict().get("domain", document.id)] = document.to_dict() or {}
            return scores
        except GoogleCloudError as exc:
            logger.exception("Failed to read cognitive scores for user %s", user_id)
            raise FirestoreServiceError(f"Could not read cognitive scores '{user_id}': {exc}") from exc
