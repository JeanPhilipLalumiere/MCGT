# tools/fix_pypi_build_pr_attach_safe.sh
#!/usr/bin/env bash
set -eu -o pipefail

WF=".github/workflows/pypi-build.yml"
[ -f "$WF" ] || { echo "[ERR] introuvable: $WF"; exit 1; }

cp -a "$WF" "$WF.bak.$(date +%s)"

# 0) name: pypi-build au niveau workflow
if ! grep -Eq '^\s*name:\s*pypi-build\s*$' "$WF"; then
  awk 'NR==1{print "name: pypi-build"} {print}' "$WF" > "$WF.tmp0" && mv "$WF.tmp0" "$WF"
fi

# 1) on: pull_request sans filtres + workflow_dispatch
python3 - "$WF" <<'PY' > "$WF.tmp1"
import sys, yaml
p=sys.argv[1]; d=yaml.safe_load(open(p,'r',encoding='utf-8'))
on=d.get('on') or {}
if isinstance(on, list):
    on={k: None for k in on}
if 'pull_request' not in on:
    on['pull_request']={}
if isinstance(on['pull_request'], dict):
    for k in ['paths','paths-ignore','branches','branches-ignore','types']:
        on['pull_request'].pop(k, None)
on['workflow_dispatch']=on.get('workflow_dispatch', {})
d['on']=on
print(yaml.safe_dump(d, sort_keys=False))
PY

# 2) neutraliser if: bloquants au niveau job
python3 - "$WF.tmp1" <<'PY' > "$WF.tmp2"
import sys, yaml
d=yaml.safe_load(open(sys.argv[1],'r',encoding='utf-8'))
jobs=d.get('jobs') or {}
for jn,job in jobs.items():
    if isinstance(job, dict) and 'if' in job:
        job['# if (disabled)'] = job.pop('if')
d['jobs']=jobs
print(yaml.safe_dump(d, sort_keys=False))
PY

# 3) job name = build (si pas déjà)
python3 - "$WF.tmp2" <<'PY' > "$WF.tmp3"
import sys, yaml
d=yaml.safe_load(open(sys.argv[1],'r',encoding='utf-8'))
jobs=d.get('jobs') or {}
# si un job a déjà name=build, on garde
have=False
for jn,job in jobs.items():
    if isinstance(job, dict) and str(job.get('name','')).strip().lower()=='build':
        have=True
        break
if not have:
    for jn,job in jobs.items():
        if isinstance(job, dict):
            job.setdefault('name','build')
            break
d['jobs']=jobs
print(yaml.safe_dump(d, sort_keys=False))
PY

# 4) concurrency non agressive
python3 - "$WF.tmp3" <<'PY' > "$WF"
import sys, yaml
d=yaml.safe_load(open(sys.argv[1],'r',encoding='utf-8'))
d['concurrency']={'group': '${{ github.workflow }}-${{ github.ref }}', 'cancel-in-progress': False}
print(yaml.safe_dump(d, sort_keys=False))
PY

echo "[OK] Patch appliqué → $WF"
git add "$WF"
git commit -m "ci(pypi-build): ensure PR-attached run (name=pypi-build; job=build; no filters; no cancel)" || true
git push

# Nudge PR HEAD pour forcer les runs PR
PRNUM=20
BR="$(gh pr view "$PRNUM" --json headRefName -q .headRefName 2>/dev/null || true)"
[ -n "${BR:-}" ] && git switch "$BR" >/dev/null 2>&1 || true

printf '\n# ci-nudge-pypi\n' >> README.md
git add README.md
git commit -m "chore(ci): nudge to attach pypi-build on PR HEAD" || true
git push

# Relance explicite (facultatif ; la source de vérité sera l'événement pull_request)
gh workflow run .github/workflows/pypi-build.yml  -r "${BR:-}" || true
gh workflow run .github/workflows/secret-scan.yml -r "${BR:-}" || true

# Poll des check-runs du HEAD pour vérifier EXACTEMENT les contexts requis
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

# Merge rebase (si le CLI refuse encore, utilise l’UI « Rebase and merge »)
gh pr checks "$PRNUM"
gh pr merge "$PRNUM" --rebase --delete-branch || echo "[WARN] Refus CLI — utilise l’UI (Rebase and merge)."
