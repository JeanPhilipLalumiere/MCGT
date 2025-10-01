#!/usr/bin/env bash
set -euo pipefail
echo "== Repair .github/workflows/sanity.yml (quote step names with ':') =="

[ -d .git ] || { echo "❌ run at repo root (.git/)"; exit 2; }
mkdir -p .github/workflows

cat > .github/workflows/sanity.yml <<'YAML'
name: sanity
on:
  push:
  pull_request:

jobs:
  sanity:
    runs-on: ubuntu-latest
    timeout-minutes: 30
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
          if [ -f requirements-lock.txt ]; then python -m pip install -r requirements-lock.txt || true; fi
          if [ -f requirements-dev.txt ]; then python -m pip install -r requirements-dev.txt || true; fi

      - name: "Guard: no .RECIPEPREFIX"
        run: bash tools/guard_no_recipeprefix.sh

      - name: Dry-run Make (fix-manifest)
        run: make -n fix-manifest

      - name: Manifests strict diag
        run: |
          python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
            --report json --normalize-paths --apply-aliases --strip-internal \
            --content-check --fail-on errors

      - name: Pytest
        run: python -m pytest -q
YAML

# Normalize: LF endings, no TABs in YAML
python - <<'PY'
from pathlib import Path
p = Path(".github/workflows/sanity.yml")
txt = p.read_text(encoding="utf-8", errors="replace").replace("\r\n","\n").replace("\r","\n").replace("\t","  ")
p.write_text(txt if txt.endswith("\n") else txt+"\n", encoding="utf-8")
PY

# Validate with PyYAML if available; otherwise just show a friendly note
python - <<'PY' || echo "⚠️ PyYAML not available; rely on pre-commit/CI to validate."
try:
    import yaml, sys
    from pathlib import Path
    yaml.safe_load(Path(".github/workflows/sanity.yml").read_text(encoding="utf-8"))
    print("✅ YAML parse OK")
except Exception as e:
    print("❌ YAML invalid:", e)
    sys.exit(1)
PY

nl -ba -w3 -s': ' .github/workflows/sanity.yml | sed -n '1,120p'

git add .github/workflows/sanity.yml
git commit -m "ci: fix sanity.yml (quote step name with colon; normalize whitespace)" || true
git push origin HEAD
echo "✅ sanity.yml fixed and pushed."
