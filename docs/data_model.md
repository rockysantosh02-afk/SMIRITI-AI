 # Smriti AI – Firestore Data Model

**Version:** v2.0 (single‑user design)  
**Last updated:** 2026-09-04

> **Important:** This schema has **no** `families`, `caregiver_uids`, or `family_uids` fields.  
> Every document belongs to exactly one user (identified by `user_id`), and **only that user** can read/write it.

---

## Collections

### `users`
One document per signed‑in user.

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | string | Firebase Auth UID (document ID) |
| `display_name` | string | User's chosen name |
| `email` | string | Email address |
| `preferred_language` | string | `en`, `hi`, `as`, `bn` |
| `text_size_multiplier` | number | 1.0 – 1.5 (user adjustable) |
| `created_at` | timestamp | Account creation time |
| `consent` | map | `{photo_consent: bool, voice_consent: bool, score_consent: bool}` each with timestamp |

---

### `game_sessions`
One document per completed game round.

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | string | Document ID (or client_generated_id) |
| `user_id` | string | Owner of this session |
| `game_id` | string | e.g., `matching_image` |
| `domain` | string | `VISUAL_MEMORY`, `ATTENTION`, `SPATIAL`, `RECALL`, `REASONING`, `NUMERACY` |
| `accuracy` | number | 0–1 (correct / total) |
| `response_time_ms` | integer | Total time for the round |
| `difficulty_level` | integer | 1–5 |
| `played_at` | timestamp | When the round finished |
| `synced_at` | timestamp (nullable) | Null = not yet synced |

---

### `cognitive_scores`
One document per domain per user – updated after each session.

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | string | Owner |
| `domain` | string | Same domains as above |
| `composite_score` | number | 0–1 (60% accuracy + 30% speed + 10% trend) |
| `accuracy_ewma` | number | Smoothed accuracy |
| `speed_score` | number | 0–1 |
| `trend` | number | –1 to 1 |
| `current_level` | integer | 1–5 |
| `last_reason` | string | Warm, human‑readable explanation |
| `updated_at` | timestamp | Last update |

---

### `journal_entries`
The user's own photos, voice notes, and memories.

| Field | Type | Description |
|-------|------|-------------|
| `entry_id` | string | Document ID (or client_generated_id) |
| `user_id` | string | Owner |
| `photo_url` | string (nullable) | Firebase Storage URL |
| `voice_note_url` | string (nullable) | Firebase Storage URL |
| `tag_place` | string | User‑provided place label |
| `tag_object` | string | User‑provided object label |
| `tag_occasion` | string | User‑provided occasion label |
| `caption` | string | Short text |
| `ai_story_text` | string (nullable) | AI‑generated reflection |
| `ai_story_passed_content_guard` | boolean | True if safe |
| `created_at` | timestamp | When entry was created |
| `synced_at` | timestamp (nullable) | Null = not yet synced |

---

### `reminders`
Daily medication, appointment, or routine reminders.

| Field | Type | Description |
|-------|------|-------------|
| `reminder_id` | string | Document ID (or client_generated_id) |
| `user_id` | string | Owner |
| `title` | string | e.g., "Take medicine" |
| `type` | string | `medication`, `routine`, `appointment` |
| `scheduled_time` | timestamp | When to fire |
| `recurrence` | string (nullable) | `daily`, `weekly`, or null |
| `status` | string | `pending`, `completed`, `missed`, `dismissed` |
| `follow_up_sent` | boolean | True if gentle follow‑up was shown |
| `created_at` | timestamp | When created |
| `synced_at` | timestamp (nullable) | Null = not yet synced |

---

### `consents`
Audit log of consent actions.

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | string | Owner |
| `consent_type` | string | `photo`, `voice`, `score` |
| `granted` | boolean | True if given |
| `timestamp` | timestamp | When action occurred |

---

## Security Rules (Summary)

- Every read/write must match `request.auth.uid == resource.data.user_id`.
- No collection has `caregiver_uids` or `family_uids` fields.
- All writes to `game_sessions`, `journal_entries`, `reminders` require `user_id` to match the authenticated user.

For the full Firestore rules file, see `backend/firestore.rules` (Part 1).