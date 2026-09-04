"""FastAPI dependencies shared by routers."""

from fastapi import Depends

from app.core.firestore_service import FirestoreService


def get_firestore_service() -> FirestoreService:
    """Provide a Firestore service instance for a request."""
    return FirestoreService()
