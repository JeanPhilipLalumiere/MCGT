#!/usr/bin/env bash
set -euo pipefail
[ -f .github/workflows/sanity.yml ] || { echo "❌ sanity.yml absent"; exit 1; }

tmp="$(mktemp)"
python - <<'PY'
import io, sys, yaml, pathlib
p = pathlib.Path(".github/workflows/sanity.yml")
data = yaml.safe_load(p.read_text(encoding="utf-8"))

# Ensure workflow_dispatch trigger
on = data.get("on", {})
if isinstance(on, dict):
    on.setdefault("workflow_dispatch", None)
else:
    on = {"push": None, "pull_request": None, "workflow_dispatch": None}
data["on"] = on

steps = data.setdefault("jobs", {}).setdefault("sanity", {}).setdefault("steps", [])

# Find step "Manifests strict diag" and replace its run
idx = None
for i, s in enumerate(steps):
    if isinstance(s, dict) and s.get("name") == "Manifests strict diag":
        idx = i; break

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
    print('stderr:')
    print(open('diag.err','r',errors='ignore').read())
    sys.exit(0)
errs=d.get('errors',0)
print('ERRORS:', errs)
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

if idx is None:
    steps.append(diag_step)
else:
    steps[idx] = diag_step

# Serialize without tabs
p.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")
print("OK: workflow updated")
PY

# Valide YAML via pre-commit si dispo
pre-commit run check-yaml --files .github/workflows/sanity.yml || true

git add .github/workflows/sanity.yml
git commit -m "ci(sanity): verbose diag + workflow_dispatch trigger" || true
git push
echo "✅ sanity.yml patché et poussé."
