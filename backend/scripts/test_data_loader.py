"""Load deterministic sample data into Firestore."""

from app.core.firebase_admin import get_firestore


def main() -> None:
    db = get_firestore()
    db.collection("patients").document("demo-patient").set({"name": "Demo Patient", "caregiver_uid": "demo-caregiver"})
    print("Loaded demo patient data.")


if __name__ == "__main__":
    main()
