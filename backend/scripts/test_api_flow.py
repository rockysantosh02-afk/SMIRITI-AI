"""Run the primary patient, game, memory, and reminder API flow.

Usage from backend/: python scripts/test_api_flow.py
Set API_BASE_URL to target another server.
"""

import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone

BASE_URL = os.getenv("API_BASE_URL", "http://127.0.0.1:8000").rstrip("/")


def request(method, path, body=None, expected=(200,), headers=None):
    data = json.dumps(body).encode() if body is not None else None
    request_headers = {"Content-Type": "application/json", **(headers or {})}
    request = urllib.request.Request(BASE_URL + path, data=data, headers=request_headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            payload = json.loads(response.read().decode()) if response.length != 0 else {}
            status = response.status
    except urllib.error.HTTPError as error:
        payload = json.loads(error.read().decode())
        status = error.code
    if status not in expected:
        raise AssertionError(f"{method} {path}: expected {expected}, got {status}: {payload}")
    print(f"PASS {method:6} {path} ({status})")
    return payload


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def main():
    setup = request("GET", "/test/setup")
    patient_id, session_id = setup["patient_id"], setup["session_id"]

    games = request("GET", "/games")
    assert len(games) == 9, f"Expected 9 games, got {len(games)}"
    game_code = games[0]["code"]
    session = request("POST", "/games/session", {"patient_id": patient_id, "game_code": game_code})
    session_id = session["session_id"]
    round_data = request("GET", f"/games/next-round/{session_id}")
    attempt = request("POST", "/games/attempt", {"session_id": session_id, "selected_index": 0, "response_time_ms": 1000})
    assert {"correct", "decision", "difficulty"} <= set(attempt)
    scores = request("GET", f"/games/scores/{patient_id}")
    assert scores

    person = request("POST", "/memory/persons", {"patient_id": patient_id, "name": "Alex", "relationship": "friend"})
    request("GET", f"/memory/persons/{patient_id}")
    photo = request("POST", "/memory/photos", {"patient_id": patient_id, "storage_path": "test/alex.jpg", "caption": "A sunny day"})
    request("GET", f"/memory/photos/{patient_id}")
    event = request("POST", "/memory/events", {"patient_id": patient_id, "title": "Birthday", "description": "Family celebration"})
    request("GET", f"/memory/events/{patient_id}")
    story = request("POST", "/memory/stories/generate", {"patient_id": patient_id, "person_ids": [person["person_id"]], "event_ids": [event["event_id"]]})

    reminder = request("POST", "/reminders", {"patient_id": patient_id, "label": "Take medicine", "type": "medication", "scheduled_time": "2099-01-01T09:00:00Z"})
    reminder_id = reminder["reminder_id"]
    request("GET", f"/reminders/{patient_id}")
    request("GET", "/reminders/check-due")
    request("PUT", f"/reminders/{reminder_id}/acknowledge")

    second_reminder = request("POST", "/reminders", {"patient_id": patient_id, "label": "Escalation test", "type": "safety", "scheduled_time": "2099-01-01T09:00:00Z"})
    request("POST", f"/reminders/{second_reminder['reminder_id']}/escalate")

    firebase_token = os.getenv("FIREBASE_ID_TOKEN")
    if firebase_token:
        login = request("POST", "/auth/firebase-login", {"id_token": firebase_token})
        token = login["access_token"]
        request("POST", "/auth/firebase-verify", headers={"Authorization": f"Bearer {firebase_token}"})
        request("GET", "/auth/me", headers=bearer(token))
        request("POST", "/auth/logout", headers=bearer(token))
        caregiver_token = os.getenv("CAREGIVER_TOKEN", token)
        request("PUT", f"/memory/stories/{story['story_id']}/approve", {"action": "approve"}, headers=bearer(caregiver_token))
    else:
        print("SKIP auth and story approval: set FIREBASE_ID_TOKEN (and CAREGIVER_TOKEN if needed)")
    print(f"\nFlow complete for patient {patient_id}; story {story['story_id']}, photo {photo['photo_id']}, round {round_data.get('round_id', 'created')}")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, urllib.error.URLError, KeyError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        raise SystemExit(1)
