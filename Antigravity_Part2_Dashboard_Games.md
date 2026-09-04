# Smriti AI — Antigravity Build Guide

## PART 2 of 3: The Dashboard App — UI, Offline Engine & Cognitive Games

**Team:** Member 3 + Member 4 (2 of your 6 people)
**What you're building:** the single app the user actually sees and touches — the
one dashboard, its offline storage, and all 9 cognitive games.
**Depends on:** Part 1's Phases 1.0–1.2 (the shared repo, Firebase project, and data
model). Do not start Phase 2.1 until Part 1 confirms those are done and shared.

---

## Before you start

### How to use this document

Same approach as the other two parts: work phase by phase, in order, copy each
**Prompt** into Antigravity exactly, then use the **Check** to confirm it worked
before moving to the next one. If a Check fails, describe the failure to Antigravity
and ask it to fix it — don't move on with something broken.

Split the work between Member 3 and Member 4 like this: Member 3 drives the app
shell and offline engine (Phases 2.1–2.4), Member 4 starts building games in
parallel once Phase 2.4 is stable (Phases 2.5–2.6 can go faster with two people
each building different games from the same template). Come back together for
Phases 2.7–2.9.

### Tools to install first (both members)

- **Antigravity**
- **Flutter SDK** — install from https://docs.flutter.dev/get-started/install, then
  run `flutter doctor` in a terminal and fix anything it flags red
- **Android Studio** (for an Android emulator) or a physical Android phone with USB
  debugging enabled
- **Git** — you'll `git clone` the same shared repo Part 1 created

### What you need from Part 1 before starting

Confirm these exist in the shared repo before Phase 2.1:
- `docs/data_model.md` — this tells you the exact field names to use, so your app
  and the backend agree with each other
- `docs/firebase_web_config.txt` — the Firebase config values
- Part 1's Firebase project, with you added as a project member (ask them to add you
  in Firebase Console → Project settings → Users and permissions)

---

## A note on what "the dashboard" means here

This app has **one home screen** that every feature hangs off of — there is no
separate app for a second type of user, and nothing in this app is gated behind
anyone else's account or approval. Keep that in mind in every phase below: if a
prompt result ever produces a "caregiver," "family," or "share with" screen or
field, that's wrong for this project — ask Antigravity to remove it.

---

## Phase 2.0 — Pull the shared repo and confirm the foundation

**Goal:** Make sure your local setup matches the team's shared project before you
build anything.

**Steps (no Antigravity needed yet):**
1. `git clone` the shared repo from Phase 1.0 (or `git pull` if you already have it).
2. Open `docs/data_model.md` and `docs/firebase_web_config.txt` — read through both
   so the field names below make sense as you go.
3. Confirm the empty `dashboard_app/` folder exists (Part 1 created it as a
   placeholder) — you're about to fill it in.

---

## Phase 2.1 — Scaffold the Flutter dashboard app

**Goal:** Create the actual Flutter project, with the accessibility choices baked in
from day one (large text, high contrast, big touch targets) — retrofitting
accessibility later is much harder than starting with it.

**Prompt to paste into Antigravity:**

```
Inside the existing dashboard_app/ folder, initialize a new Flutter project
targeting Android, iOS, and Web (flutter create with all three platforms).
Use this folder structure inside lib/:

lib/
├── main.dart
├── core/
│   ├── theme/
│   │   └── app_theme.dart
│   ├── firebase/
│   ├── database/
│   └── sync/
└── features/
    ├── dashboard_home/
    ├── auth/
    ├── games/
    ├── journal/
    ├── reminders/
    ├── progress/
    └── voice/

In lib/core/theme/app_theme.dart, define a Material 3 theme built for elderly
users: minimum body text size 20sp (with a user-adjustable multiplier up to
1.5x), minimum touch target 56x56 logical pixels, high-contrast color scheme
(WCAG AA minimum, test with a contrast checker), a calm and warm color
palette (not clinical white/blue), and reduced-motion-friendly transitions
(short, simple fades rather than complex animations) with a setting to
disable animation entirely.

Wire this theme into main.dart as the app's ThemeData. Add a comment block at
the top of app_theme.dart summarizing these accessibility decisions in plain
English so anyone on the team understands why the numbers are what they are.
```

**Check:** Run `flutter run -d chrome` (fastest way to see it) — you should see a
blank app launch with no errors. `flutter doctor` should show no blocking issues.

---

## Phase 2.2 — Connect Firebase and build the login screen

**Goal:** Let a user sign in — this is the ONLY account-related screen in the whole
app, because there's only one role.

**Prompt to paste into Antigravity:**

```
Add Firebase to this Flutter project using the FlutterFire CLI approach
(firebase_core, firebase_auth packages). Use the config values from
docs/firebase_web_config.txt for the web target; for Android, I will add
google-services.json myself after this step (leave a clear comment showing
exactly where that file needs to go).

Build lib/features/auth/ with:
- A single, simple sign-in screen offering three options: Email/Password,
  Google Sign-In, and "Use a simple code" (device pairing — generates a
  6-digit code the user can also enter on a second device to link the same
  account, for a user who struggles with passwords).
- Large, clearly labeled buttons, minimal text, and a short (one sentence)
  friendly explanation at the top: something like "Sign in to keep your
  games, journal, and reminders safe and with you."
- After successful sign-in, navigate to a placeholder dashboard_home screen
  (built in Phase 2.3) and store the Firebase ID token for use in backend API
  calls (Part 1's backend expects it as an Authorization: Bearer header — see
  docs/auth_flow.md from Part 1).

Do not include any field, button, or screen related to inviting another
person, adding a family member, or connecting a caregiver account. This app
has exactly one account per person, full stop.
```

**Check:** Download `google-services.json` from Firebase Console → Project
settings → your Android app (create one there if it doesn't exist yet, package name
e.g. `com.smritiai.dashboard_app`) and place it in `android/app/`. Run
`flutter run` on an emulator or `flutter run -d chrome`, try signing up with a test
email — you should land on a blank placeholder dashboard screen.

---

## Phase 2.3 — Build the single Dashboard Home Screen

**Goal:** This is the screen described throughout the PRD — one screen, reachable
right after login, with every feature one tap away.

**Prompt to paste into Antigravity:**

```
Build lib/features/dashboard_home/dashboard_home_screen.dart: the single home
screen of the app, shown right after sign-in. Layout:
- A warm greeting at the top using the user's display_name and time of day
  ("Good morning, Anima").
- A row/grid of 5 large, icon-led tiles, each navigating to a feature (the
  features themselves are placeholders for now, built in later phases):
  Games, Voice Assistant, My Journal, Reminders, My Progress.
- A "Today" card below the tiles showing: today's pending reminders (pull
  from a placeholder empty list for now) and a simple streak indicator
  ("You've played 3 days in a row!").
- A settings icon (top-right) opening a simple settings screen: language
  picker (English/Hindi/Assamese/Bengali), text-size slider, a toggle for
  reduced motion, and a sign-out button.

This is the ONLY home/navigation screen in the app. Every one of the 5
tiles above must be reachable in a single tap from here, and every other
screen in the app should have a clear way back to this screen (not just
Android's back button).
```

**Check:** After signing in, you land on this screen. All 5 tiles are visible,
tappable, and large enough to comfortably tap on a phone screen without precision.
Settings opens and the language picker works (even if it doesn't do anything yet).

---

## Phase 2.4 — Local offline storage & the sync engine (client side)

**Goal:** This is the technical core that makes "offline-first" actually true. Every
game result, reminder, and journal entry gets saved to the phone first, and only
sent to the cloud later — the user should never notice or care whether they're
online.

**Prompt to paste into Antigravity:**

```
Add the drift package (SQLite for Flutter) to this project. In
lib/core/database/, define tables matching docs/data_model.md exactly (same
field names): game_sessions, cognitive_scores, journal_entries, reminders.
Each table needs a client_generated_id (a UUID generated on-device) and a
synced_at column (nullable — null means "not yet synced").

In lib/core/sync/outbox_sync_service.dart, build a SyncService class with:
- A method queueForSync(record) that writes a record to its local table
  immediately (this should always succeed, online or offline — this IS the
  save, not a cache of the save).
- A method syncPendingRecords() that: checks connectivity
  (connectivity_plus package), if online, batches all rows where synced_at
  is null, POSTs them to Part 1's backend /sync/batch endpoint (base URL
  from a config file — leave a TODO comment for the real deployed URL from
  Part 1's Phase 1.9), and on a successful response marks matching rows
  synced_at = now(). Handle partial failures gracefully (some records synced,
  some not — only mark the successful ones).
- A background trigger: call syncPendingRecords() on app start, whenever
  connectivity_plus reports the device came back online, and every 15
  minutes while the app is in the foreground (use a simple Timer, not
  workmanager, for this in-foreground case — workmanager background sync
  comes later in Part 3's reminder work).

Write a widget test that: writes a record while "offline" (mock
connectivity), confirms it's saved locally, then simulates coming online and
confirms syncPendingRecords sends it.
```

**Check:** Run the widget test — it passes. Manually test: turn on airplane mode on
your test device, do something that queues a record (you can trigger this with a
temporary debug button for now, since games aren't built yet), confirm you can see
it in the local SQLite file (Antigravity can show you how to inspect it, or use a
tool like DB Browser for SQLite), turn off airplane mode, confirm it syncs.

---

## Phase 2.5 — Cognitive Games: the shared game framework + first game

**Goal:** Build one reusable pattern all 9 games will follow, then build the first
real game on top of it, so the remaining games in Phase 2.6 go quickly.

**Prompt to paste into Antigravity:**

```
In lib/features/games/, build a shared game framework:
- game_result.dart: a simple data class {game_id, domain, accuracy (0-1),
  response_time_ms, played_at} — this is what every game produces when it
  ends, and it maps directly onto the game_sessions table from Phase 2.4.
- game_session_controller.dart: a reusable controller any game screen can use
  to start a timer, record each answer as correct/incorrect, compute a final
  accuracy and total response time when the round ends, build a
  GameResult, save it via SyncService.queueForSync(), and then call Part 1's
  adaptive difficulty logic (for now, just POST the result to
  /games/sessions and use the returned {new_level, reason} — this
  automatically updates the user's difficulty; if offline, skip this call
  and just queue the result — difficulty simply won't change until the next
  successful sync, which is fine).
- games_menu_screen.dart: a screen (reached from the dashboard's "Games"
  tile) listing all 9 games as large tappable cards with a simple icon and
  name for each, grouped loosely by domain.

Then build the first full game: matching_image_game.dart (VISUAL_MEMORY
domain). Show a grid of 6-8 image cards face-down; the player taps two at a
time to find matching pairs (use culturally relevant placeholder images for
now — regional food, Bihu instruments, traditional homes — a simple colored
icon set is fine as a placeholder until real art assets exist). On
completion, use game_session_controller to record accuracy (based on
mismatched attempts) and response time, show a warm, encouraging completion
message (not a numeric score front-and-center), and return to
games_menu_screen.
```

**Check:** From the dashboard, tap Games → Matching Image, play a full round,
complete it, see the encouraging message, and confirm (via the SQLite inspection
from Phase 2.4) that a game_sessions row was created.

---

## Phase 2.6 — Build the remaining 8 games

**Goal:** Same pattern as Phase 2.5, repeated. This phase is naturally parallelizable
— Member 3 and Member 4 can each take a few games and build them side by side once
the framework from 2.5 is solid.

**Prompt to paste into Antigravity (repeat once per game, swapping in the details
from the table below):**

```
Using the same framework as matching_image_game.dart (game_session_controller,
consistent completion flow), build [GAME NAME] as
lib/features/games/[file_name].dart for the [DOMAIN] domain.

[GAME DESCRIPTION — paste from the table below]

Add it to games_menu_screen.dart's list of 9 games.
```

| Game name | Domain | Description to paste in |
|---|---|---|
| Draw What You Saw | VISUAL_MEMORY | Show a simple shape/object for 5 seconds, hide it, let the player draw on a canvas what they remember (use a simple finger-drawing canvas widget), score by rough shape-similarity or just completion (simplest v1: did they draw something within the time limit — refine later). |
| Place Correctly | SPATIAL | Show 4-6 draggable shapes/objects and matching outlined "slots"; player drags each to its correct slot; score by correct placements / total. |
| Find the Differences | ATTENTION | Show two nearly-identical images side by side with 3-5 differences; player taps the differences; score by differences found within the time limit. |
| Pick the Correct One | RECALL | Show a prompt ("Pick the fruit") and 4 options; player taps the correct one; score by correct/total across several rounds. |
| Recall My Memories | RECALL | Placeholder screen for now that shows "Add some memories in My Journal first!" if the user has fewer than 3 journal entries — the real version is built in Part 3's Phase 3.2 once the journal and AI quiz generation exist; leave a clear TODO comment linking to that phase. |
| Match the Situation | REASONING | Show an everyday situation as text or a simple image ("It's raining. What would you take?") with 4 options; player picks the best match; score by correct/total. |
| Simple Number/Math Game | NUMERACY | Show simple counting or "what comes next" sequences (1, 2, 3, __) with 4 tappable options; score by correct/total. |
| Family-Related Quiz (REMOVED) | — | Do not build this game. It depended on family-supplied photos and is explicitly out of scope for this version of the product — see PRD.md Section 5, "Out of scope." |

**Check per game:** Play a full round of each game from the games menu, confirm it
completes, shows an encouraging (not clinical) result message, and produces a
game_sessions row. Note that "Family-Related Quiz" is intentionally not built —
that's correct, not a missing step.

---

## Phase 2.7 — On-device Adaptive Difficulty

**Goal:** Games should adapt to the player even fully offline, without waiting for a
server response — this phase ports Part 1's backend logic into the app itself.

**Prompt to paste into Antigravity:**

```
In lib/core/database/, build a Dart port of the adaptive difficulty logic:
adaptive_difficulty.dart implementing the exact same rules as Part 1's
backend/app/services/adaptive_difficulty.py (ask me for that file's contents
if you don't already have it in context) — same thresholds (promote at
composite >= 0.78, demote at <= 0.45, minimum 3 attempts, same 60/30/10
weighting), and the same warm, plain-English reason strings, just written in
Dart instead of Python.

Wire game_session_controller.dart (from Phase 2.5) to: after saving a game
result locally, always compute the new difficulty level using this on-device
function immediately (regardless of connectivity), and use that level for the
very next round of that game. If a later sync to the backend returns a
different level (e.g. because the backend saw sessions from another of the
user's devices too), reconcile by taking whichever level is higher-confidence
(more attempts considered) — add a comment explaining this reconciliation
choice.

Write a Dart unit test confirming the on-device function produces identical
level decisions to at least 3 example input sequences you'd expect from the
Python test file in Part 1's Phase 1.5.
```

**Check:** Run `flutter test` — the new test passes. Manually play a game several
times in airplane mode and confirm the difficulty visibly changes (e.g. more image
pairs, more distractor options) without needing to go online.

---

## Phase 2.8 — "My Progress" trend view

**Goal:** Build the screen that replaces the old caregiver dashboard's charts — but
written for the user themselves, not a third party.

**Prompt to paste into Antigravity:**

```
Build lib/features/progress/my_progress_screen.dart, reached from the
dashboard's "My Progress" tile. Show:
- One simple trend chart per cognitive domain (VISUAL_MEMORY, ATTENTION,
  SPATIAL, RECALL, REASONING, NUMERACY) using the fl_chart package, plotting
  composite_score over the last 14 days from local cognitive_scores data
  (works fully offline — reads local SQLite, doesn't require a network call).
- Under each chart, show the current human-readable "reason" string from the
  adaptive difficulty engine (Phase 2.7), in large, friendly text — this is
  the primary content, the chart is secondary support for someone who likes
  seeing a visual trend.
- A simple weekly streak/consistency summary at the top ("You've played
  something every day this week!").
- No numeric score should be the FIRST thing the eye lands on — lead with
  encouragement, follow with the optional detail. Use a "See more detail"
  expand rather than showing raw numbers by default.
```

**Check:** After playing a few rounds across different games (Phase 2.5–2.6), open
My Progress and confirm charts render with real local data, and the reason text
matches what Phase 2.7 is producing.

---

## Phase 2.9 — Accessibility pass & internal testing

**Goal:** Before handing this off to be combined with Part 3's work, make sure the
whole dashboard genuinely works for the target user — an elder who may have low
digital literacy, low vision, or motor difficulty.

**Prompt to paste into Antigravity:**

```
Review every screen built so far in lib/features/ against this checklist and
fix anything that fails:
1. Every tappable element is at least 56x56 logical pixels.
2. Every screen has a visible, obvious way back to dashboard_home_screen
   (not reliant on hardware back button alone).
3. Text respects the user's text-size multiplier from settings (Phase 2.3)
   everywhere, with no text overflow/clipping at the largest size.
4. Color contrast passes WCAG AA on every screen (check text against its
   background).
5. No screen anywhere in the app references "caregiver," "family member," or
   requires a second account/login/approval to use any feature.
6. Every game and the sync engine work correctly with the device in airplane
   mode (except the one-time backend sync, which should queue gracefully,
   not crash or hang).

List every fix made as a short changelog at the bottom of your response.
```

**Check:** Physically test on a real Android phone if possible (emulators hide real
touch-target and readability issues). Have someone unfamiliar with the app try to
use it — can they find and complete a game without help?

---

## What Part 2 hands off to Part 3

By the end of this document:
- A working dashboard app with sign-in, home screen, all 9 games (except the
  Recall-My-Memories real content, which needs Part 3's journal), offline sync,
  on-device difficulty, and My Progress.
- Push everything to the shared repo and message Part 3 that `dashboard_app/` is
  ready for them to add their journal, voice, and reminder features into the
  `lib/features/journal/`, `lib/features/voice/`, and `lib/features/reminders/`
  folders you already scaffolded in Phase 2.1.
