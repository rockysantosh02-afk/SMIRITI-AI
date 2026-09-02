#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
PYTHON="${PYTHON:-python3}"
[[ -x venv312/bin/python ]] && PYTHON=venv312/bin/python
exec "$PYTHON" run_tests.py
