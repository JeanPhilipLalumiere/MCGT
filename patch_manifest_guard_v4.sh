#!/usr/bin/env bash
set -Eeuo pipefail
ts="$(date -u +%Y%m%dT%H%M%SZ)"
WF=".github/workflows/manifest-guard.yml"
cp -a "$WF" "${WF}.bak.${ts}"

cat > "$WF" <<'YAML'
name: manifest-guard
on:
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch: {}
permissions:
  contents: read
concurrency:
  group: manifest-guard-${{ github.ref }}
  cancel-in-progress: true

jobs:
  guard:
    name: guard
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Locate manifest
        id: pick
        shell: bash
        run: |
          set -euo pipefail
          for M in zz-manifests/manifest_master.json zz-manifests/manifest_publication.json; do
            if [ -f "$M" ]; then
              echo "manifest=$M" >> "$GITHUB_OUTPUT"
              echo "[OK] Found manifest: $M"
              exit 0
            fi
          done
          echo "::error::No manifest found (expected zz-manifests/manifest_master.json or zz-manifests/manifest_publication.json)"
          exit 1

      - name: Validate JSON syntax (stdlib)
        shell: bash
        run: |
          set -euo pipefail
          p="${{ steps.pick.outputs.manifest }}"
          python3 - <<PY
import json,sys,os
p=os.environ["p"]
json.load(open(p,'rb'))
print("[OK] JSON syntax:", p)
PY

      - name: Run diag_consistency if present (fail only on errors)
        shell: bash
        run: |
          set -euo pipefail
          M="${{ steps.pick.outputs.manifest }}"
          # Chercher diag dans 2 emplacements connus
          if   [ -f zz-manifests/diag_consistency.py ]; then D=zz-manifests/diag_consistency.py
          elif [ -f zz-scripts/diag_consistency.py   ]; then D=zz-scripts/diag_consistency.py
          else
            echo "[SKIP] diag_consistency.py not found"
            exit 0
          fi
          echo "[INFO] Using diag: $D"
          set +e
          python3 "$D" "$M" \
            --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on errors
          rc=$?
          set -e
          if [ $rc -ne 0 ]; then
            echo "::error::diag_consistency failed (rc=$rc)."
            exit $rc
          fi
          echo "[OK] diag_consistency completed (fail-on=errors)"
YAML

git add "$WF"
echo
read -rp "Commit & push ce patch ? [y/N] " ans
if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
  git commit -m "ci(manifest-guard): accept publication/master manifest; JSON check; diag fail-on=errors [SAFE ${ts}]" && git push
  echo "[GIT] Pushed."
else
  echo "[SKIP] No commit."
fi
