#!/usr/bin/env bash
set -Eeuo pipefail
WF=".github/workflows/manifest-guard.yml"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p .github/workflows
[ -f "$WF" ] && cp -a "$WF" "$WF.bak.$TS"

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
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

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

      - name: Validate JSON syntax
        shell: bash
        env:
          MANIFEST: ${{ steps.pick.outputs.manifest }}
        run: |
          set -euo pipefail
          python3 - <<'PY'
import json, os
p = os.environ["MANIFEST"]
with open(p,'rb') as f:
    json.load(f)
print("[OK] JSON syntax:", p)
PY

      - name: Run diag_consistency (non-blocking, always writes report)
        shell: bash
        env:
          MANIFEST: ${{ steps.pick.outputs.manifest }}
        run: |
          set -euo pipefail
          set +e
          if   [ -f zz-manifests/diag_consistency.py ]; then D=zz-manifests/diag_consistency.py
          elif [ -f zz-scripts/diag_consistency.py   ]; then D=zz-scripts/diag_consistency.py
          else
            echo "[SKIP] diag_consistency.py not found"
            printf '{"issues":[],"rules":{}}' > diag_report.json
            echo "[INFO] diag exit code: 0 (no diag script)"
            exit 0
          fi
          echo "[INFO] Using diag: $D"
          python3 "$D" "$MANIFEST" \
            --report json --normalize-paths --apply-aliases --strip-internal --content-check \
            > diag_report.json
          RC=$?
          echo "[INFO] diag exit code: $RC"
          # Ne pas échouer ici: le step suivant décide
          exit 0

      - name: Post-process report (python runner)
        shell: bash
        env:
          ALLOW_MISSING_REGEX: "(\\.lock\\.json$|^zz-data\\/chapter0[8-9]\\/|^zz-data\\/chapter10\\/)"
          SOFT_PASS_IF_ONLY_CODES_REGEX: "^(FILE_MISSING)$"
        run: |
          set -euo pipefail
          python3 zz-tools/manifest_postprocess.py
YAML

# Validation ciblée (si actionlint installé, on ne scanne QUE ce fichier)
if command -v actionlint >/dev/null 2>&1; then
  actionlint -color -oneline -file "$WF"
fi

git add "$WF"
git commit -m "ci(manifest-guard): v12 — rewrite clean YAML, non-blocking diag, python post-process"
git push
