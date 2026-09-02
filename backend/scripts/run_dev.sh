#!/usr/bin/env bash
set -euo pipefail

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BACKEND_DIR"

VENV_DIR="${VENV_DIR:-venv}"
if [[ -f venv312/bin/activate ]]; then
    VENV_DIR="venv312"
fi

if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
    echo "[run] Virtual environment not found. Run ./scripts/setup.sh first." >&2
    exit 1
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
export PYTHONPATH="$BACKEND_DIR${PYTHONPATH:+:$PYTHONPATH}"
echo "[run] Starting SMRITI-AI API at http://127.0.0.1:8000"
python -m uvicorn app.main:app --reload
