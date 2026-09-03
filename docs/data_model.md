# Firestore Data Model

## Ownership and roles

Simriti is a single-user application. Every Firestore document contains a required `user_id` field whose value is the Firebase Authentication UID of the document owner. A user can read and write only their own documents.

There is no second-party role in this model: no caregiver, family member, delegated viewer, shared account, or other user can access another user's data.

## Collections

### `users/{user_id}`

Stores the authenticated user's profile and preferences.

Required fields:

- `user_id`: string, the Firebase Authentication UID; normally the document ID as well.

Additional profile and preference fields may be added without changing ownership semantics.

### `patients/{patient_id}`

Stores the user's personal profile record and application state associated with that user.

Required fields:

- `patient_id`: string, the document identifier.
- `user_id`: string, the owning Firebase Authentication UID.

A patient record is private to its owner. It is not a shared or delegated record.

### `journal_entries/{entry_id}`

Stores one user-owned journal entry.

Required fields:

- `entry_id`: string, the document identifier.
- `user_id`: string, the owning Firebase Authentication UID.
- `photo_url` or `voice_note_url`: string, the source media URL; at least one source is expected.
- `tag_place`: string or null, an optional place tag.
- `tag_object`: string or null, an optional object tag.
- `tag_occasion`: string or null, an optional occasion tag.
- `caption`: string or null, the user's caption.
- `ai_story_text`: string or null, generated story text.
- `ai_story_passed_content_guard`: boolean, whether generated content passed the content guard.
- `created_at`: timestamp, when the entry was created.

`photo_url` and `voice_note_url` are alternative media fields. The remaining tag and text fields can be empty when not applicable.

### `reminders/{reminder_id}`

Stores reminders configured by the user.

Required fields:

- `reminder_id`: string, the document identifier.
- `user_id`: string, the owning Firebase Authentication UID.

Scheduling, status, title, and notification fields are application-specific and remain private to the owner.

### `user_scores/{score_id}`

Stores cognitive scores for the authenticated user.

Required fields:

- `user_id`: string, the owning Firebase Authentication UID.
- `domain`: string, the cognitive domain being scored.

### `game_sessions/{session_id}` and `game_attempts/{attempt_id}`

Store the user's game sessions and submitted attempts.

Required fields:

- `user_id`: string, the owning Firebase Authentication UID.

Session and attempt references must not be used to join data across users.

### `journal_stories/{story_id}`

Stores stories generated from the user's own journal entries.

Required fields:

- `story_id`: string, the document identifier.
- `user_id`: string, the owning Firebase Authentication UID.
- `entry_ids`: list of journal entry identifiers owned by the same user.
- `content`: string, the generated story.
- `status`: string, the user's story review status.

## Security boundary

Firestore rules require authentication and verify the document's `user_id` against the authenticated UID for every read and write. Unknown collections are denied by the catch-all rule.
