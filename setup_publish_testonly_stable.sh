#!/usr/bin/env bash
# Patch idempotent de .github/workflows/publish_testonly.yml pour:
# - écouter une branche fixe (ci/testpypi-workflow-rmid)
# - ajouter workflow_dispatch
# - relaxer les "if:" pour autoriser dispatch/push
# - supprimer 'run-id:' des steps actions/download-artifact
# - ajouter "paths" (.ci_poke) pour déclencher par push trivial
# La fenêtre NE SE FERME PAS : boucle finale.

set -u -o pipefail  # pas de -e

WF=".github/workflows/publish_testonly.yml"
FIXBR="ci/testpypi-workflow-rmid"

# --- Détection sûre du repo pour gh -R ---
detect_repo() {
  local r url owner repo
  r="$(git remote 2>/dev/null | head -n1 || true)"
  url="$(git remote get-url "${r:-origin}" 2>/dev/null || true)"
  # formats possibles: git@github.com:owner/repo.git  ou https://github.com/owner/repo.git
  if [[ "$url" =~ github.com[:/]+([^/]+)/([^/.]+) ]]; then
    owner="${BASH_REMATCH[1]}"; repo="${BASH_REMATCH[2]}"
    echo "${owner}/${repo}"
  else
    # dernier recours: mets ton repo ici si besoin
    echo "JeanPhilipLalumiere/MCGT"
  fi
}

GH_REPO="$(detect_repo)"

log()  { printf "\n== %s ==\n" "$*"; }
warn() { printf "Avertissement: %s\n" "$*" >&2; }
err()  { printf "ERREUR: %s\n" "$*" >&2; }

final_loop() {
  echo
  echo "==============================================================="
  echo " Patch terminé — la fenêtre RESTE OUVERTE."
  echo "   Entrée : quitter"
  echo "   sh     : shell interactif (exit pour revenir)"
  echo "==============================================================="
  while true; do
    read -r -p "> " ans || true
    if [ "${ans:-}" = "sh" ]; then /bin/bash -i; continue; fi
    [ -z "${ans:-}" ] && break
  done
}

log "Pré-checks"
[ -f "$WF" ] || { err "Workflow introuvable: $WF"; final_loop; exit 0; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { err "Pas un dépôt git."; final_loop; exit 0; }
command -v gh >/dev/null 2>&1 || { err "GitHub CLI (gh) requis."; final_loop; exit 0; }

log "Installer ruamel.yaml (idempotent)"
python - <<'PY' >/dev/null 2>&1 || pip install --quiet 'ruamel.yaml>=0.17'
try:
    import ruamel.yaml  # noqa
except Exception:
    raise SystemExit(1)
PY

log "Appliquer le patch YAML"
python - "$WF" "$FIXBR" <<'PY' || true
import sys, time
from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap as CM, CommentedSeq as CS

wf_path = sys.argv[1]
fix_branch = sys.argv[2]

yaml = YAML()
yaml.preserve_quotes = True
data = yaml.load(open(wf_path, 'r', encoding='utf-8'))

def ensure_dispatch_and_push(d):
    on = d.get('on') or d.get(True)
    if on is None:
        on = CM()
        d['on'] = on
    if 'workflow_dispatch' not in on:
        on['workflow_dispatch'] = CM()
    push = on.get('push')
    if push is None or isinstance(push, str):
        push = CM()
        on['push'] = push
    branches = push.get('branches')
    if branches is None or not isinstance(branches, (list, CS)):
        branches = CS()
        push['branches'] = branches
    if fix_branch not in list(branches):
        branches.append(fix_branch)
    paths = push.get('paths')
    if paths is None or not isinstance(paths, (list, CS)):
        paths = CS()
        push['paths'] = paths
    need = {'.github/workflows/publish_testonly.yml', '.ci_poke'}
    for p in list(need):
        if p not in paths:
            paths.append(p)

def relax_if(expr):
    extra = f"(github.event_name == 'workflow_dispatch') || startsWith(github.ref, 'refs/heads/{fix_branch}')"
    expr = (expr or "").strip()
    if not expr:
        return extra
    if extra in expr:
        return expr
    return f"({expr}) || {extra}"

def cleanup_runid_in_dl(step):
    if isinstance(step, CM) and 'uses' in step:
        u = step['uses']
        if isinstance(u, str) and u.startswith('actions/download-artifact@'):
            if 'with' in step and isinstance(step['with'], CM):
                step['with'].pop('run-id', None)

ensure_dispatch_and_push(data)

jobs = data.get('jobs') or {}
for name, job in list(jobs.items()):
    if isinstance(job, CM):
        job['if'] = relax_if(job.get('if'))
        steps = job.get('steps') or []
        for st in steps:
            if isinstance(st, CM):
                if 'if' in st:
                    st['if'] = relax_if(st.get('if'))
                cleanup_runid_in_dl(st)

data['_ci_touch_comment'] = f"patched {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}"

with open(wf_path, 'w', encoding='utf-8') as f:
    yaml.dump(data, f)
PY

log "Créer .ci_poke si absent"
[ -f .ci_poke ] || echo "poke $(date -u +%FT%TZ)" > .ci_poke

log "Commit & push idempotent"
git add "$WF" .ci_poke >/dev/null 2>&1 || true
if ! git diff --cached --quiet; then
  git commit -m "ci: patch publish_testonly.yml for fixed branch + dispatch + relax if + poke"
  # pousse sur la branche courante (quelle qu'elle soit)
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
else
  echo "Rien à committer."
fi

# Petit check que gh voit bien le workflow dans le bon repo
echo
echo "Sanity check gh:"
gh workflow list -R "$GH_REPO" | sed -n '1,5p' || true

final_loop
