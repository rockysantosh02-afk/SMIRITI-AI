"""Application service for Smriti AI Firestore operations."""

import logging
from typing import Any, Dict, List, Optional

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
            data["updated_at"] = firestore.SERVER_TIMESTAMP
            self.client.collection("users").document(uid).update(data)
        except GoogleCloudError as exc:
            logger.exception("Failed to update user %s", uid)
            raise FirestoreServiceError(f"Could not update user '{uid}': {exc}") from exc

    def create_patient(self, patient_data: Dict[str, Any]) -> str:
        """Create a patient document and return its generated document ID."""
        try:
            data = dict(patient_data)
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

    def get_patients_by_caregiver(self, caregiver_uid: str) -> List[Dict[str, Any]]:
        """Return all patients whose caregiver UID matches the supplied UID."""
        try:
            query = self.client.collection("patients").where(
                "caregiver_uid", "==", caregiver_uid
            )
            return [self._with_id(document) for document in query.stream()]
        except GoogleCloudError as exc:
            logger.exception("Failed to list patients for caregiver %s", caregiver_uid)
            raise FirestoreServiceError(
                f"Could not list patients for caregiver '{caregiver_uid}': {exc}"
            ) from exc

    def update_patient_scores(self, patient_id: str, scores: Dict[str, Any]) -> None:
        """Merge summary scores into a patient document."""
        try:
            self.client.collection("patients").document(patient_id).set(
                {"scores": scores, "updated_at": firestore.SERVER_TIMESTAMP}, merge=True
            )
        except GoogleCloudError as exc:
            logger.exception("Failed to update scores for patient %s", patient_id)
            raise FirestoreServiceError(f"Could not update patient scores '{patient_id}': {exc}") from exc

    def update_cognitive_score(self, patient_id: str, domain: str, score_data: Dict[str, Any]) -> None:
        """Create or update a domain score under a patient and timestamp it."""
        try:
            data = dict(score_data)
            data["domain"] = domain
            data["updated_at"] = firestore.SERVER_TIMESTAMP
            self.client.collection("patients").document(patient_id).collection(
                "cognitive_scores"
            ).document(domain).set(data, merge=True)
        except GoogleCloudError as exc:
            logger.exception("Failed to update %s score for patient %s", domain, patient_id)
            raise FirestoreServiceError(f"Could not update cognitive score '{domain}': {exc}") from exc

    def get_cognitive_scores(self, patient_id: str) -> Dict[str, Any]:
        """Return cognitive scores keyed by domain for a patient."""
        try:
            scores: Dict[str, Any] = {}
            for document in self.client.collection("patients").document(patient_id).collection(
                "cognitive_scores"
            ).stream():
                scores[document.id] = document.to_dict() or {}
            return scores
        except GoogleCloudError as exc:
            logger.exception("Failed to read cognitive scores for patient %s", patient_id)
            raise FirestoreServiceError(f"Could not read cognitive scores '{patient_id}': {exc}") from exc

    def create_consent(self, patient_id: str, consent_data: Dict[str, Any]) -> str:
        """Create a consent record and return its generated document ID."""
        try:
            data = dict(consent_data)
            data["patient_id"] = patient_id
            data["created_at"] = firestore.SERVER_TIMESTAMP
            return self.client.collection("patients").document(patient_id).collection(
                "consents"
            ).add(data)[1].id
        except GoogleCloudError as exc:
            logger.exception("Failed to create consent for patient %s", patient_id)
            raise FirestoreServiceError(f"Could not create consent '{patient_id}': {exc}") from exc

    def get_consents(self, patient_id: str) -> List[Dict[str, Any]]:
        """Return all consent records for a patient."""
        try:
            documents = self.client.collection("patients").document(patient_id).collection(
                "consents"
            ).stream()
            return [self._with_id(document) for document in documents]
        except GoogleCloudError as exc:
            logger.exception("Failed to read consents for patient %s", patient_id)
            raise FirestoreServiceError(f"Could not read consents '{patient_id}': {exc}") from exc