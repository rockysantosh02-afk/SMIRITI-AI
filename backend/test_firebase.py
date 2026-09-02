"""Basic Firebase Admin SDK and environment configuration checks."""

import sys
from pathlib import Path

from google.api_core.exceptions import GoogleAPIError
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.core.config import settings  # noqa: E402
from app.core.firebase_admin import get_firestore  # noqa: E402
from app.main import app  # noqa: E402


def test_environment_variables() -> None:
    required_values = {
        "FIREBASE_PROJECT_ID": settings.FIREBASE_PROJECT_ID,
        "FIREBASE_STORAGE_BUCKET": settings.FIREBASE_STORAGE_BUCKET,
        "SECRET_KEY": settings.SECRET_KEY,
        "ALGORITHM": settings.ALGORITHM,
    }
    missing = [name for name, value in required_values.items() if not value]
    if missing:
        raise AssertionError(f"Missing configuration: {', '.join(missing)}")
    print("✅ Environment variables loaded correctly")


def test_firestore_connection() -> None:
    document_ref = get_firestore().collection("_connection_tests").document("smoke-test")
    try:
        document_ref.set({"status": "ok"})
        if document_ref.get().to_dict() != {"status": "ok"}:
            raise AssertionError("Firestore test document contents were incorrect")
        print("✅ Firestore connection works")
    finally:
        try:
            document_ref.delete()
        except GoogleAPIError as exc:
            print(f"⚠️ Could not delete Firestore test document: {exc}")


def test_server_endpoints() -> None:
    """Verify startup, documentation, and authentication route registration."""
    client = TestClient(app)
    assert client.get("/").status_code == 200
    assert client.get("/health").status_code == 200
    assert client.get("/docs").status_code == 200
    auth_status = client.post("/auth/firebase-login", json={"id_token": "invalid"}).status_code
    assert auth_status in {401, 503}, f"unexpected Firebase login status: {auth_status}"
    assert client.post("/auth/firebase-verify").status_code == 401
    openapi_paths = client.get("/openapi.json").json()["paths"]
    required_paths = {"/auth/firebase-login", "/auth/firebase-verify", "/test-firestore"}
    assert required_paths.issubset(openapi_paths), "required routes missing from OpenAPI docs"
    firestore_status = client.get("/test-firestore").status_code
    assert firestore_status in {200, 503}, f"unexpected Firestore endpoint status: {firestore_status}"
    print("✅ Server endpoints and Swagger documentation passed")


if __name__ == "__main__":
    try:
        test_environment_variables()
        test_server_endpoints()
        test_firestore_connection()
    except Exception as exc:
        print(f"❌ Firebase tests failed: {exc}")
        raise SystemExit(1) from exc
    print("✅ ALL TESTS PASSED!")