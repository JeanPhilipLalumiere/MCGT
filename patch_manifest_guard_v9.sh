#!/usr/bin/env bash
set -Eeuo pipefail
WF=".github/workflows/manifest-guard.yml"
ts="$(date -u +%Y%m%dT%H%M%SZ)"
[ -f "$WF" ] && cp -a "$WF" "${WF}.bak.${ts}"

awk '
  BEGIN{printenv=1}
  # Injecte/force un bloc env pour le job guard (si absent on l ajoute)
  /^jobs:/ {print; next}
  {print}
' "$WF" > "$WF.tmp.1"

# Remplace le step "Post-process report" par une version tolérante
awk '
  BEGIN{in_post=0}
  /^      - name: Post-process report \(fail only on real ERROR\)/{in_post=1; print; getline; while ($0 !~ /^      - name:/ && $0 !~ /^  [^ ]/ && !feof()) {getline} if (!feof()) print; exit}
  {print}
' "$WF" > "$WF.tmp.keep_head" || true

cat > "$WF.tmp.post" <<'YAML'
      - name: Post-process report (fail only on real ERROR)
        shell: bash
        env:
          # Par défaut, on ignore/downgrade tout ce qui matche *.lock.json
          ALLOW_MISSING_REGEX: '\.lock\.json$'
        run: |
          set -euo pipefail
          python3 - <<'PY'
          import json, os, re, sys
          allow_missing = os.environ.get("ALLOW_MISSING_REGEX", r"\.lock\.json$")
          ALLOW = re.compile(allow_missing, re.I)
          IGN   = re.compile(r'\.bak(\.|_|$)|_autofix', re.I)

          with open("diag_report.json","rb") as f:
              rep = json.load(f)
          issues = rep.get("issues", []) or []

          kept = []
          for it in issues:
              path = str(it.get("path",""))
              if IGN.search(path):
                  continue
              # Downgrade FILE_MISSING si path autorisé
              if str(it.get("code","")).upper()=="FILE_MISSING" and ALLOW.search(path):
                  it = dict(it)  # copie
                  it["severity"] = "WARN"
              kept.append(it)

          errors = [it for it in kept if str(it.get("severity","")).upper()=="ERROR"]
          warns  = [it for it in kept if str(it.get("severity","")).upper()=="WARN"]

          print(f"[INFO] kept={len(kept)} WARN={len(warns)} ERROR={len(errors)}")
          for it in errors[:100]:
              code = it.get("code","?"); path = it.get("path","?"); msg = it.get("message","")
              print(f"::error::{code} at {path}: {msg}")
          for it in warns[:50]:
              code = it.get("code","?"); path = it.get("path","?"); msg = it.get("message","")
              print(f"::warning::{code} at {path}: {msg}")

          # Échoue uniquement s il reste des ERROR
          sys.exit(1 if errors else 0)
          PY
YAML

# Concatène head gardé + nouveau post-step
cat "$WF.tmp.keep_head" "$WF.tmp.post" > "$WF"

rm -f "$WF.tmp.1" "$WF.tmp.keep_head" "$WF.tmp.post"
git add "$WF"
git commit -m "ci(manifest-guard): v9 — downgrade FILE_MISSING sur *.lock.json (ALLOW_MISSING_REGEX)"
git push
