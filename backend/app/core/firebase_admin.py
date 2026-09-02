"""Firebase Admin SDK setup and access helpers."""

import logging
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import auth, credentials, firestore, storage

from app.core.config import settings

logger = logging.getLogger(__name__)


class FirebaseInitializationError(RuntimeError):
    """Raised when the Firebase Admin app cannot be initialized."""


_firebase_app: firebase_admin.App | None = None


def _credential_path() -> Path:
    configured_path = Path(settings.FIREBASE_CREDENTIALS_PATH)
    if configured_path.is_absolute():
        return configured_path
    return Path(__file__).resolve().parents[2] / configured_path


def _get_firebase_app() -> firebase_admin.App:
    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    if firebase_admin._apps:
        _firebase_app = firebase_admin.get_app()
        return _firebase_app

    key_path = _credential_path()
    if not key_path.is_file():
        logger.error("Firebase service account file not found: %s", key_path)
        raise FirebaseInitializationError(
            f"Firebase service account file not found: {key_path}"
        )

    try:
        firebase_credential = credentials.Certificate(str(key_path))
        options: dict[str, Any] = {}
        if settings.FIREBASE_STORAGE_BUCKET:
            options["storageBucket"] = settings.FIREBASE_STORAGE_BUCKET
        if settings.FIREBASE_PROJECT_ID:
            options["projectId"] = settings.FIREBASE_PROJECT_ID
        _firebase_app = firebase_admin.initialize_app(firebase_credential, options)
        logger.info("Firebase Admin SDK initialized for %s", settings.FIREBASE_PROJECT_ID or "service account project")
        return _firebase_app
    except Exception as exc:
        logger.exception("Failed to initialize Firebase Admin SDK")
        raise FirebaseInitializationError("Failed to initialize Firebase Admin SDK") from exc


def get_firestore() -> firestore.Client:
    """Return the Firestore client for the configured Firebase project."""
    return firestore.client(app=_get_firebase_app())


def get_storage_bucket() -> storage.bucket:
    """Return the configured Firebase Cloud Storage bucket."""
    if not settings.FIREBASE_STORAGE_BUCKET:
        logger.error("FIREBASE_STORAGE_BUCKET is not configured")
        raise FirebaseInitializationError("FIREBASE_STORAGE_BUCKET is not configured")
    return storage.bucket(name=settings.FIREBASE_STORAGE_BUCKET, app=_get_firebase_app())


def verify_firebase_token(id_token: str, check_revoked: bool = False) -> dict[str, Any] | None:
    """Verify a Firebase ID token, returning claims or None for invalid tokens."""
    try:
        return auth.verify_id_token(
            id_token, app=_get_firebase_app(), check_revoked=check_revoked
        )
    except (auth.InvalidIdTokenError, auth.ExpiredIdTokenError, auth.RevokedIdTokenError) as exc:
        logger.warning("Firebase ID token validation failed: %s", exc)
        return None
    except Exception:
        logger.exception("Unexpected error while validating Firebase ID token")
        return None