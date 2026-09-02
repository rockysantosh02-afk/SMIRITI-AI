#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python -m pip install -r requirements.txt
python -m pip install flake8 black isort mypy
black --check app core_logic tests
isort --check-only app core_logic tests
flake8 app core_logic tests
mypy core_logic
python run_tests.py
