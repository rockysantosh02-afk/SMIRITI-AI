# Smriti AI — Antigravity Build Guide

## PART 3 of 3: Personal Memory Journal, Voice Assistant, Reminders & Launch

**Team:** Member 5 + Member 6 (2 of your 6 people)
**What you're building:** the Personal Memory Journal, the multilingual voice
assistant, the reminder system, and — at the end — you own testing everything
together and shipping it.
**Depends on:** Part 1's backend (Phases 1.0–1.7, especially the AI generation and
content-guard service) and Part 2's app shell (Phases 2.1–2.4, especially the
folder structure, offline sync engine, and dashboard home screen). Don't start
Phase 3.1 until both of those are pushed to the shared repo.

---

## Before you start

### How to use this document

Same as the other two parts: work phase by phase, paste each **Prompt** into
Antigravity exactly as written, use the **Check** before moving on. Split the work:
Member 5 drives the Personal Memory Journal (Phases 3.1–3.2), Member 6 drives the
Voice Assistant (Phases 3.3–3.4) — these can happen in parallel once you're both past
Phase 3.0. Come back together for Reminders (3.5) and everything from 3.6 onward,
since testing and launch genuinely need both of you.

### Tools to install first (both members)

- **Antigravity**
- **Flutter SDK** (same as Part 2 — if you're on the same machine as a Part 2
  member you may already have this)
- A physical Android phone is strongly recommended for this part specifically,
  because voice recognition and notifications behave differently (and often better)
  on real hardware than in an emulator

### What you need from Parts 1 and 2 before starting

- The shared repo, pulled fresh (`git pull`), with `backend/` (Part 1) and
  `dashboard_app/` (Part 2) both populated
- Part 1's backend running locally or deployed, with the `/journal` generation
  endpoints (you'll build these together with Part 1 in Phase 3.2 if they don't
  exist yet — see that phase)
- Part 2's `lib/features/journal/`, `lib/features/voice/`, and
  `lib/features/reminders/` folders (empty, scaffolded in their Phase 2.1) and their
  working `SyncService` from Phase 2.4

---

## A note on what you're protecting in this part

Two of this project's most important "no caregiver, no family" decisions live
squarely in your part of the build:

1. **The Personal Memory Journal is single-author, single-audience.** The user adds
   their own photos and their own captions. There is no "tag a family member"
   feature, no "send to family for approval" step. Read PRD.md Section 6.4 before
   Phase 3.1 if you haven't already — it explains exactly why.
2. **Reminders get a gentle in-app follow-up, never an alert to someone else.** There
   is no caregiver dashboard to notify. Read PRD.md Section 6.5 before Phase 3.5.

If a prompt result in this document ever produces a "share with family," "notify
caregiver," or "tag a relative" feature, that's a mistake — ask Antigravity to
remove it and explain why (you can literally paste the paragraph above).

---

## Phase 3.0 — Pull the shared repo and confirm the foundation

**Steps (no Antigravity needed yet):**
1. `git pull` the shared repo.
2. Confirm `backend/` has Part 1's routers and services, and that you can run it
   locally (`uvicorn app.main:app --reload --port 8000` from `backend/`, after
   `pip install -r requirements.txt` in a virtual environment).
3. Confirm `dashboard_app/` runs (`flutter run -d chrome`) and you can sign in and
   reach the dashboard home screen built in Part 2's Phase 2.3.
4. Read `docs/data_model.md` again, specifically the `journal_entries` and
   `reminders` collections — you'll use these exact field names throughout this
   document.

---

## Phase 3.1 — Personal Memory Journal: UI and offline storage

**Goal:** Build the screen where the user adds and browses their own photos and
short notes — completely private, completely self-authored.

**Prompt to paste into Antigravity:**

```
In lib/features/journal/, build the Personal Memory Journal, reached from the
dashboard's "My Journal" tile:

1. journal_list_screen.dart — a scrollable grid/list of the user's own
   journal entries (photo thumbnail + caption), newest first, reading from
   the local journal_entries table (built in Part 2's Phase 2.4). A large,
   obvious "+ Add a memory" button.

2. journal_entry_editor_screen.dart — reached by tapping "+ Add a memory" or
   an existing entry to edit it:
   - Pick a photo from the device gallery or take a new one (image_picker
     package).
   - Optionally record a short voice note (record package) instead of or
     alongside a photo.
   - Three simple, optional tag fields: "Where was this?" (tag_place), "What
     was the occasion?" (tag_occasion), "What's in this photo?"
     (tag_object) — plain text fields, not a person/relationship picker.
   - A free-text caption field ("Tell me about this memory" placeholder
     text).
   - Save button: writes to the local journal_entries table via
     SyncService.queueForSync() from Part 2's Phase 2.4 (works fully
     offline; photo/voice files should be saved to local app storage first,
     with only the local file path stored until sync uploads them).
   - Edit and delete are always available on the user's own entries — there
     is no "submitted for approval" state, because there is no second party
     to approve anything.

Do not add any field for another person's name, relationship, or account —
this journal has one author and one reader: the signed-in user.
```

**Check:** From the dashboard, tap My Journal, add a new entry with a photo and a
caption while in airplane mode, confirm it appears in the list immediately, and
confirm (via SQLite inspection, same approach as Part 2's Phase 2.4 Check) that it's
saved locally with no `synced_at` value yet.

---

## Phase 3.2 — Wire the Journal to AI story generation and the content guard

**Goal:** Bring in Part 1's Gemini-powered story writer, and make sure nothing
reaches the user without passing the content guard first — and finish the "Recall My
Memories" game that Part 2 left as a placeholder in their Phase 2.6.

**Prompt to paste into Antigravity:**

```
First, confirm (or if missing, add together with anyone from the Part 1 team)
these backend endpoints in backend/app/routers/journal.py, using the
services Part 1 built in Phase 1.7 (memory_game_generator.py,
content_guard.py):
- POST /journal/entries/{entry_id}/generate-story — loads the entry, calls
  generate_journal_story(), runs the result through passes_content_guard(),
  and if it passes, saves ai_story_text and sets
  ai_story_passed_content_guard=true on the entry; if it fails the guard,
  falls back to a simple static template ("What a lovely memory of
  {tag_place}.") and still marks the entry as having a story, just not an
  AI-generated one. Returns the final story text either way.
- POST /journal/recall-quiz — takes the caller's own journal entries (loaded
  server-side from Firestore, never trust entries passed in the request) and
  calls generate_recall_quiz(), returning simple multiple-choice questions.

Then in the Flutter app:
1. In journal_entry_editor_screen.dart (from Phase 3.1), after an entry
   syncs successfully, add a "Hear a little story about this" button that
   calls the generate-story endpoint and displays/speaks the result (voice
   piece can be a placeholder call for now — Phase 3.4 builds real
   text-to-speech). If offline, disable this button with a clear message
   ("Stories need an internet connection — try again later").
2. Replace Part 2's placeholder in lib/features/games/recall_my_memories_game.dart
   with the real game: if the user has 3+ synced journal entries, call
   /journal/recall-quiz and present it exactly like the other quiz-style
   games from Part 2's Phase 2.6 (same game_session_controller, same
   completion flow, RECALL domain). If fewer than 3 entries, keep Part 2's
   friendly "add some memories first" placeholder message.
```

**Check:** Add 3+ journal entries with meaningful captions (while online), tap "Hear
a little story" on one and confirm a short, warm story appears — read it and
confirm it doesn't mention anything upsetting. Then play "Recall My Memories" from
the games menu and confirm it asks questions based on your own entries.

---

## Phase 3.3 — Multilingual Voice Assistant

**Goal:** Let the whole app be used by ear and by voice — not just read text aloud,
but actually understand spoken input too.

**Prompt to paste into Antigravity:**

```
In lib/features/voice/, build the multilingual voice assistant:

1. voice_service.dart — a single service class wrapping speech_to_text (for
   listening) and flutter_tts (for speaking), with:
   - setLanguage(String localeCode) supporting en-US, hi-IN, as-IN, bn-IN,
     switching both STT and TTS immediately (no app restart).
   - speak(String text) using the app's current language, with rate fixed at
     0.5x (slower, comfortable for elderly listening) and normal pitch.
   - listen() -> Future<String> that returns recognized speech text, with a
     visible "listening..." indicator while active and a graceful timeout.
   - A hasOfflineSupport(String localeCode) check — return true only for
     as-IN and bn-IN per the PRD; for en-US and hi-IN when offline, speak()
     and listen() should show a clear "voice needs internet right now"
     message rather than silently failing.

2. voice_prompts.dart — a map of pre-authored (not machine-translated)
   strings for common app moments (greeting, "let's play a game", "well
   done", reminder announcements, journal prompts) in all 4 languages. Leave
   clear TODO placeholders with rough English meaning next to each
   non-English entry, since the actual Assamese/Bengali/Hindi wording should
   be reviewed by a fluent speaker on the team before final launch — flag
   this explicitly as a task for the team, not something Antigravity should
   invent on its own for a real launch.

3. Wire voice_service into the dashboard's settings screen (Part 2's Phase
   2.3) language picker — changing the setting should call setLanguage()
   immediately.
```

**Check:** In settings, switch the language and confirm the app speaks a test phrase
in the new language when you trigger it. Turn on airplane mode and test Assamese or
Bengali — voice should still work. Test English or Hindi offline — you should see
the clear fallback message, not a crash.

---

## Phase 3.4 — Voice-only navigation through the dashboard and games

**Goal:** A user who struggles with typing or fine motor control should be able to
use the whole app by voice alone, as required by PRD Section 6.3.

**Prompt to paste into Antigravity:**

```
Add a persistent, large microphone button to dashboard_home_screen.dart
(Part 2's Phase 2.3) and to each game screen from Part 2's Phases 2.5-2.6.
Tapping it calls voice_service.listen() and matches the recognized text
against simple intent phrases per screen, for example on the dashboard:
"play a game" / "open my journal" / "my reminders" / "my progress" — on a
quiz-style game: recognized answer text matched against the current
options. Speak a confirmation (voice_service.speak()) before acting, so the
user always hears what the app understood ("Opening your journal") before
anything changes on screen.

Also wire voice_service.speak() to announce every screen's main heading and
instructions automatically when that screen first opens (not just on
button-press), so a user who can't read well is guided the whole way
through, not just when they ask.

Confirm this doesn't break the touch-based flow from Part 2 — voice should
be an alternative path to every action, never the only path.
```

**Check:** With the screen reader/TTS on, navigate from the dashboard into a game
and complete a full round using only your voice, without touching the screen once.
Then confirm you can still do the exact same thing by touch alone.

---

## Phase 3.5 — Reminders with local notifications and gentle follow-up

**Goal:** Build the reminder system — offline-capable, and with a soft, kind
follow-up instead of any alert to a second party.

**Prompt to paste into Antigravity:**

```
In lib/features/reminders/, build:

1. reminder_list_screen.dart — reached from the dashboard's "Reminders"
   tile. Shows today's reminders (medicine/routine/appointment) with a
   simple "Add a reminder" button (title, type, time, optional recurrence).
   Reads/writes the local reminders table from Part 2's Phase 2.4.

2. reminder_scheduler.dart — using flutter_local_notifications and
   workmanager, schedules an actual on-device notification for each
   reminder's time, fully offline (no server round-trip required to fire a
   notification). When a scheduled notification fires and is not marked
   "completed" by the user within a short window (e.g. 30 minutes), schedule
   ONE gentle follow-up notification with a soft, encouraging message (pull
   the wording from voice_prompts.dart, Phase 3.3, so it's multilingual) —
   and mark the reminder status "missed" locally, syncing that status via
   SyncService like any other record.

   Add a clear comment block explaining: this follow-up is entirely
   in-app/on-device, aimed at the user themselves. It never sends a
   notification to any other device or account, because there is no
   caregiver or family role in this product to notify. This is a deliberate
   design choice from PRD.md Section 6.5, not a missing feature.

3. Add reminder completion (tap "Done" on a notification or in the app) and
   have voice_service optionally speak the reminder aloud when it fires, in
   the user's chosen language.
```

**Check:** Create a reminder 2 minutes in the future, put the phone down, confirm
the notification fires on time (works in airplane mode too). Ignore it and confirm
you get exactly one gentle follow-up, not a barrage. Check that no other device,
account, or email receives anything about it.

---

## Phase 3.6 — Full integration and offline regression testing

**Goal:** Now that all three parts' work lives in one repo, this is where you make
sure it actually works together as one coherent app — this is genuinely a two-person
job because of how much ground it covers.

**Prompt to paste into Antigravity:**

```
Walk through this full regression checklist against the complete app (all
features from Parts 1, 2, and 3 merged in the shared repo) and report,
feature by feature, what passes and what needs fixing:

1. Sign in, land on the single dashboard home screen, reach every one of the
   5 tiles (Games, Voice, My Journal, Reminders, My Progress) in one tap.
2. Enable airplane mode. Play at least 2 different games to completion. Add
   a journal entry with a photo. Create a reminder. Confirm none of this
   requires connectivity or shows an error.
3. Still offline, confirm adaptive difficulty still changes between rounds
   (Part 2's Phase 2.7).
4. Disable airplane mode. Wait (or manually trigger) a sync and confirm:
   game sessions, the journal entry, and the reminder all appear in
   Firestore (check the Firebase console) exactly once each — no
   duplicates.
5. Generate an AI story for the journal entry now that you're online; confirm
   it either shows a safe AI story or the safe fallback template — never
   nothing, never an error the user can't recover from.
6. Switch language to Assamese, confirm voice prompts and reminder
   announcements switch immediately and still work offline.
7. Search the entire codebase for the strings "caregiver", "family_uid", and
   "family member" (case-insensitive) — there should be zero results outside
   of comments explaining that these were deliberately removed. Report every
   match found.

For each numbered item, report pass/fail and, for any fail, propose a fix.
```

**Check:** Work through every fail Antigravity reports until the whole checklist
passes. Item 7 in particular should come back completely clean — if it doesn't,
that's a priority fix before moving on, since it's a core product requirement.

---

## Phase 3.7 — Security rules testing

**Goal:** Prove, not just assume, that one user can never read another user's data —
this matters even more in a single-role app, since there's no second role to
"accidentally" rely on for protection.

**Prompt to paste into Antigravity:**

```
Set up the Firebase emulator suite for Firestore rules testing
(firebase-tools already installed from Part 1's Phase 1.2). Write
backend/tests/firestore_rules_test.js (or .ts) using
@firebase/rules-unit-testing, with test cases proving:
1. A signed-in user CAN read and write their own documents in every
   collection from docs/data_model.md (users, game_sessions,
   cognitive_scores, journal_entries, reminders, consents).
2. A signed-in user CANNOT read or write another user's documents in any of
   those collections, even if they guess a valid document ID.
3. An unauthenticated request is denied everywhere.

Run these against backend/firestore.rules from Part 1's Phase 1.2 and report
any failures.
```

**Check:** `firebase emulators:exec --only firestore "npm test"` (or however
Antigravity sets up the test runner) passes every case. If any cross-user access
test fails, that's a critical fix — do not proceed to launch until it passes.

---

## Phase 3.8 — Build release artifacts and launch

**Goal:** Ship it — produce the actual installable app and a deployed backend.

**Prompt to paste into Antigravity:**

```
1. Review backend/DEPLOY.md (written in Part 1's Phase 1.9) and walk me
   through deploying the backend to Google Cloud Run step by step, including
   setting all .env values as Cloud Run environment variables/secrets.

2. For the Flutter app, walk me through:
   - flutter build apk --release (a single installable file for Android,
     easiest for a hackathon demo — you can install this directly on a
     judge's or teammate's phone)
   - flutter build appbundle --release (needed only if you're actually
     publishing to the Play Store)
   - flutter build web --release (a version you can host and demo from a
     browser with no install needed — useful for a live demo laptop)

3. Before final packaging, update the app's base API URL config to point at
   the deployed Cloud Run backend URL from step 1, not localhost.

4. Write a one-page docs/DEMO_SCRIPT.md: a suggested 3-minute walkthrough for
   demoing this app to judges, in order: sign in → dashboard home screen →
   play one game → show adaptive difficulty changed → add a journal entry
   and hear its AI story → show a reminder firing → show My Progress → close
   with airplane-mode-toggle-and-still-works as the final proof point.
```

**Check:** Install the built APK on a phone that has never had the debug version on
it, confirm it opens, signs in, and works end to end against the real deployed
backend (not your laptop's local server). Run through `docs/DEMO_SCRIPT.md`
yourselves as a full team once, timing it, before the actual demo.

---

## Final full-team checklist (all 6 members, together)

Once Part 3 reaches the end of this document, get everyone in one room (or one
call) and go through this together before calling the project done:

- [ ] One dashboard, one login, one role — no caregiver/family screen anywhere
  (Phase 3.6, item 7, should already have confirmed this in code — now confirm it
  visually, screen by screen)
- [ ] Every core feature (games, voice, journal, reminders, progress) works fully
  offline
- [ ] Firestore security rules tested and passing (Phase 3.7)
- [ ] The deployed backend URL is what the release build actually points to (not
  localhost)
- [ ] `docs/README.md` and `docs/PRD.md` in the repo match what you actually built —
  if anything changed along the way, update the docs to match reality before
  submitting
- [ ] `docs/DEMO_SCRIPT.md` has been rehearsed at least once by the full team
