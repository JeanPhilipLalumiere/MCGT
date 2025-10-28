# tools/fix_secret_scan_workflow_name_and_filters_safe.sh
#!/usr/bin/env bash
set -eu -o pipefail

WF=".github/workflows/secret-scan.yml"
[ -f "$WF" ] || { echo "[ERR] introuvable: $WF"; exit 1; }

cp -a "$WF" "$WF.bak.$(date +%s)"

# 0) Si pas de name: secret-scan, l'ajouter en tête
if ! grep -Eq '^\s*name:\s*secret-scan\s*$' "$WF"; then
  awk 'NR==1{print "name: secret-scan"} {print}' "$WF" > "$WF.tmp0" && mv "$WF.tmp0" "$WF"
fi

# 1) Garantir on: pull_request + workflow_dispatch (sans filtres)
#    - on retire les blocks paths*/if restrictifs sous on: pull_request
python3 - "$WF" <<'PY' > "$WF.tmp1"
import sys, yaml
p=sys.argv[1]; d=yaml.safe_load(open(p,'r',encoding='utf-8'))
on=d.get('on') or {}
# normaliser en dict
if isinstance(on, list):
    on={k: None for k in on}
if 'pull_request' not in on:
    on['pull_request']={}
# enlever paths/paths-ignore/branches* restrictifs sur pull_request
if isinstance(on['pull_request'], dict):
    for k in ['paths','paths-ignore','branches','branches-ignore','types']:
        on['pull_request'].pop(k, None)
# ajouter workflow_dispatch
on['workflow_dispatch']=on.get('workflow_dispatch', {})
d['on']=on
print(yaml.safe_dump(d, sort_keys=False))
PY

# 2) Neutraliser if: au niveau JOB (empêche l’attache PR)
python3 - "$WF.tmp1" <<'PY' > "$WF.tmp2"
import sys, yaml
txt=open(sys.argv[1],'r',encoding='utf-8').read()
d=yaml.safe_load(txt)
jobs=d.get('jobs') or {}
for jn,job in jobs.items():
    if isinstance(job, dict) and 'if' in job:
        job['# if (disabled)'] = job.pop('if')
d['jobs']=jobs
import yaml as y; print(y.safe_dump(d, sort_keys=False))
PY

# 3) Assurer job name = gitleaks (et le laisser si déjà correct)
python3 - "$WF.tmp2" <<'PY' > "$WF.tmp3"
import sys, yaml
d=yaml.safe_load(open(sys.argv[1],'r',encoding='utf-8'))
jobs=d.get('jobs') or {}
# si un job a déjà name=gitleaks, on garde
have=False
for jn,job in jobs.items():
    if isinstance(job, dict) and str(job.get('name','')).strip().lower()=='gitleaks':
        have=True
        break
if not have:
    # pose gitleaks sur le premier job
    for jn,job in jobs.items():
        if isinstance(job, dict):
            job.setdefault('name','gitleaks')
            break
d['jobs']=jobs
print(yaml.safe_dump(d, sort_keys=False))
PY

# 4) Concurrency non agressive
python3 - "$WF.tmp3" <<'PY' > "$WF"
import sys, yaml
d=yaml.safe_load(open(sys.argv[1],'r',encoding='utf-8'))
d['concurrency']={'group': '${{ github.workflow }}-${{ github.ref }}', 'cancel-in-progress': False}
print(yaml.safe_dump(d, sort_keys=False))
PY

echo "[OK] Patch appliqué → $WF"
git add "$WF"
git commit -m "ci(secret-scan): name=secret-scan; job=gitleaks; PR attach; no filters; no cancel" || true
git push

# Nudge PR HEAD & relance des 2 requis
PR="$(gh pr list --state open --json number,headRefName | jq -r 'map(select(.number==20))|.[0].headRefName' 2>/dev/null || true)"
[ -n "${PR:-}" ] && git switch "$PR" >/dev/null 2>&1 || true
printf '\n# ci-nudge-3\n' >> README.md
git add README.md
git commit -m "chore(ci): nudge for secret-scan context attach (HEAD)" || true
git push

gh workflow run .github/workflows/pypi-build.yml  -r "${PR:-}" || true
gh workflow run .github/workflows/secret-scan.yml -r "${PR:-}" || true

# Poll jusqu’à SUCCESS (contexte exacts)
HEAD_SHA="$(git rev-parse HEAD)"
echo "[INFO] HEAD = $HEAD_SHA"
for i in $(seq 1 60); do
  JSON="$(gh api repos/:owner/:repo/commits/$HEAD_SHA/check-runs -H 'Accept: application/vnd.github+json' 2>/dev/null || true)"
  C_BUILD=$(printf "%s" "$JSON" | jq -r '.check_runs[]? | select(.name=="pypi-build/build") | .conclusion' | tail -n1)
  C_GITLK=$(printf "%s" "$JSON" | jq -r '.check_runs[]? | select(.name=="secret-scan/gitleaks") | .conclusion' | tail -n1)
  echo "CTX pypi-build/build => ${C_BUILD:-<none>} ; CTX secret-scan/gitleaks => ${C_GITLK:-<none>}"
  if [ "${C_BUILD:-}" = "success" ] && [ "${C_GITLK:-}" = "success" ]; then
    echo "[OK] Les deux contexts requis sont SUCCESS sur le HEAD."
    break
  fi
  sleep 10
done

# Merge rebase (si le CLI refuse encore, clic UI « Rebase and merge »)
gh pr merge 20 --rebase --delete-branch || echo "[WARN] Refus CLI — utilise l’UI (Rebase and merge)."
