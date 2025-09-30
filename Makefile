# --- Minimal MCGT Makefile ---
SHELL := /bin/bash
# .RECIPEPREFIX := >
.DEFAULT_GOAL := help

PY             ?= python3
DIR_SCHEMAS    := zz-schemas
DIR_MANIFESTS  := zz-manifests
MANIFEST_MAIN  := $(DIR_MANIFESTS)/manifest_master.json

.PHONY: help env validate json csv manifestscheck manifests-md build distcheck clean

help:
	# > echo "Targets:"
	# > echo "  env              - show python"
	# > echo "  validate         - json + csv + manifests"
	# > echo "  json             - json validations (delegated to script)"
	# > echo "  csv              - csv validations (delegated to script)"
	# > echo "  manifestscheck   - check main manifest"
	# > echo "  manifests-md     - render manifest report"
	# > echo "  build            - build sdist/wheel"
	# > echo "  distcheck        - twine check dist/*"
	# > echo "  clean            - rm build/dist/egg-info"

env:
	# > $(PY) -V; which $(PY) || true

validate: json csv manifestscheck

json:
	# > ./$(DIR_SCHEMAS)/validate_all.sh

csv:
	# > ./$(DIR_SCHEMAS)/validate_csv_all.sh

manifestscheck:
	# > $(PY) $(DIR_MANIFESTS)/diag_consistency.py $(MANIFEST_MAIN) --report json --fail-on errors > /tmp/diag.json
	# > echo "diag written to /tmp/diag.json"

manifests-md:
	# > $(PY) $(DIR_MANIFESTS)/diag_consistency.py $(MANIFEST_MAIN) --report md --fail-on none > $(DIR_MANIFESTS)/manifest_report.md
	# > echo "wrote $(DIR_MANIFESTS)/manifest_report.md"

build:
	# > $(PY) -m build

distcheck:
	# > twine check dist/*

clean:
	# > rm -rf build dist *.egg-info

# === MCGT: validation targets ===
# .RECIPEPREFIX := >
.PHONY: validate validate-json validate-csv diag

# Pipeline complet
validate: validate-json validate-csv diag

# JSON: suite de validations pilotée par zz-schemas/validate_all.sh
validate-json:
	# > ./zz-schemas/validate_all.sh

# CSV: nos deux tables clés (élargis la liste dans validate_csv_all.sh si besoin)
validate-csv:
	# > ./zz-schemas/validate_csv_all.sh

# Diagnostic de cohérence des manifestes (chemins/sha/tailles)
diag:
	# > python zz-manifests/diag_consistency.py zz-manifests/manifest_publication.json --repo-root . --report json --content-check

# --- Manifests maintenance ---
fix-manifest:
	@python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
	--report json --normalize-paths --apply-aliases --strip-internal \
	--content-check --write-hashes --write-sizes || true
	@echo "Done: fix-manifest (hashes/sizes écrits si applicable)."

fix-manifest-strict:
	@python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
	--report json --normalize-paths --apply-aliases --strip-internal \
	--content-check --fail-on errors
