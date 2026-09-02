# Smriti AI Backend Testing

## Setup

From `backend`, run `scripts\setup.bat` on Windows or `./scripts/setup.sh` on
Mac/Linux. Start the API with `scripts\run_dev.bat` or `./scripts/run_dev.sh`.
Open Swagger at `http://127.0.0.1:8000/docs`.

Create a Firebase test user in Authentication, sign in with the mobile/client
SDK, and use its ID token as `Bearer <token>`. Never commit `.env` or the
service-account key.

## Endpoint examples

PowerShell:

```powershell
$base = "http://127.0.0.1:8000"
Invoke-RestMethod "$base/health"
Invoke-RestMethod "$base/games"
Invoke-RestMethod "$base/auth/firebase-login" -Method Post -ContentType application/json -Body '{"id_token":"TOKEN"}'
Invoke-RestMethod "$base/reminders" -Method Post -ContentType application/json -Body '{"patient_id":"PATIENT","label":"Medicine","type":"medication","scheduled_time":"2030-01-01T09:00:00Z"}'
```

Mac/Linux:

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/games
curl -X POST http://127.0.0.1:8000/auth/firebase-login -H 'Content-Type: application/json' -d '{"id_token":"TOKEN"}'
```

Use `postman_collection.json` for a ready-made request collection.

## Scenarios

1. Create a game session, fetch its round, submit an attempt, and inspect patient scores.
2. Create a Memory Vault person/photo, generate a pending story, then approve as a caregiver.
3. Create a reminder, acknowledge it, or escalate it after its scheduled time.
4. Test invalid tokens, missing resources, and forbidden caregiver operations.
5. Queue offline writes with `app.core.outbox_manager`, then flush with `SyncService`.

## Debugging

Check Uvicorn logs, `/health`, and `/test-firestore`. Firebase Console shows
Firestore documents and Authentication users. Missing key/configuration gives
503; invalid tokens give 401; validation gives 422.
