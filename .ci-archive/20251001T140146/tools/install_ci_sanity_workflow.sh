#!/usr/bin/env bash
set -euo pipefail
mkdir -p .github/workflows

cat > .github/workflows/sanity.yml <<'YAML'
name: sanity
on:
  push:
  pull_request:

jobs:
  sanity:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install deps (minimal)
        run: |
          python -m pip install -U pip
          python -m pip install -r requirements-dev.txt || true
          python -m pip install -r requirements-lock.txt || true

      - name: Guard: no .RECIPEPREFIX
        run: |
          bash tools/guard_no_recipeprefix.sh

      - name: Dry-run Make (fix-manifest)
        run: |
          make -n fix-manifest >/dev/null

      - name: Manifests strict diag
        run: |
          python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
            --report json --normalize-paths --apply-aliases --strip-internal \
            --content-check --fail-on errors >/dev/null

      - name: Pytest (quiet)
        run: |
          python -m pytest -q
YAML

git add .github/workflows/sanity.yml
git commit -m "ci: add lightweight sanity workflow (guards + dry-run make + diag + pytest)" || true
git push origin HEAD
echo "✅ sanity.yml installé et poussé."
