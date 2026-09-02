## Firebase authentication tests

1. Copy `.env.example` to `.env` and fill in the Firebase settings.
2. Place the downloaded `service-account-key.json` in this directory, or set
	`FIREBASE_CREDENTIALS_PATH` to its path.
3. Create a Firebase test user with Email/Password in Firebase Console.
4. Obtain an ID token by signing in with the Firebase client SDK, then call:

```text
POST /auth/firebase-login
{"id_token":"<firebase-id-token>"}
```

Run `python test_firestore_service.py` from this directory to verify live CRUD
operations. The script deletes its test user, patient, score, and consent.

## Local development setup

From the `backend` directory:

### Mac/Linux

```bash
./scripts/setup.sh
./scripts/run_dev.sh
```

Or use the Makefile:

```bash
make setup
make run
make test
make clean
```

### Windows

```bat
scripts\setup.bat
scripts\run_dev.bat
```

If package imports are corrupted, repair the selected virtual environment with:

```bat
scripts\fix_install.bat
```

The setup scripts create `venv`, install `requirements.txt`, and create `.env`
from `.env.example` only when `.env` does not already exist. The development
server is available at `http://127.0.0.1:8000`, with API documentation at
`http://127.0.0.1:8000/docs`.

From PowerShell, run the API from the backend directory with the repaired
Python environment:

```powershell
cd C:\Users\rocky\OneDrive\Desktop\SIMRITI-AI\backend
.\venv312\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Do not run `uvicorn app.main:app` from the project root. The `app` package is
inside `backend`, and the root interpreter may not have the backend packages.
