# SMRITI-AI API Manual Test Guide

## Prerequisites

Start the backend from `backend/`:

```powershell
.\venv312\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Use `http://127.0.0.1:8000` as `BASE_URL`. A Firebase service account (or Firebase emulator) is required for Firestore-backed requests. Authentication requests additionally require a real Firebase ID token.

Sample values:

```json
{"patient_id":"<from /test/setup>","game_code":"matching_image"}
```

## Smoke Check

1. `GET /` expects `200` and `{"status":"running"}`.
2. `GET /health` expects `200` and `{"status":"healthy","service":"smriti-ai"}`.
3. `GET /test-firestore` expects `200` and `{"status":"connected","service":"firestore"}`.
4. `GET /test/setup` expects `200` with `patient_id`, `session_id`, and `game_code`. Save these values for the steps below.
5. `POST /test/create-session/family_quiz` expects `200` with a `session_id`.
6. `POST /test/create-session/not-a-game` expects `404`.

## Authentication

1. `POST /auth/firebase-login` with `{"id_token":"<Firebase ID token>"}` expects `200` with `access_token`, `token_type`, `user_id`, `role`, and `firebase_uid`. Save `access_token` as `TOKEN`.
2. `POST /auth/firebase-verify` with `Authorization: Bearer <Firebase ID token>` expects `200` with `status: "valid"` and a `user` object.
3. `GET /auth/me` with `Authorization: Bearer TOKEN` expects `200` with `uid`, `role`, and profile fields.
4. `POST /auth/logout` with the bearer token expects `200` and `status: "success"`. The API is stateless, so discard the token client-side.
5. Missing, invalid, or expired bearer tokens expect `401`.

## Games

1. `GET /games` expects `200`, a JSON array of exactly 9 game objects, each containing `code`, `title`, `domain`, and `description`.
2. `POST /games/session` with `{"patient_id":"<patient_id>","game_code":"matching_image"}` expects `200` with `session_id`, `difficulty: 1`, and `game_code`.
3. `GET /games/next-round/<session_id>` expects `200` with the game round payload. Use the session ID from step 2.
4. Submit an answer with `POST /games/attempt` and `{"session_id":"<session_id>","selected_index":0,"response_time_ms":1000}`. Expect `200` with `correct`, `decision`, and `difficulty`.
5. `GET /games/scores/<patient_id>` expects `200` with a JSON object keyed by cognitive domain.
6. Unknown game codes and session IDs expect `404`; negative `selected_index` or `response_time_ms` expects `422`.

Repeat steps 2-4 with each `code` returned by `GET /games` to exercise all nine games.

## Memory Vault

1. `POST /memory/persons` with `{"patient_id":"<patient_id>","name":"Alex Morgan","relationship":"friend"}` expects `200` with `person_id`.
2. `GET /memory/persons/<patient_id>` expects `200` with an array containing the person.
3. `POST /memory/photos` with `{"patient_id":"<patient_id>","storage_path":"test/alex.jpg","caption":"A sunny day","face_clusters":[]}` expects `200` with `photo_id`.
4. `GET /memory/photos/<patient_id>` expects `200` with an array containing the photo.
5. `POST /memory/events` with `{"patient_id":"<patient_id>","title":"Birthday celebration","description":"Family dinner"}` expects `200` with `event_id`.
6. `GET /memory/events/<patient_id>` expects `200` with an array containing the event.
7. `POST /memory/stories/generate` with the patient ID and the saved person/event IDs expects `200` with `story_id` and `status: "pending"`.
8. As a caregiver, `PUT /memory/stories/<story_id>/approve` with `{"action":"approve"}` expects `200` and `status: "approved"`. Use `{"action":"reject"}` to test rejection.
9. A patient/non-caregiver gets `403`; an invalid action gets `400`; an unknown story gets `404`.

## Reminders

1. `POST /reminders` with `{"patient_id":"<patient_id>","label":"Take medicine","type":"medication","scheduled_time":"2099-01-01T09:00:00Z"}` expects `200` with `reminder_id` and `status: "scheduled"`.
2. `GET /reminders/<patient_id>` expects `200` with an array of active reminders.
3. `GET /reminders/check-due` expects `200` with `checked` and `reminders`.
4. `PUT /reminders/<reminder_id>/acknowledge` expects `200` with `status: "acknowledged"`; the reminder should disappear from the active list.
5. Create another reminder with a past `scheduled_time`, then `GET /reminders/check-due` to verify due processing in a configured Firestore environment.
6. `POST /reminders/<reminder_id>/escalate` expects `200` with `status: "escalated"` when the reminder exists. Unknown IDs expect `404` when Firestore is available.
7. Invalid reminder payloads expect `422`; unknown acknowledgement IDs expect `404`.

## Automated Checks

From `backend/`:

```powershell
.\venv312\Scripts\python.exe -m pytest tests/test_api_automated.py -v
.\venv312\Scripts\python.exe -m pytest -q
python scripts/test_api_flow.py
python scripts/test_all_apis.py
```

Set `API_BASE_URL` for another server. Set `FIREBASE_ID_TOKEN` for the authentication portions of `test_all_apis.py`; set `CAREGIVER_TOKEN` when that token has caregiver role.

## Troubleshooting

- `503` from Firestore routes: verify Firebase credentials, `FIREBASE_PROJECT_ID`, `.env`, and the service-account path. From `backend/`, run `GET /test-firestore` first.
- `401` from `/auth/me`: use the internal `access_token` returned by login, not the raw Firebase ID token.
- `403` approving a story: the authenticated Firestore user must have `role: "caregiver"`.
- `404` for game/session/story/reminder: check the saved ID and ensure the record was created against the same Firestore project.
- `422`: compare the JSON field names and types with `/docs`; timestamps must be ISO-8601.
- Escalation does not use the request dependency override; it reads the configured Firebase client directly. Use a Firebase emulator or configured project for that manual check.
- `Connection refused`: start Uvicorn from `backend/` and confirm port `8000` is free.
