# SMIRITI-AI — Cognitive Care & Wellness Application

An offline-first, single-user cognitive care platform designed specifically for elderly wellness and memory care. The system integrates a calm, high-contrast Flutter mobile dashboard with a FastAPI and Google Cloud Firestore backend, supporting local-first Drift SQLite storage, outbox-pattern synchronization, AI journal story generation, cognitive games, and smart reminders.

---

## 1. Project Architecture

The architecture follows a strict **offline-first local-database-first pattern**:

```
Flutter UI (Dashboard / Journal / Games / Reminders / Voice)
   ↓
Domain Repositories (JournalRepository, ReminderRepository, GameRepository)
   ↓
Drift SQLite Local Database (Single source of truth for UI, schemaVersion: 2)
   ↓
Outbox Queue Table (Pending operations: create / update / delete)
   ↓
SyncService (Collision-safe, re-entrant protected, periodic & network-triggered)
   ↓ (Bearer Token)
FastAPI Backend (POST /sync/batch, GET /sync/{collection})
   ↓
Firebase Authentication Verification (UID ownership validation)
   ↓
Google Cloud Firestore
```

### Key Architectural Invariants
1. **Offline Integrity:** All writes save to Drift SQLite immediately and enqueue an Outbox event (`synced = false`). Guest and offline users have full app functionality.
2. **Synchronization Contract:** Standardized `POST /sync/batch` accepting `{"records": [{"collection", "client_generated_id", "operation", "data"}]}` and returning `results` and `successful_record_ids`.
3. **Collision Safety:** All entity and attempt IDs use compound millisecond timestamps and cryptographically sound UUID substrings (e.g. `reminder_<timestamp>_<uuid>`).
4. **Zero Cross-User Leakage:** The backend never trusts client-supplied `user_id`. The authenticated Firebase UID strictly controls document ownership across all create, update, delete, and pull operations.

---

## 2. Directory Structure

```
SMIRITI-AI/
├── dashboard_app/             # Flutter Mobile & Desktop Application
│   ├── lib/
│   │   ├── core/
│   │   │   ├── config/        # AppConfig (Centralized base URL & environments)
│   │   │   ├── database/      # Drift SQLite database, tables, repositories
│   │   │   ├── firebase/      # FirebaseService wrapper
│   │   │   └── sync/          # SyncService & HTTP client
│   │   ├── features/
│   │   │   ├── dashboard/     # Accessible home grid & navigation
│   │   │   ├── journal/       # Memory journal & AI story generator
│   │   │   ├── games/         # Cognitive stimulation games & scoring
│   │   │   ├── reminders/     # Smart reminders & notifications
│   │   │   └── voice/         # Multilingual speech assistant
│   │   └── main.dart
│   ├── test/                  # 115 comprehensive unit & widget tests
│   └── pubspec.yaml
│
├── backend/                   # FastAPI Backend
│   ├── app/
│   │   ├── core/              # Firebase Admin, dependencies, config
│   │   ├── routers/           # auth, sync, journal, reminders, games
│   │   ├── schemas/           # Pydantic request/response models
│   │   └── main.py            # FastAPI entrypoint, /health, /ready
│   ├── tests/                 # 123 pytest suites
│   ├── Dockerfile             # Production container definition
│   ├── requirements.txt
│   └── .env.example
│
├── render.yaml                # Render Cloud Deployment Blueprint
└── README.md
```

---

## 3. Local Development Setup

### Prerequisites
- **Flutter SDK:** `>=3.13.0` (Dart `>=3.0.0 <4.0.0`)
- **Python:** `3.12+`
- **Node.js & Firebase CLI:** (optional, for Firestore emulator)

---

### Backend Setup

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Create and activate a virtual environment:**
   ```bash
   python -m venv .venv
   # Windows PowerShell:
   .venv\Scripts\Activate.ps1
   # macOS/Linux:
   source .venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your Firebase configuration or leave for local mock mode
   ```

5. **Run the backend development server:**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

- **Health Check URL:** `http://localhost:8000/health`
- **Readiness Check URL:** `http://localhost:8000/ready`
- **Interactive Swagger Documentation:** `http://localhost:8000/docs`

---

### Flutter Setup

1. **Navigate to the dashboard app:**
   ```bash
   cd dashboard_app
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Configure environment:**
   ```bash
   cp .env.example .env
   ```

4. **Run Flutter locally:**
   - On Android Emulator (automatically routes to `http://10.0.2.2:8000` via `AppConfig`):
     ```bash
     flutter run
     ```
   - On Desktop / Chrome / iOS:
     ```bash
     flutter run -d chrome
     # or
     flutter run -d windows
     ```
   - Targeting a specific staging/production backend:
     ```bash
     flutter run --dart-define=API_BASE_URL=https://smriti-ai-backend.onrender.com
     ```

---

## 4. Running Verification & Tests

### Backend Tests
```bash
cd backend
python -m pytest
python -m compileall app
```

### Flutter Analysis & Tests
```bash
cd dashboard_app
flutter analyze
flutter test
```

---

## 5. Production Deployment (Render / Docker)

### Docker Container Build & Run
The backend Dockerfile is fully containerized using Python 3.12-slim and dynamically binds to platform `$PORT` variables:

```bash
cd backend
docker build -t smriti-ai-backend:latest .
docker run -p 8000:8000 -e PORT=8000 -e ENVIRONMENT=production smriti-ai-backend:latest
```

### Deploying to Render
1. Connect your GitHub repository to [Render](https://render.com).
2. Render uses `render.yaml` or Docker runtime:
   - **Environment:** Docker
   - **Dockerfile Path:** `./backend/Dockerfile`
   - **Docker Context:** `./backend`
   - **Health Check Path:** `/health`
3. Configure Environment Variables in the Render Dashboard:
   - `FIREBASE_PROJECT_ID`
   - `ALLOWED_ORIGINS`
   - `ENVIRONMENT=production`
   - Firebase Admin service account credentials (via environment variables or Application Default Credentials).
