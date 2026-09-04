# Smriti AI — Antigravity Build Guide

## PART 1 of 3: Foundation, Firebase & Backend API

**Team:** Member 1 + Member 2 (2 of your 6 people)
**What you're building:** the project's shared foundation — the Firebase project, the
data rules, and the FastAPI backend that the app in Parts 2 and 3 will talk to.
**You are the "Phase 0" team.** Parts 2 and 3 cannot really start until you finish
Phases 1.0–1.2, so do those first and share the output files with the other two
duos immediately (see the Handoff Package at the end of this document).

---

## Before you start

### What is Antigravity, in one sentence?

Antigravity is an AI coding assistant you talk to in plain English inside an
editor. You paste in a "prompt" (an instruction), it writes the actual code files
for you, and you check the result. This document gives you the exact prompts to
paste, in order, phase by phase. **You do not need to know how to code to use this
document** — you need to paste each prompt, read what Antigravity did, run the
"how to check it worked" step, and only then move to the next prompt.

### How to use this document

1. Work through the phases **in order**. Do not skip ahead — later prompts assume
   earlier ones are done.
2. Each phase has: a **Goal** (what you're building and why, in plain English), a
   **Prompt** (copy this exactly into Antigravity), and a **Check** (how to know it
   worked before moving on).
3. If Antigravity's result doesn't match the Check, don't move on — paste the Check
   failure back to Antigravity and say "this didn't work, here's what happened:
   [paste the error]." That's a normal, expected part of the process.
4. Two people, one keyboard at a time is fine for this part — the work here is
   mostly sequential (one thing has to exist before the next thing can be built on
   top of it). Member 1 can drive Phases 1.0–1.4, Member 2 can drive Phases 1.5–1.9,
   but talk through each Check together before moving on.

### Tools to install first (both members)

- **Antigravity** (or your team's AI coding assistant/IDE)
- **Python 3.10 or newer** — check with `python3 --version` in a terminal
- **Git** and a **GitHub account** — this is how your three duos will share code
- A **Google account** to create the Firebase project
- A **Gemini API key** — get one free at https://aistudio.google.com/app/apikey (you'll
  need this in Phase 1.7)

---

## Phase 1.0 — Create the shared project skeleton

**Goal:** Set up one shared GitHub repository with the folder structure the whole
team (all 6 members, all 3 parts) will build into. This is the single most
important phase to get right early, because Parts 2 and 3 will create their files
inside the folders you make here.

**Prompt to paste into Antigravity:**

```
Create a new project called "smriti-ai" with this exact folder structure. Create
empty placeholder files (like a .gitkeep or a one-line README) inside empty folders
so the structure is visible in git:

smriti-ai/
├── backend/
│   ├── app/
│   │   ├── core/
│   │   ├── models/
│   │   ├── routers/
│   │   └── services/
│   ├── tests/
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
├── dashboard_app/
│   └── (leave empty — the Flutter team will initialize this in Part 2)
├── docs/
│   ├── README.md
│   ├── PRD.md
│   └── data_model.md
└── .gitignore

The .gitignore must ignore: .env, service-account-key.json, *.log,
dashboard_app/build/, __pycache__/, .venv/, node_modules/, .dart_tool/, and any
file with "google-services.json" or "firebase_options.dart" in the name (these
contain secrets and must never be committed).

Also create a plain-English CONTRIBUTING.md explaining that this project has 3
teams working in 3 folders (backend/, dashboard_app/, and shared docs/) and that
nobody should edit another team's folder without asking first.
```

**Check:** You should see the folder tree above created on disk. Run `git init`,
`git add .`, `git commit -m "project skeleton"`, then push to a new GitHub repo and
invite all 6 team members as collaborators. Every member should now `git clone` this
repo to their own machine — this is the shared codebase for the whole hackathon.

---

## Phase 1.1 — Create and configure the Firebase project

**Goal:** Firebase is the cloud database and login system for the whole app. You are
creating it once, here, and every other part of the project (backend, and later the
app in Parts 2/3) will plug into this same project.

**This step is done in the Firebase Console (a website), not in Antigravity** —
Antigravity can't create a Firebase project for you, but it can generate the
follow-up code. Do this part manually first:

1. Go to https://console.firebase.google.com/ and click **Add project**. Name it
   `smriti-ai` (or `smriti-ai-dev` if that name is taken).
2. In the left sidebar, enable these four things one by one:
   - **Authentication** → click "Get started" → enable **Email/Password** and
     **Google** sign-in methods.
   - **Firestore Database** → click "Create database" → choose **production
     mode** → pick region **asia-south1 (Mumbai)**.
   - **Storage** → click "Get started" → same region, production mode.
   - **Cloud Messaging** → no setup needed yet, it's on by default.
3. Go to **Project settings (gear icon) → Service accounts → Generate new private
   key**. This downloads a file — rename it `service-account-key.json` and put it
   in `smriti-ai/backend/`. **Do not commit this file to git** (your `.gitignore`
   from Phase 1.0 already blocks it, but double-check).
4. Still in Project settings, under "Your apps," click **Add app → Web app** (even
   though the real app is Flutter, adding a web app here is the easiest way to get
   the config values Part 2 will need later). Name it `smriti-ai-web`. Copy the
   config object it shows you (it looks like `{ apiKey: "...", authDomain: "...",
   ... }`) — paste it into a new file `docs/firebase_web_config.txt` for now. Part 2
   will use this in Phase 2.2.

**Prompt to paste into Antigravity (after the manual steps above):**

```
I've created a Firebase project and downloaded a service-account-key.json into
backend/. Write backend/.env.example with these variable names and a one-line
comment explaining each (no real values, just placeholders):

FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=
FIREBASE_STORAGE_BUCKET=
GEMINI_API_KEY=
REDIS_URL=

Then write backend/app/core/config.py using pydantic-settings (or python-dotenv if
that's simpler) that loads these from a real .env file at runtime, with clear error
messages if any required variable is missing.
```

**Check:** `backend/.env.example` exists with all 6 variables and comments.
`backend/app/core/config.py` exists. Copy `.env.example` to a real `.env` file, fill
in the values from your downloaded `service-account-key.json` (open that JSON file
— `project_id`, `private_key`, and `client_email` are in it) and your Gemini API key.
Do NOT commit `.env`.

---

## Phase 1.2 — Define the Firestore data model & security rules

**Goal:** This is the most important design decision in the whole backend: every
single piece of data in this app belongs to exactly one user, and no other account
can ever read it. There is no "family" or "caregiver" concept anywhere — read this
phase carefully even if you copy the prompt exactly, because it's the thing that
makes the "no family connections, one dashboard" requirement real at the database
level.

**Prompt to paste into Antigravity:**

```
Design a Firestore data model for a single-user (no multi-user sharing, no
caregiver, no family member roles) offline-first wellness app called Smriti AI.
Write it as docs/data_model.md with a collection-by-collection breakdown.

Collections needed:
- users: one document per signed-in user. Fields: user_id, display_name,
  preferred_language (one of en, hi, as, bn), text_size_preference,
  created_at, consent (nested object with photo_consent: bool,
  voice_consent: bool, score_consent: bool, each with a timestamp).
- game_sessions: one document per completed game round. Fields: session_id,
  user_id, game_id, domain (one of VISUAL_MEMORY, ATTENTION, SPATIAL, RECALL,
  REASONING, NUMERACY), accuracy, response_time_ms, difficulty_level,
  played_at, synced_at.
- cognitive_scores: one document per domain per user, updated after each
  session. Fields: user_id, domain, composite_score, accuracy_ewma,
  speed_score, trend, current_level, last_reason (human-readable explanation
  string), updated_at.
- journal_entries: one document per journal entry (the user's own photos/voice
  notes, self-tagged). Fields: entry_id, user_id, photo_url or voice_note_url,
  tag_place, tag_object, tag_occasion, caption, ai_story_text (nullable),
  ai_story_passed_content_guard (bool), created_at.
- reminders: one document per reminder. Fields: reminder_id, user_id, title,
  type (medication/routine/appointment), scheduled_time, recurrence,
  status (pending/completed/missed/dismissed), follow_up_sent (bool),
  created_at.
- consents: an audit log, one document per consent action. Fields: user_id,
  consent_type, granted (bool), timestamp.

Explicitly state in the doc: there is no "families" collection, no
"caregiver_uids" field, and no "family_uids" field anywhere in this schema,
because no account other than the data's own owner is ever allowed to read it.

Then write backend/firestore.rules with security rules enforcing: a signed-in
user can only read/write documents where the document's user_id field matches
their own Firebase Auth uid. Deny all access by default. Include comments
explaining each rule block in plain English for someone learning Firestore
rules for the first time.
```

**Check:** `docs/data_model.md` exists and lists exactly the 6 collections above,
with an explicit note that there's no family/caregiver field. `backend/firestore.rules`
exists. Deploy it with `firebase deploy --only firestore:rules` (you'll need the
Firebase CLI: `npm install -g firebase-tools`, then `firebase login`, then
`firebase init` inside `backend/` pointing at your project, then deploy). Share both
files with Parts 2 and 3 right away — they need `data_model.md` to know what field
names to use in the app.

---

## 🟢 HANDOFF POINT — share these with Parts 2 and 3 now

Before continuing, push to GitHub and message the other two duos that these exist:
- `docs/firebase_web_config.txt`
- `docs/data_model.md`
- `backend/firestore.rules` (deployed)
- The Firebase project itself (add Part 2/3 members as Firebase project members:
  Firebase Console → Project settings → Users and permissions)

Parts 2 and 3 can now start their own Phase "0" (pulling this repo and confirming
these files exist) while you continue with the backend below.

---

## Phase 1.3 — Scaffold the FastAPI backend

**Goal:** Build the skeleton of the actual backend server — the program that will
run all the time, talking to Firebase and to the app.

**Prompt to paste into Antigravity:**

```
In backend/, scaffold a FastAPI application. Create:
- backend/app/main.py — the FastAPI app instance, with CORS enabled for local
  development, and a GET /health endpoint that returns {"status": "ok"}.
- backend/app/core/firebase_admin.py — initializes the Firebase Admin SDK using
  the service-account-key.json path from config.py, and exposes a function
  get_firestore_client() other files can import.
- backend/requirements.txt — include: fastapi, uvicorn[standard],
  firebase-admin, pydantic-settings, python-dotenv, celery, redis,
  langchain, google-generativeai, pytest, httpx.
- backend/Dockerfile — a standard Python 3.11-slim Dockerfile that installs
  requirements.txt and runs uvicorn on port 8080.

Explain in comments what each file does, written for someone who has never used
FastAPI before.
```

**Check:** Run `pip install -r backend/requirements.txt` (inside a virtual
environment: `python -m venv .venv && source .venv/bin/activate` first), then
`uvicorn app.main:app --reload --port 8000` from inside `backend/`. Open
`http://localhost:8000/health` in a browser — you should see `{"status":"ok"}`.

---

## Phase 1.4 — Authentication router

**Goal:** Every request to the backend needs to prove "I am this specific signed-in
user" — this phase builds that check.

**Prompt to paste into Antigravity:**

```
In backend/app/routers/auth.py, create a FastAPI router with:
1. A reusable dependency function get_current_user(request) that reads a
   "Authorization: Bearer <token>" header, verifies it as a Firebase ID token
   using the Firebase Admin SDK, and returns the decoded user's uid. If the
   token is missing or invalid, raise a 401 Unauthorized error with a clear
   message.
2. A GET /auth/me endpoint (protected by the dependency above) that returns
   the caller's own uid and their user profile document from the "users"
   Firestore collection (create the user document with default values on
   first login if it doesn't exist yet — no separate "sign up" step needed).

Wire this router into app/main.py. Add a docs/auth_flow.md explaining, in plain
English with no jargon, how a login actually works end to end: the app signs the
user in with Firebase Auth directly (not through this backend), gets a token back,
and sends that token to this backend on every request afterward.
```

**Check:** With `uvicorn` running, calling `GET /auth/me` with no header should
return 401. (You can't fully test the "valid token" path until Part 2 has a working
login screen — note that as a known gap for now and revisit together once Part 2
reaches Phase 2.2.)

---

## Phase 1.5 — Adaptive Difficulty Engine (backend)

**Goal:** Build the "brain" that decides whether each game gets a little easier or a
little harder for this specific user, and — just as important — produces a
plain-English reason for that decision, since this app has no second person to
interpret a raw number for the user.

**Prompt to paste into Antigravity:**

```
In backend/app/services/adaptive_difficulty.py, implement a rule-based (not
machine-learning) adaptive difficulty engine as a pure Python module (no
Firestore calls inside this file — it should take data in and return a
decision out, so it's easy to test and to reuse on-device later).

Function signature:
def compute_difficulty_decision(recent_attempts: list[dict], current_level: int) -> dict

Each item in recent_attempts has: accuracy (0-1 float), response_time_ms (int),
played_at (ISO timestamp string).

Logic:
1. Require at least 3 attempts; if fewer, return the current level unchanged
   with reason "Not enough recent attempts yet to adjust difficulty."
2. accuracy_ewma: exponentially weighted moving average of accuracy, more
   weight on recent attempts (alpha=0.3).
3. speed_score: normalize response_time_ms into a 0-1 score (faster = higher,
   using a rolling median as baseline — pick a sane bounded formula and
   document it with a comment).
4. trend: +1 if the last 2 attempts' accuracy is higher than the 2 before that,
   -1 if lower, 0 if flat.
5. composite_score = 0.6*accuracy_ewma + 0.3*speed_score + 0.1*(trend
   normalized to 0-1).
6. If composite_score >= 0.78 and current_level < 5: promote one level.
   If composite_score <= 0.45 and current_level > 1: demote one level.
   Otherwise: keep the level.
7. Return a dict: {new_level, composite_score, reason} where reason is a
   short, warm, plain-English sentence written for the USER themselves to
   read (not a clinician) — e.g. "You've been getting quicker and more
   accurate, so this is stepping up a little" or "Let's ease this back a
   touch so it stays enjoyable." Never use clinical language like
   "cognitive decline" or "impairment" in this string.

Write backend/tests/test_adaptive_difficulty.py with at least 5 pytest test
cases covering: too few attempts, a clear promotion case, a clear demotion
case, a "stay the same" case, and level capped at 5/floored at 1.
```

**Check:** Run `cd backend && pytest` — all tests should pass. Read through the
`reason` strings out loud — if any sound clinical or cold, ask Antigravity to
rewrite them warmer.

---

## Phase 1.6 — Games & Sync API endpoints

**Goal:** Build the endpoints the app will call to submit finished game rounds and
to reconcile everything it saved while offline.

**Prompt to paste into Antigravity:**

```
Using the auth dependency from Phase 1.4 and the engine from Phase 1.5, build
backend/app/routers/games.py and backend/app/routers/sync.py.

games.py:
- POST /games/sessions — accepts a game session result (game_id, domain,
  accuracy, response_time_ms, played_at, client_generated_session_id).
  Writes it to the game_sessions Firestore collection scoped to the caller's
  own uid (never trust a user_id in the request body — always use the id from
  the verified token). Then re-reads the user's recent attempts for that
  domain, calls compute_difficulty_decision, updates the cognitive_scores
  document, and returns the new level + reason in the response.
- GET /games/sessions — returns the caller's own recent sessions (paginated,
  most recent first).

sync.py:
- POST /sync/batch — accepts a list of locally-queued records of mixed types
  (game_sessions, reminders, journal_entries) with a client_generated_id on
  each. For each record: if a document with that client_generated_id already
  exists for this user, skip it (idempotent — this is how we avoid duplicate
  writes when the same batch gets retried after a dropped connection).
  Otherwise write it. Return a list of {client_generated_id, status:
  "created"|"already_synced"|"error"} so the app knows what to remove from
  its local outbox.

Add docstrings on every endpoint explaining, for a beginner, why idempotency
(the client_generated_id skip-if-exists check) matters for an offline-first app.
```

**Check:** With the server running, use the FastAPI auto-generated docs at
`http://localhost:8000/docs` to manually try `POST /games/sessions` and
`POST /sync/batch` (you'll need a real Firebase ID token — Part 2 can generate one
for you once their login screen works, or ask Antigravity for a small test script
that mints one using the Firebase Admin SDK's `create_custom_token` for a test uid).

---

## Phase 1.7 — AI generation service (Gemini + content guard)

**Goal:** This powers the "AI-narrated story" feature in the Personal Memory
Journal. Because there's no second person to review AI output before the user sees
it, the safety check in this phase is not optional — it's the only thing standing
between a bad AI output and a vulnerable user.

**Prompt to paste into Antigravity:**

```
In backend/app/services/memory_game_generator.py, build two functions using
LangChain + google-generativeai (Gemini):

1. generate_journal_story(caption: str, tag_place: str, tag_occasion: str,
   language: str) -> str
   Prompts Gemini to write a short (3-5 sentence), warm, first-person-friendly
   reflection based on the journal entry's own caption/tags, in the given
   language. The prompt to Gemini must explicitly instruct it to: never
   invent facts not present in the caption/tags, never mention illness,
   decline, death, or anything distressing, keep it simple and positive, and
   stay under 60 words.

2. generate_recall_quiz(journal_entries: list[dict]) -> list[dict]
   Given 3+ of the user's own journal entries, generates simple multiple-
   choice recall questions ("What did you call this place?" style, using the
   user's OWN captions/tags as the answer options) for the "Recall My
   Memories" game.

Then in backend/app/services/content_guard.py, build:

def passes_content_guard(text: str) -> tuple[bool, str]
   A conservative safety check that rejects text containing: distressing
   words (a blocklist you define — illness, death, decline, forget,
   confusion, lost, alone, and similar), anything that looks like a question
   demanding personal information, or text over 80 words. Returns
   (True, "") if it passes, or (False, reason) if it doesn't. This function
   should be the ONLY gate before any AI text reaches the user — default to
   rejecting anything you're not confident about, and if it's rejected,
   the caller should fall back to a simple static template like "What a
   lovely memory of {tag_place}."

Write backend/tests/test_content_guard.py with test cases for both a passing
and a failing example.
```

**Check:** `pytest backend/tests/test_content_guard.py` passes. Manually run
`generate_journal_story` with a sample caption and read the output out loud — does
it sound warm and safe? If Gemini ever produces something the guard doesn't catch,
add that phrase to the blocklist and re-test.

---

## Phase 1.8 — Reminder scheduling service

**Goal:** Build the backend half of reminders — mirroring what fires locally on the
device, without any escalation to a second person (there isn't one in this product).

**Prompt to paste into Antigravity:**

```
In backend/app/services/reminder_logic.py, build a function
process_missed_reminder(reminder: dict) -> dict that, given a reminder
document that is now overdue and still status="pending", returns an update:
{status: "missed", follow_up_message: <a short, kind, non-judgmental
in-app message string in the reminder's owner's preferred language>}.

Explicitly do NOT build any notification, push, or alert to any account
other than the reminder's own owner — there is no second-party escalation
in this product. Add a comment in the file explaining why, referencing that
this app has exactly one user role.

Then set up backend/app/core/celery_app.py with a Celery app configured to
use REDIS_URL from config.py, and a scheduled task
check_overdue_reminders() that runs every 5 minutes, queries Firestore for
reminders past their scheduled_time still marked pending, and calls
process_missed_reminder on each, writing the update back to Firestore.
```

**Check:** With Redis running locally (`docker run -p 6379:6379 redis` is the
fastest way if you have Docker, otherwise `redis-server`), run
`celery -A app.core.celery_app worker --beat --loglevel=info` from `backend/` and
confirm it starts without errors and logs the scheduled task registering.

---

## Phase 1.9 — Backend tests, Docker, and deployment prep

**Goal:** Make sure the whole backend is tested and ready to deploy, so Part 3's
final launch phase (3.8) has something working to point at.

**Prompt to paste into Antigravity:**

```
Review everything in backend/app/ and:
1. Add any missing pytest tests so every router and service has at least one
   test, using pytest fixtures to mock Firebase Admin SDK calls (don't hit
   real Firestore in tests).
2. Confirm backend/Dockerfile builds successfully: docker build -t
   smriti-ai-backend backend/
3. Write backend/DEPLOY.md with step-by-step instructions (for someone who
   has never used Google Cloud Run before) to deploy this container to Cloud
   Run, including how to set the environment variables from .env as Cloud
   Run secrets rather than plain text.
```

**Check:** `pytest backend/` passes with no failures. `docker build` succeeds
locally. `backend/DEPLOY.md` reads clearly enough that Part 3 can follow it in
Phase 3.8 without you in the room.

---

## What Part 1 hands off to Parts 2 and 3

By the end of this document, make sure these exist and are pushed to the shared
repo, and message the other two duos:

- `docs/data_model.md` and `docs/firebase_web_config.txt` (needed for Part 2's
  Phase 2.2)
- `backend/firestore.rules`, deployed
- A running backend (locally, and ideally already deployed per Phase 1.9) with a
  base URL Parts 2 and 3 can point their app at
- The Firebase project itself, with Part 2/3 members added as project members

Once this is shared, hop into the other two documents and support them if they hit
backend-related questions — you now know this API better than anyone else on the
team.
