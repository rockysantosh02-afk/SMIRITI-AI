#!/usr/bin/env bash
set -euo pipefail

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BACKEND_DIR"

PYTHON_BIN="${PYTHON_BIN:-python3}"
VENV_DIR="${VENV_DIR:-venv}"
echo "[setup] Using Python: $PYTHON_BIN"
"$PYTHON_BIN" -m venv "$VENV_DIR"

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
echo "[setup] Installing backend dependencies..."
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

if [[ ! -f .env ]]; then
    cp .env.example .env
    echo "[setup] Created .env from .env.example. Fill in local values before using Firebase."
else
    echo "[setup] Existing .env preserved."
fi

echo "[setup] Setup complete. Activate with: source venv/bin/activate"
echo "[setup] Start the API with: ./scripts/run_dev.sh"
