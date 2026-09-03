"""Smoke-test every HTTP endpoint against a running backend.

From backend/: python scripts/test_all_apis.py
Optional: API_BASE_URL, FIREBASE_ID_TOKEN, CAREGIVER_TOKEN.
"""

import json
import os
import sys
import urllib.error
import urllib.request

BASE = os.getenv("API_BASE_URL", "http://127.0.0.1:8000").rstrip("/")
PASSED = FAILED = SKIPPED = 0


def call(method, path, body=None, expected=(200,), token=None):
    global PASSED, FAILED
    data = json.dumps(body).encode() if body is not None else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            status, raw = response.status, response.read()
    except urllib.error.HTTPError as error:
        status, raw = error.code, error.read()
    try:
        payload = json.loads(raw.decode()) if raw else {}
    except json.JSONDecodeError:
        payload = raw.decode(errors="replace")
    label = f"{method} {path}"
    if status in expected:
        PASSED += 1
        print(f"PASS {label} [{status}]")
    else:
        FAILED += 1
        print(f"FAIL {label}: expected {expected}, got {status}: {payload}")
    return payload if isinstance(payload, dict) else {}, status


def assert_keys(payload, keys, label):
    missing = set(keys) - set(payload)
    if missing:
        print(f"FAIL {label}: missing response keys {sorted(missing)}")
        raise AssertionError(missing)


def skip(label):
    global SKIPPED
    SKIPPED += 1
    print(f"SKIP {label}")


def main():
    call("GET", "/")
    call("GET", "/health")
    call("GET", "/test-firestore")
    setup, _ = call("GET", "/test/setup")
    patient_id = setup.get("patient_id", "")
    session_id = setup.get("session_id", "")
    games, _ = call("GET", "/games")
    if not isinstance(games, list) or not games:
        raise AssertionError("GET /games returned no games")
    game_code = games[0]["code"] if games else "matching_image"
    created, _ = call("POST", "/test/create-session/" + game_code)
    session_id = created.get("session_id", session_id)
    game_session, _ = call("POST", "/games/session", {"patient_id": patient_id, "game_code": game_code})
    session_id = game_session.get("session_id", session_id)
    call("GET", f"/games/next-round/{session_id}")
    call("POST", "/games/attempt", {"session_id": session_id, "selected_index": 0, "response_time_ms": 1000})
    call("GET", f"/games/scores/{patient_id}")

    person, _ = call("POST", "/memory/persons", {"patient_id": patient_id, "name": "Alex", "relationship": "friend"})
    call("GET", f"/memory/persons/{patient_id}")
    call("POST", "/memory/photos", {"patient_id": patient_id, "storage_path": "test/alex.jpg", "caption": "Test photo"})
    call("GET", f"/memory/photos/{patient_id}")
    event, _ = call("POST", "/memory/events", {"patient_id": patient_id, "title": "Birthday", "description": "Test event"})
    call("GET", f"/memory/events/{patient_id}")
    story, _ = call("POST", "/memory/stories/generate", {"patient_id": patient_id, "person_ids": [person.get("person_id", "")], "event_ids": [event.get("event_id", "")]})

    reminder, _ = call("POST", "/reminders", {"patient_id": patient_id, "label": "Medicine", "type": "medication", "scheduled_time": "2099-01-01T09:00:00Z"})
    reminder_id = reminder.get("reminder_id", "")
    call("GET", "/reminders/check-due")
    call("GET", f"/reminders/{patient_id}")
    call("PUT", f"/reminders/{reminder_id}/acknowledge")
    escalated, _ = call("POST", "/reminders/missing/escalate", expected=(200, 404))
    if escalated and "status" in escalated:
        assert_keys(escalated, ("reminder_id", "status"), "POST /reminders/{id}/escalate")

    firebase_token = os.getenv("FIREBASE_ID_TOKEN")
    if firebase_token:
        login, _ = call("POST", "/auth/firebase-login", {"id_token": firebase_token})
        token = login.get("access_token")
        call("POST", "/auth/firebase-verify", token=token or firebase_token)
        call("GET", "/auth/me", token=token)
        call("POST", "/auth/logout", token=token)
        if story.get("story_id"):
            caregiver = os.getenv("CAREGIVER_TOKEN", token)
            call("PUT", f"/memory/stories/{story['story_id']}/approve", {"action": "approve"}, token=caregiver)
    else:
        for label in ("POST /auth/firebase-login", "POST /auth/firebase-verify", "GET /auth/me", "POST /auth/logout", "PUT /memory/stories/{story_id}/approve"):
            skip(label + " (set FIREBASE_ID_TOKEN)")

    call("GET", "/games/next-round/missing", expected=(404,))
    call("POST", "/games/session", {"patient_id": patient_id, "game_code": "missing"}, expected=(404,))
    call("PUT", "/reminders/missing/acknowledge", expected=(404,))
    call("POST", "/reminders/missing/escalate", expected=(404,))
    print(f"\nSummary: {PASSED} passed, {FAILED} failed, {SKIPPED} skipped")
    return 1 if FAILED else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.URLError as error:
        print(f"FAIL Cannot reach {BASE}: {error}", file=sys.stderr)
        raise SystemExit(2)
