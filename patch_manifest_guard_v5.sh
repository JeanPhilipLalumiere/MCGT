#!/usr/bin/env bash
set -Eeuo pipefail
ts="$(date -u +%Y%m%dT%H%M%SZ)"
WF=".github/workflows/manifest-guard.yml"
mkdir -p .github/workflows
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
          python3 - <<'PY'
import json, os
p=os.environ["p"]
json.load(open(p,'rb'))
print("[OK] JSON syntax:", p)
PY

      - name: Run diag_consistency and pass on warnings
        shell: bash
        run: |
          set -euo pipefail
          M="${{ steps.pick.outputs.manifest }}"
          # Locate diag script
          if   [ -f zz-manifests/diag_consistency.py ]; then D=zz-manifests/diag_consistency.py
          elif [ -f zz-scripts/diag_consistency.py   ]; then D=zz-scripts/diag_consistency.py
          else
            echo "[SKIP] diag_consistency.py not found"
            exit 0
          fi
          echo "[INFO] Using diag: $D"

          # Run diag WITHOUT --fail-on, capture JSON report
          python3 "$D" "$M" \
            --report json --normalize-paths --apply-aliases --strip-internal --content-check \
            > diag_report.json

          # Post-process: ignore *bak* and *_autofix* noise, fail only if ERROR remains
          python3 - <<'PY'
import json, re, sys
with open('diag_report.json','rb') as f:
    rep=json.load(f)
issues=rep.get("issues", [])
IGN=re.compile(r'\.bak(\.|_|$)|_autofix', re.I)
kept=[it for it in issues if not IGN.search(it.get("path",""))]
errors=[it for it in kept if it.get("severity","").upper()=="ERROR"]
warns =[it for it in kept if it.get("severity","").upper()=="WARN"]
print(f"[INFO] issues kept: {len(kept)}, WARN={len(warns)}, ERROR={len(errors)}")
if errors:
    print("::error::diag_consistency reported ERRORs after filtering *.bak/_autofix")
    # Print a compact list of first 20 errors
    for it in errors[:20]:
        print(f"::error::{it.get('code','?')} at {it.get('path','?')}: {it.get('message','')}")
    sys.exit(1)
else:
    if warns:
        print("::warning::diag_consistency had warnings (ignored).")
    else:
        print("[OK] no issues after filtering.")
PY
YAML

git add "$WF"
echo
read -rp "Commit & push manifest-guard v5 ? [y/N] " ans
if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
  git commit -m "ci(manifest-guard): robust v5 — JSON check, diag report parse, ignore *.bak/_autofix, fail only on ERROR [SAFE $ts]" && git push
  echo "[GIT] Pushed."
else
  echo "[SKIP] No commit."
fi
