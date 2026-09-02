"""Live Firestore smoke test for the application service layer."""

import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.core.firestore_service import FirestoreService  # noqa: E402


def main() -> None:
    service = FirestoreService()
    uid = f"firestore-test-{uuid.uuid4().hex}"
    patient_id = ""
    consent_id = ""
    try:
        service.create_user(uid, {"email": f"{uid}@example.test", "role": "caregiver"})
        assert service.get_user(uid), "created user could not be read"
        print("✅ User create/read passed")

        patient_id = service.create_patient({"name": "Firestore Test Patient", "caregiver_uid": uid})
        assert service.get_patient(patient_id), "created patient could not be read"
        print("✅ Patient create/read passed")

        service.update_cognitive_score(patient_id, "memory", {"score": 87, "source": "test"})
        scores = service.get_cognitive_scores(patient_id)
        assert scores["memory"]["score"] == 87, "cognitive score was not stored"
        print("✅ Cognitive score update/read passed")

        consent_id = service.create_consent(patient_id, {"type": "research", "granted": True})
        consents = service.get_consents(patient_id)
        assert any(consent["id"] == consent_id for consent in consents), "consent was not read back"
        print("✅ Consent create/read passed")
        print("✅ ALL TESTS PASSED!")
    finally:
        if patient_id:
            patient_ref = service.client.collection("patients").document(patient_id)
            for subcollection in ("cognitive_scores", "consents"):
                for document in patient_ref.collection(subcollection).stream():
                    document.reference.delete()
            patient_ref.delete()
        service.client.collection("users").document(uid).delete()
        print("🧹 Test data cleaned up")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"❌ Firestore service tests failed: {exc}")
        raise SystemExit(1) from exc