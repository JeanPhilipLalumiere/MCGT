#!/usr/bin/env bash
set -euo pipefail
[ -f .github/workflows/sanity.yml ] || { echo "❌ sanity.yml absent"; exit 1; }

python - <<'PY'
import yaml, pathlib

p = pathlib.Path(".github/workflows/sanity.yml")
data = yaml.safe_load(p.read_text(encoding="utf-8"))

# 1) Ensure workflow_dispatch
on = data.get("on", {})
if isinstance(on, dict):
    on.setdefault("workflow_dispatch", None)
else:
    on = {"push": None, "pull_request": None, "workflow_dispatch": None}
data["on"] = on

# 2) Ensure steps array
steps = data.setdefault("jobs", {}).setdefault("sanity", {}).setdefault("steps", [])

# 3) Replace/insert verbose diag step
diag_idx = None
for i, s in enumerate(steps):
    if isinstance(s, dict) and s.get("name") == "Manifests strict diag":
        diag_idx = i; break

diag_step = {
  "name": "Manifests strict diag",
  "shell": "bash",
  "run": r"""set +e
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal \
  --content-check --fail-on errors > diag.json 2> diag.err
ec=$?
set -e

echo '--- diag summary ---'
python - <<'PY2' || true
import json, sys
try:
    d=json.load(open('diag.json'))
except Exception as e:
    print('! cannot parse diag.json:', e)
    try:
        print('stderr:'); print(open('diag.err','r',errors='ignore').read())
    except: pass
    sys.exit(0)
errs=d.get('errors',0); print('ERRORS:', errs)
for it in d.get('issues',[]):
    if it.get('severity')=='ERROR':
        print(f"{it.get('code','?')}\t{it.get('path','?')}\t{it.get('message','')}")
PY2

if [ $ec -ne 0 ]; then
  echo "::error title=diag_consistency failed::See the diag summary above"
  exit $ec
fi
"""
}

if diag_idx is None:
    steps.append(diag_step)
else:
    steps[diag_idx] = diag_step

# 4) Upload artifacts (always)
upload = {
  "name": "Upload diag artifacts",
  "if": "always()",
  "uses": "actions/upload-artifact@v4",
  "with": {
    "name": "sanity-diag",
    "path": |
      diag.json
      diag.err
    ,
    "if-no-files-found": "warn",
    "retention-days": 7
  }
}

# insérer juste après l’étape diag
insert_at = (diag_idx if diag_idx is not None else len(steps)) + 1
steps.insert(insert_at, upload)

# 5) Optionnel: imprimer l’arbo pour debug
steps.insert(insert_at, {
  "name": "Workspace tree (for debug)",
  "if": "always()",
  "run": "pwd && ls -la && git status || true"
})

p.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")
print("OK: sanity.yml updated")
PY

# valider YAML si pre-commit est dispo
pre-commit run check-yaml --files .github/workflows/sanity.yml || true

git add .github/workflows/sanity.yml
git commit -m "ci(sanity): upload diag artifacts + verbose summary + workflow_dispatch" || true
git push
echo "✅ Workflow patché & poussé."
