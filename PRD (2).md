# Product Requirements Document — Smriti AI

| | |
|---|---|
| **Product** | Smriti AI |
| **Document owner** | Product Team |
| **Status** | Draft — v2.0 (single-dashboard, no-caregiver revision) |
| **Last updated** | September 3, 2026 |
| **Related doc** | [README.md](./README.md) — engineering-facing build & setup guide |

---

## 0. Revision note (read this first)

This is a revision of the original PRD. The earlier version described three
connected surfaces — a patient mobile app, a caregiver web dashboard, and a
family-photo-driven Memory Vault. **This version replaces that with a single,
self-contained dashboard app for one person, with no caregiver role and no
family-member features anywhere in the product.** Every section below reflects the
new scope. Where a feature was removed rather than renamed, that is called out
explicitly so nothing is lost by accident — it is a deliberate design decision,
explained in Section 2 and Section 4.

---

## 1. Executive summary

Smriti AI is a single, offline-first dashboard app for people living with early-stage
dementia or mild cognitive impairment. One app, one login, one home screen — the
dashboard — brings together culturally grounded cognitive-stimulation games, a
multilingual voice assistant, a private Personal Memory Journal that turns the user's
own photos and voice notes into gentle reminiscence activities and AI-narrated
stories, daily reminders, and a simple "My Progress" trend view. All of it works with
**no internet connection** and syncs to Firebase the moment connectivity returns.

The product is designed first for elders in low-connectivity, multilingual regions of
North-East India (Assamese, Bengali, Hindi, and English), where existing cognitive-care
apps assume constant connectivity, a single national language, and — critically — a
second person (a caregiver or family member) managing the experience on the user's
behalf. Smriti AI removes that assumption by design: it is built to be used
independently, by the person themselves, to build their own memory practice and their
own sense of routine and wellbeing.

---

## 2. Problem statement

- **Cognitive decline is under-supported outside clinics.** Structured cognitive
  stimulation (memory games, reminiscence therapy, routine reinforcement) measurably
  helps people with mild cognitive impairment and early dementia, but it normally
  requires a trained facilitator repeating sessions daily — something most families
  and rural health systems cannot sustain.
- **Connectivity cannot be assumed.** Many of the users who would benefit most live
  in low-connectivity areas. An app that requires a live connection to play a game,
  hear a prompt, or fire a reminder is unusable exactly when it's needed most.
- **Language and culture are not an afterthought.** Generic "brain training" content
  (Western idioms, unfamiliar imagery) does not trigger recognition or engagement in
  elderly users who think and remember in Assamese, Bengali, or Hindi, and in the
  imagery of their own festivals, food, and homes.
- **Dependency on a second person is itself a barrier — and not the goal.** Many
  existing tools (and the original version of this project) are structured around a
  caregiver or family member: uploading photos, tagging faces, approving content,
  watching a dashboard. That model assumes an available, engaged second person, which
  is not always true, and it quietly shifts the product's purpose away from the
  user's own cognitive and emotional wellbeing and toward someone else's peace of
  mind. **Smriti AI's problem statement is deliberately narrower and more personal:
  give one person a private, independent, day-to-day practice that helps them keep
  their memory active, keep a routine, and feel good about their day — without
  requiring anyone else's involvement to work.**

---

## 3. Goals & success metrics

| Goal | Metric | Target (first 6 months post-launch) |
|---|---|---|
| Sustained daily engagement | % of users completing ≥1 game session/day | ≥ 60% |
| Works without connectivity | % of core sessions (games, voice, reminders) completed fully offline | 100% functional; track % actually offline |
| Independent use | % of users who complete onboarding and first week of use without any second account being created or involved | ≥ 90% |
| Cognitive tracking utility | % of users who view their own "My Progress" view weekly | ≥ 50% |
| Multilingual reach | % of sessions conducted in a language other than English | ≥ 40% |
| Journal engagement | % of users who add at least one Personal Memory Journal entry in month 1 | ≥ 35% |
| Data trust | Zero unresolved critical Firestore security-rule violations | 0 |

These are directional targets for planning, not results already achieved — see
[Section 12, Roadmap](#12-roadmap--phased-delivery) for current build status.

---

## 4. Target user

### 4.1 The single persona

| Persona | Who | Core need |
|---|---|---|
| **The User** | An elder (60+) with mild cognitive impairment or early-stage dementia, may have low literacy, prefers speaking over typing | A simple, private, voice-guided daily activity that builds their own memory and mood, entirely on their own terms |

Smriti AI supports **exactly one persona and one account type.** There is no
caregiver, no family member, and no health-worker role in this version of the
product.

### 4.2 Why the earlier caregiver and family-member roles were removed

The original problem statement (SIH26003) called for "caregiver/health-worker
monitoring" as a required feature, and the first draft of this product included a
caregiver web dashboard and family-photo-based memory features. This revision
removes all of that, for three product reasons:

1. **It changes who the product is for.** A caregiver dashboard makes the caregiver
   the primary user of half the product. Smriti AI's purpose is the user's own
   cognitive engagement and daily wellbeing — not producing a report for someone
   else to read.
2. **It introduces a dependency the product shouldn't require.** Family-photo
   tagging, story approval, and reminder escalation only work if a second,
   consistently available person exists and participates. Many users do not have
   that. A product that only fully works with a second person is not truly
   independent.
3. **It changes the emotional framing.** Being "monitored" and being "supported to
   build your own routine" are different experiences for the person actually living
   with memory changes. This product is intentionally framed as the second one.

Nothing in this document uses the word "caregiver," and no feature described below
depends on a family member's account, upload, tagging, or approval.

---

## 5. Scope

### In scope (v1)

- **One dashboard app** (Flutter — Android and iOS primary, Web supported from the
  same codebase for users who prefer a larger screen) — offline-first
- 9 cognitive mini-games spanning 6 domains (visual memory, attention, spatial,
  recall, reasoning, numeracy)
- Rule-based, explainable adaptive difficulty engine
- Multilingual voice assistant (STT + TTS) in English, Hindi, Assamese, Bengali, with
  offline capability for Assamese and Bengali
- Personal Memory Journal: on-device photo storage, simple self-tagging (place,
  object, event — not a family/relationship graph), AI-assisted personal-recall quiz
  generation and story narration, entirely self-authored and self-reviewed
- Reminder system with local notifications and in-app, self-directed gentle follow-up
  (no escalation to a second party)
- Local SQLite cache with an outbox-based sync engine to Cloud Firestore (so the same
  user's data follows them across their own devices)
- Firebase Authentication (email/password, Google Sign-In, device pairing)
- "My Progress" — a trend and streak view **inside the single dashboard app**,
  visible only to the signed-in user
- Firestore/Storage security rules scoping all data to the individual `user_id`
- Consent records for data collection (photos, voice, cognitive scores) — captured
  from and for the user themselves

### Out of scope (v1)

- Clinical diagnosis or classification of dementia stage (Smriti AI supports the
  user's own cognitive engagement; it does not diagnose)
- **Any caregiver, family-member, or health-worker account, role, or dashboard**
- **Any feature that requires a second person's photos, tagging, consent, or
  approval to function** (this includes the earlier "Family Quiz" and "Family Game
  Mode" concepts, which are explicitly removed, not deferred)
- Video calling / telehealth
- Wearable-device integration
- Languages beyond English, Hindi, Assamese, Bengali
- Billing/subscription management

---

## 6. Feature requirements

### 6.1 Cognitive Games Suite

**User story:** As a user, I want short, encouraging games with pictures and sounds I
recognize, so that I can build a daily habit without feeling tested or judged, and
without needing anyone else present.

- 9 games across the following domains: `VISUAL_MEMORY`, `ATTENTION`, `SPATIAL`,
  `RECALL`, `REASONING`, `NUMERACY`.
- Confirmed launch content includes:
  - **Matching Image** (`VISUAL_MEMORY`) — match culturally familiar images (e.g.
    Bihu instruments, regional food).
  - **Recall My Memories** (`RECALL`) — a personal-recall quiz built from the
    user's own Personal Memory Journal entries (their own photos and notes about
    their own life) — replaces the earlier "Family Quiz," which depended on
    family-supplied photos.
  - **Place Correctly** (`SPATIAL`) — drag household/cultural objects to their
    correct location.
  - **Find the Differences** (`ATTENTION`) — spot differences in festival/cultural
    scenes.
  - Remaining games extend the same content model into `REASONING` and `NUMERACY`
    and are tracked in the [roadmap](#12-roadmap--phased-delivery).
- Every game must be fully playable with zero network connectivity, and every game
  must be launchable directly from the single dashboard's home screen in one tap.
- Each round is scored for correctness and response time and feeds the Adaptive
  Difficulty Engine (Section 6.2).
- Content is tagged by culture/region so future locales can swap content packs
  without code changes.

**Acceptance criteria**
- A user can start, play, and complete a full game session with the device in
  airplane mode.
- Game results are queued locally and sync automatically once online, with no
  duplicate or lost attempts (see Section 6.6).
- No game screen, prompt, or result requires a second account to view or unlock.

### 6.2 Adaptive Difficulty Engine

**User story:** As a user, I want the game to get easier when I'm struggling and more
interesting when I'm doing well, so that I stay engaged instead of frustrated or
bored.

- Rule-based, explainable engine (not a black-box model) — every difficulty change
  must be traceable to a human-readable reason, and that reason is shown to the user
  themselves in the dashboard's "My Progress" view, in plain, encouraging language.
- Per-domain scoring: accuracy (EWMA-smoothed), speed score, short-term trend, and a
  weighted composite score (60% accuracy / 30% speed / 10% trend).
- Promotion threshold: composite ≥ 0.78 (levels capped at 5). Demotion threshold:
  composite ≤ 0.45 (floor at level 1).
- Requires a minimum of 3 attempts in a domain before adapting, to avoid premature
  swings.
- Runs identically on-device (offline) and on the backend, so difficulty adapts
  correctly with or without connectivity.

**Acceptance criteria**
- Given identical input sequences, the on-device and backend implementations produce
  the same level decision and the same human-readable explanation string.
- The explanation string is phrased for the user themselves ("You've been getting
  quicker at this one, so it's stepping up a little"), not for a third-party report.

### 6.3 Multilingual Voice Assistant

**User story:** As a user who is more comfortable speaking than reading, I want the
app to talk to me and understand me in my own language, so I can use the whole
dashboard — games, journal, reminders — by voice alone if I want to.

- Supported locales at launch: `en-US`, `hi-IN`, `as-IN`, `bn-IN`.
- Offline STT/TTS guaranteed for Assamese and Bengali; other locales fall back
  gracefully with a clear "voice needs internet" indicator when offline.
- Cultural, pre-authored voice prompts for greetings, game instructions, reminders,
  encouragement, and story narration — not machine-translated at runtime, to
  guarantee natural phrasing.
- Speech rate and pitch tuned for elderly listening comfort (default: 0.5x rate).

**Acceptance criteria**
- Switching the app's language setting immediately changes all spoken prompts with
  no restart required.
- A user can complete an entire game session, and navigate the dashboard's main
  sections, using only voice, without touching the screen.

### 6.4 Personal Memory Journal

**User story:** As a user, I want to keep my own photos and memories in one private
place and have the app gently bring them back to me, without needing anyone else to
set it up for me.

This feature replaces the earlier "Memory Vault," which was built around family
members uploading and tagging photos of relatives. The Personal Memory Journal is
**single-author, single-audience**: the user adds their own content, and only the
user ever sees it.

- On-device storage of the user's own photos and short voice notes.
- Simple, optional self-tagging: a place, an object, an occasion, a short caption —
  **not** a person/relationship graph. There is no "who is this family member"
  feature.
- Journal entries feed the "Recall My Memories" game (Section 6.1) and an
  AI-narrated short story mode.
- AI-assisted story generation narrates a short, warm reflection on a journal
  entry using an LLM (Gemini), passed through a content-safety guard **before it is
  ever shown or spoken to the user.** Because there is no second-party review step
  in this design, the content guard is the sole safety gate and must default to the
  most conservative, gentle output — reject and fall back to a simple, safe template
  rather than surface anything ambiguous.
- The user can edit, delete, or re-record any journal entry themselves at any time;
  there is no separate "approval" workflow because there is no second party to
  approve on the user's behalf.

**Acceptance criteria**
- Journal creation, tagging, and browsing all work fully offline; entries sync when
  connectivity returns.
- No AI-generated story is surfaced to the user without passing the content guard.
- The data model contains no field that stores another person's identity, account,
  or relationship to the user (no "family member," no "relative," no "contact").

### 6.5 Reminder System with Gentle Follow-Up

**User story:** As a user, I want a kind reminder about my medicine or routine, and a
gentle nudge if I miss it — without it being reported to anyone else.

- Reminders (medication, appointments, routines) are scheduled locally as device
  notifications and mirrored to Firestore under the user's own account only.
- Reminders fire and log attempts fully offline via local notifications and
  background work (WorkManager).
- **Follow-up, not escalation:** a missed or dismissed reminder triggers a second,
  softer in-app nudge and is logged to the user's own "My Progress" view. It does
  **not** generate an alert to any other person or device — there is no caregiver
  dashboard to receive one.
- Voice-spoken reminders use the same multilingual prompt system as Section 6.3.

**Acceptance criteria**
- A reminder scheduled while offline fires at the correct local time without any
  network call.
- A missed reminder appears, within the same session or the next app open, in the
  user's own "My Progress" view — and nowhere else.

### 6.6 Offline-First Sync Engine

**User story:** As a user in an area with poor signal, I want the app to work exactly
the same whether or not I'm online, and to see the same journal, scores, and
reminders if I use the app on a second device of my own.

- All user-facing writes (game attempts, cognitive scores, reminder logs, journal
  entries) are written first to a local SQLite database (Drift) via an **outbox**
  pattern.
- A background sync engine uploads the outbox to Firestore when connectivity is
  restored, with conflict resolution rules for concurrently edited records.
- Firestore offline persistence is enabled as a second layer of resilience for reads.
- Sync is always scoped to a single `user_id` — there is no multi-account merge or
  sharing logic anywhere in the sync engine.

**Acceptance criteria**
- Simulated offline test: install app, enable airplane mode, complete games, add a
  journal entry, and create reminders, disable airplane mode, verify all records
  reach Firestore with no duplicates or loss.

### 6.7 The Dashboard (Single Home Screen)

**User story:** As a user, I want one place — one screen I always come back to —
that shows me my games, my journal, my reminders, and how I'm doing, without having
to open a different app or ask someone else to check it for me.

This is the feature that replaces the earlier "caregiver web dashboard." There is
now exactly one dashboard, it lives inside the same app the user already uses, and it
is built for the user themselves:

- A home screen with clear, large, icon-led entry points to: Games, Voice Assistant,
  Personal Memory Journal, Reminders, and My Progress.
- **My Progress** panel: simple trend view of the user's own cognitive-domain scores
  over time, with the same plain-language explanations produced by the Adaptive
  Difficulty Engine (Section 6.2) — framed as encouragement, not clinical reporting.
- Today's reminders and a friendly streak/consistency indicator, shown at a glance.
- Settings: language, voice speed, text size/contrast, notification preferences —
  all self-service, with no separate settings surface for anyone else.

**Acceptance criteria**
- Every feature in this PRD is reachable from the single dashboard home screen within
  two taps.
- The dashboard renders and is fully usable at large text sizes and high-contrast
  mode without layout breakage.
- No screen in the app requires switching to a second app, second login, or second
  device role to view any user data.

### 6.8 Authentication & Access Control

- Firebase Authentication: email/password, Google Sign-In, and device pairing (for
  users who prefer not to manage credentials themselves).
- **Single role (`user`)** enforced both in the backend (JWT/Firebase ID token
  verification) and in Firestore/Storage security rules — never trust the client
  alone. There is no `family_member` or `caregiver` role anywhere in the auth model.
- Consent records capture explicit, revocable consent for photo storage, voice
  recording, and cognitive-score collection, given by the user for their own data.

---

## 7. Non-functional requirements

| Category | Requirement |
|---|---|
| **Offline resilience** | Games, voice, reminders, and the journal must be 100% functional with zero connectivity. |
| **Data residency** | Firestore/Storage regions default to `asia-south1` (Mumbai) to minimize latency for North-East India and align with data-locality expectations. |
| **Accessibility** | Large touch targets, high-contrast UI, voice-first interaction paths, reduced-motion option, short session lengths appropriate for elderly attention spans. |
| **Privacy & consent** | No photo, voice sample, or cognitive score is collected without an explicit consent record from the user; consent is revocable and revocation halts further collection. No user data is ever readable by a second account. |
| **Security** | All cross-cutting access is governed by Firestore/Storage security rules scoped to a single `user_id`; secrets (service-account keys) are never committed to source control. |
| **Explainability** | Every adaptive-difficulty decision and every cognitive-score trend shown in the dashboard must include a human-readable reason, phrased for the user themselves. |
| **Performance** | Game round transitions render in under 300ms on a mid-range Android device; sync of a typical day's outbox completes in under 10 seconds on a 3G connection. |
| **Localization** | All user-facing copy and voice prompts are authored (not machine-translated) for English, Hindi, Assamese, and Bengali. |
| **Content safety** | All AI-generated content (stories, quiz text) passes through a content guard before reaching the user — this is the sole safety gate, so it must default to rejecting ambiguous output. |

---

## 8. System architecture (summary)

Smriti AI is Firebase-first: Cloud Firestore is the system of record, Cloud Storage
holds the user's own photos/audio, Firebase Auth handles identity, and Cloud
Messaging delivers the user's own reminder notifications to their own device(s). A
single Flutter app (mobile + web from one codebase) is the **only** front-end
surface; a FastAPI backend handles orchestration, AI generation (Gemini), reminder
scheduling (Celery), and sync support. Full component and data-flow diagrams live in
[README.md](./README.md#architecture).

---

## 9. Data model (high level)

Primary Firestore collections: `users`, `games`, `game_sessions`,
`cognitive_scores`, `journal_entries` (`photos`, `voice_notes`, `tags`),
`reminders`, `consents`.

Every document in every collection carries a single `user_id` field and is scoped to
that user alone. There is intentionally **no `families` collection, no
`caregiver_uids` field, and no `family_uids` field** anywhere in this schema — that
is the concrete data-model consequence of Section 4.2's decision. Full schema
sketches and security rules are documented in the engineering build guide and
mirrored in [README.md](./README.md).

---

## 10. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Offline sync conflicts corrupt cognitive score history | Loss of user trust in their own trend data | Deterministic, tested conflict-resolution rules; append-only score logs rather than destructive overwrites |
| AI-generated stories say something upsetting or inaccurate to a vulnerable user | Emotional harm — with no second-party backstop to catch it | Mandatory, conservative content guard on every single AI output; safe static fallback template when the guard is uncertain |
| Removing caregiver escalation means a genuinely urgent situation (e.g. repeated missed medication) goes unnoticed by anyone | Missed real-world safety signal | In-app, user-facing gentle follow-ups and streak visibility are the mitigation within this product's chosen scope; this is a deliberate scope boundary (see Section 4.2), not an oversight — call out clearly in onboarding that Smriti AI is a personal wellness tool, not an emergency or medical monitoring system |
| Low digital literacy limits dashboard adoption | Missed reminders, low engagement | Voice-first experience does not depend on typing or navigation skill; dashboard prioritizes glanceable cards and icons over dense data |
| Firestore security rules misconfigured | Data leakage across user accounts | Security-rule test suite required before each deploy; rules reviewed in every release checklist |

---

## 11. Open questions / assumptions

- Which two additional languages (if any) are prioritized after Assamese and
  Bengali for offline voice support?
- Should the remaining 5 of the 9 games be net-new content or additional difficulty
  packs on the existing 4 confirmed games?
- What is the data-retention policy once a user revokes consent — immediate
  deletion vs. anonymized retention for aggregate product-improvement analytics
  (never shared with a second party about that specific user)?
- Should "My Progress" eventually support an optional, user-initiated export (e.g. a
  PDF the user can choose to print or share themselves) — this would remain
  user-initiated, not an automatic caregiver feed, to stay consistent with Section 4.2.

---

## 12. Roadmap / phased delivery

| Phase | Scope | Status |
|---|---|---|
| 0 – Firebase project setup | Auth, Firestore, Storage, Cloud Messaging provisioning | Planned |
| 1 – Backend & Firebase Admin | FastAPI + Firestore service layer, auth router | Planned |
| 2 – Dashboard app shell & Firebase integration | Flutter auth + Firestore client + single dashboard home screen | Planned |
| 3 – Offline-first architecture | Local SQLite, outbox sync engine | Planned |
| 4 – Cognitive games | 9 games, 6 domains, culturally tagged content | Planned |
| 5 – Multilingual voice assistant | STT/TTS in 4 languages, offline for Assamese/Bengali | Planned |
| 6 – Adaptive difficulty engine | Rule-based, explainable scoring (backend + on-device) | Planned |
| 7 – Personal Memory Journal | On-device storage, self-tagging, AI story generation + content guard | Planned |
| 8 – Reminders & gentle follow-up | Local notifications, in-dashboard nudges | Planned |
| 9 – My Progress view | Trend charts and streaks inside the single dashboard | Planned |
| 10 – Testing & deployment | Security rules, offline test pass, production build | Planned |

This mirrors the day-by-day engineering build guide. Update the **Status** column as
each phase ships; see [README.md](./README.md#current-status) for the
engineering-facing checklist.

---

## 13. Glossary

- **Dashboard** — the single home screen inside the Smriti AI app that surfaces
  every feature (games, voice, journal, reminders, progress) to the user. There is
  only one dashboard in this product, and it belongs to the user.
- **Personal Memory Journal** — the user's own private space for their own photos
  and voice notes, used to personalize games and stories. Replaces the earlier
  "Memory Vault" concept, which depended on family-supplied content.
- **Composite score** — the weighted accuracy/speed/trend score that drives adaptive
  difficulty decisions.
- **Outbox** — the local queue of not-yet-synced writes used to guarantee offline
  durability.
- **Content guard** — the automated safety check every AI-generated story or quiz
  prompt must pass before reaching the user. It is the sole safety gate in this
  design (see Section 6.4).
