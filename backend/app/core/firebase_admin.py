import logging
import os
from typing import Any, Dict, Optional

import firebase_admin
from firebase_admin import credentials, initialize_app

logger = logging.getLogger(__name__)


class FirebaseInitializationError(RuntimeError):
    """Raised when the Firebase Admin SDK cannot be initialized."""
    pass


def init_firebase() -> Any:
    """Initialize Firebase Admin SDK using service account file or environment variables."""
    if firebase_admin._apps:
        return firebase_admin.get_app()

    # 1. Check for explicit path or local service-account-key.json
    cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH") or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not cred_path:
        local_candidate = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "service-account-key.json")
        if os.path.exists(local_candidate):
            cred_path = local_candidate

    if cred_path and os.path.exists(cred_path):
        try:
            cred = credentials.Certificate(cred_path)
            return initialize_app(cred)
        except Exception as exc:
            logger.warning("Could not initialize Firebase from file %s: %s", cred_path, exc)

    # 2. Check for required environment variables
    private_key = os.environ.get("FIREBASE_PRIVATE_KEY", "").strip()
    client_email = os.environ.get("FIREBASE_CLIENT_EMAIL", "").strip()
    project_id = os.environ.get("FIREBASE_PROJECT_ID", "").strip()

    if private_key and client_email and project_id:
        try:
            cred_dict = {
                "type": os.environ.get("FIREBASE_TYPE", "service_account"),
                "project_id": project_id,
                "private_key_id": os.environ.get("FIREBASE_PRIVATE_KEY_ID", ""),
                "private_key": private_key.replace("\\n", "\n"),
                "client_email": client_email,
                "client_id": os.environ.get("FIREBASE_CLIENT_ID", ""),
                "auth_uri": os.environ.get("FIREBASE_AUTH_URI", "https://accounts.google.com/o/oauth2/auth"),
                "token_uri": os.environ.get("FIREBASE_TOKEN_URI", "https://oauth2.googleapis.com/token"),
                "auth_provider_x509_cert_url": os.environ.get(
                    "FIREBASE_AUTH_PROVIDER_X509_CERT_URL",
                    "https://www.googleapis.com/oauth2/v1/certs",
                ),
                "client_x509_cert_url": os.environ.get("FIREBASE_CLIENT_X509_CERT_URL", ""),
            }
            cred = credentials.Certificate(cred_dict)
            return initialize_app(cred)
        except Exception as exc:
            logger.error("Could not initialize Firebase from env vars: %s", exc)
            raise FirebaseInitializationError(f"Failed to initialize Firebase credentials: {exc}") from exc

    # 3. Fallback: default credentials (e.g. on GCP/Cloud Run)
    try:
        return initialize_app()
    except Exception as exc:
        raise FirebaseInitializationError(
            f"Firebase credentials not configured or available: {exc}"
        ) from exc


def get_firestore():
    """Retrieve Firestore client singleton."""
    init_firebase()
    from firebase_admin import firestore
    return firestore.client()


def get_auth():
    """Retrieve Firebase Auth module."""
    init_firebase()
    from firebase_admin import auth
    return auth


def verify_firebase_token(id_token: str) -> Optional[Dict[str, Any]]:
    """Verify Firebase ID token and return decoded token dict or None."""
    try:
        init_firebase()
        from firebase_admin import auth
        return auth.verify_id_token(id_token)
    except FirebaseInitializationError:
        raise
    except Exception as exc:
        logger.warning("Firebase token verification failed: %s", exc)
        return None