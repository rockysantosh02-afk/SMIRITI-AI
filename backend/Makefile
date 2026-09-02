.PHONY: setup run test clean

VENV_DIR ?= venv

setup:
	./scripts/setup.sh

run:
	./scripts/run_dev.sh

test:
	$(VENV_DIR)/bin/python -m pytest -q

clean:
	rm -rf venv venv312 .pytest_cache __pycache__
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
