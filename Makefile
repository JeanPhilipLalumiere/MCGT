.PHONY: deps deps-dev deps-gw deps-ml check-imports build dist check twine-check clean

VENV ?= .venv
PY ?= python3

deps:
	$(PY) -m pip install -U pip build wheel
	$(PY) -m pip install -r requirements.generated.txt

deps-dev: deps
	$(PY) -m pip install -r requirements-dev.generated.txt

deps-gw:
	$(PY) -m pip install -r requirements.gw.txt || true

deps-ml:
	$(PY) -m pip install -r requirements.ml.txt || true

check-imports:
	$(PY) tools/check_imports.py

build:
	$(PY) -m build

dist: clean build check twine-check

check:
	$(PY) -m pytest -q || true

twine-check:
	$(PY) -m pip install -U twine
	twine check dist/*

clean:
	rm -rf build/ dist/ *.egg-info
