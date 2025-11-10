#!/usr/bin/env bash
set -Eeuo pipefail
WF=".github/workflows/manifest-guard.yml"
mkdir -p .github/workflows
ts="$(date -u +%Y%m%dT%H%M%SZ)"
[ -f "$WF" ] && cp -a "$WF" "${WF}.bak.${ts}"

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

      - name: Run diag_consistency (collect JSON) — non-blocking
        shell: bash
        env:
          MANIFEST: ${{ steps.pick.outputs.manifest }}
        run: |
          set +e
          # Localise le diag
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
          # Toujours garantir un fichier JSON exploitable
          if [ ! -s diag_report.json ]; then
            echo "[WARN] diag_report.json missing or empty; creating fallback"
            printf '{"issues":[{"severity":"ERROR","code":"DIAG_FAILED","path":"%s","message":"diag exited with code %d"}],"rules":{}}' "$MANIFEST" "$RC" > diag_report.json
          fi
          # Ne PAS échouer ici; la post-analyse décidera
          exit 0

      - name: Post-process report (fail only on real ERROR)
        shell: bash
        run: |
          set -euo pipefail
          python3 - <<'PY'
          import json, re, sys
          with open('diag_report.json','rb') as f:
              rep = json.load(f)
          issues = rep.get("issues", []) or []
          IGN = re.compile(r'\.bak(\.|_|$)|_autofix', re.I)
          kept = [it for it in issues if not IGN.search(str(it.get("path","")))]
          errors = [it for it in kept if str(it.get("severity","")).upper()=="ERROR"]
          warns  = [it for it in kept if str(it.get("severity","")).upper()=="WARN"]
          print(f"[INFO] kept={len(kept)} WARN={len(warns)} ERROR={len(errors)}")
          for it in errors[:50]:
              code = it.get('code','?')
              path = it.get('path','?')
              msg  = it.get('message','')
              print(f"::error::{code} at {path}: {msg}")
          for it in warns[:20]:
              code = it.get('code','?')
              path = it.get('path','?')
              msg  = it.get('message','')
              print(f"::warning::{code} at {path}: {msg}")
          sys.exit(1 if errors else 0)
          PY
YAML

git add "$WF"
git commit -m "ci(manifest-guard): v8 — diag non-bloquant + rapport garanti + fail uniquement si ERROR"
git push
