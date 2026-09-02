"""Delete documents with the test-data prefix."""

from app.core.firebase_admin import get_firestore

for collection in ("patients", "users", "reminders", "alerts", "game_sessions", "game_attempts"):
    for document in get_firestore().collection(collection).stream():
        if document.id.startswith(("test-", "demo-", "integration-")):
            document.reference.delete()
print("Test data cleanup complete.")
