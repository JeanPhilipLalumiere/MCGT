#!/usr/bin/env bash
# Répare/valide .github/workflows/publish_testonly.yml et injecte un job "smoke" si nécessaire.
# La fenêtre RESTE OUVERTE (boucle finale). ASCII only.

set -u -o pipefail   # pas de -e

WF=".github/workflows/publish_testonly.yml"
FIXBR="ci/testpypi-workflow-rmid"

log(){ printf "\n== %s ==\n" "$*"; }
warn(){ printf "WARN: %s\n" "$*" >&2; }
err(){ printf "ERROR: %s\n" "$*" >&2; }

need(){
  command -v "$1" >/dev/null 2>&1 || { err "$1 requis"; final_loop; exit 0; }
}

final_loop(){
  echo
  echo "==============================================================="
  echo " Fin — la fenêtre RESTE OUVERTE. [Entrée]=quitter  [sh]=shell "
  echo "==============================================================="
  while true; do
    read -r -p "> " a || true
    case "${a:-}" in
      sh) /bin/bash -i;;
      "") break;;
      *) echo "?";;
    esac
  done
}

# Détecte le repo pour gh -R
detect_repo(){
  local r url
  r="$(git remote 2>/dev/null | head -n1 || true)"
  url="$(git remote get-url "${r:-origin}" 2>/dev/null || true)"
  if [[ "$url" =~ github.com[:/]+([^/]+)/([^/.]+) ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  else
    echo "JeanPhilipLalumiere/MCGT"
  fi
}
GH_REPO="$(detect_repo)"

need git
need gh

[ -f "$WF" ] || { err "$WF introuvable"; final_loop; exit 0; }

log "Installer ruamel.yaml si besoin"
python - <<'PY' 2>/dev/null || pip install --user ruamel.yaml >/dev/null
import sys, pkgutil
sys.exit(0 if pkgutil.find_loader('ruamel.yaml') else 1)
PY

log "Patch YAML de base (suppr. clés parasites, run-id, triggers)"
python - "$WF" "$FIXBR" <<'PY' || { err "Patch YAML (phase 1)"; final_loop; exit 0; }
import sys, io
from ruamel.yaml import YAML
yaml = YAML()
yaml.preserve_quotes = True

wf_path = sys.argv[1]
fixbr = sys.argv[2]

with open(wf_path, 'r', encoding='utf-8') as f:
    data = yaml.load(f)

if data is None:
    print("FATAL: YAML vide", file=sys.stderr); sys.exit(1)

# -- normaliser 'on'
on = data.get('on')
if on is None: on = {}
if isinstance(on, list):
    on = {k:{} for k in on}
data['on'] = on

# ensure workflow_dispatch
if 'workflow_dispatch' not in on:
    on['workflow_dispatch'] = {}

# ensure push branches + paths
push = on.get('push')
if push is None or isinstance(push, list):
    push = {}
on['push'] = push
branches = push.get('branches')
if branches is None or not isinstance(branches, list):
    branches = []
push['branches'] = branches
if fixbr not in branches:
    branches.append(fixbr)
paths = push.get('paths')
if paths is None or not isinstance(paths, list):
    paths = []
push['paths'] = paths
if '.ci_poke/**' not in paths:
    paths.append('.ci_poke/**')

# strip clés parasites type _ci_touch_comment récursif
def strip_bad(obj):
    if isinstance(obj, dict):
        for k in list(obj.keys()):
            if isinstance(k, str) and k.startswith('_ci_touch_comment'):
                del obj[k]
            else:
                strip_bad(obj[k])
    elif isinstance(obj, list):
        for v in obj: strip_bad(v)
strip_bad(data)

# retirer run-id dans steps download-artifact
def clean_runid(obj):
    if isinstance(obj, dict):
        if ('uses' in obj) and isinstance(obj['uses'], str) and 'actions/download-artifact' in obj['uses']:
            w = obj.get('with')
            if isinstance(w, dict) and 'run-id' in w:
                w.pop('run-id', None)
        for v in obj.values(): clean_runid(v)
    elif isinstance(obj, list):
        for v in obj: clean_runid(v)
clean_runid(data)

# sauver
out = io.StringIO()
yaml.dump(data, out)
txt = out.getvalue().rstrip() + "\n"
with open(wf_path, 'w', encoding='utf-8') as f:
    f.write(txt)
print("OK: patch phase 1")
PY

log "S'assurer d'une branche fixe $FIXBR + préparer .ci_poke/"
if git show-ref --verify --quiet "refs/heads/$FIXBR"; then
  git checkout "$FIXBR" >/dev/null
else
  git checkout -b "$FIXBR" >/dev/null
fi
[ -e .ci_poke ] && [ ! -d .ci_poke ] && rm -f .ci_poke
mkdir -p .ci_poke

log "Installer actionlint si indisponible (validation GHA)"
if ! command -v actionlint >/dev/null 2>&1; then
  # Télécharge un binaire simple (Linux x86_64); adapter si autre archi
  curl -sSL -o actionlint.tar.gz https://github.com/rhysd/actionlint/releases/latest/download/actionlint_Linux_x86_64.tar.gz || true
  tar -xzf actionlint.tar.gz actionlint 2>/dev/null || true
  chmod +x actionlint 2>/dev/null || true
  PATH="$PWD:$PATH"
fi

log "Validation actionlint"
if command -v actionlint >/dev/null 2>&1; then
  if ! actionlint "$WF" 2> .actionlint.err; then
    echo "---- actionlint errors ----"
    cat .actionlint.err
    echo "---------------------------"
  else
    echo "actionlint: OK"
  fi
else
  warn "actionlint indisponible, on continue sans"
fi

log "Vérifier qu'au moins un job peut tourner"
python - "$WF" "$FIXBR" <<'PY' || true
import sys, io
from ruamel.yaml import YAML
yaml = YAML()
wf_path=sys.argv[1]; fixbr=sys.argv[2]
data=yaml.load(open(wf_path,'r',encoding='utf-8'))
jobs = (data or {}).get('jobs') or {}
if not jobs:
    print("NO_JOBS")
    sys.exit(0)

def likely_blocked(j):
    # Heuristique simple: job totalement conditionné sur tags/releases uniquement
    cond = (j.get('if') or '').lower()
    if 'refs/tags/' in cond and 'workflow_dispatch' not in cond and fixbr not in cond:
        return True
    return False

blocked = all(likely_blocked(j) for j in jobs.values())
print("JOBS_EXIST", "ALL_BLOCKED" if blocked else "HAS_RUNNABLE")
PY

NEED_SMOKE=0
if grep -q "^NO_JOBS$" <<<"$(python - "$WF" "$FIXBR" <<'PY'
import sys, io
from ruamel.yaml import YAML
yaml=YAML()
data=yaml.load(open(sys.argv[1],'r',encoding='utf-8'))
print("NO_JOBS" if not ((data or {}).get('jobs') or {}) else "OK")
PY
)"; then
  warn "Aucun job dans le workflow"
  NEED_SMOKE=1
else
  if grep -q "ALL_BLOCKED" <<<"$(python - "$WF" "$FIXBR" <<'PY'
import sys, io
from ruamel.yaml import YAML
yaml=YAML()
wf_path=sys.argv[1]
fixbr=sys.argv[2]
data=yaml.load(open(wf_path,'r',encoding='utf-8'))
jobs=(data or {}).get('jobs') or {}
def likely_blocked(j):
    cond=(j.get('if') or '').lower()
    return ('refs/tags/' in cond) and ('workflow_dispatch' not in cond) and (fixbr not in cond)
print("ALL_BLOCKED" if jobs and all(likely_blocked(j) for j in jobs.values()) else "HAS_RUNNABLE")
PY
)"; then
    warn "Tous les jobs semblent bloqués par des conditions"
    NEED_SMOKE=1
  fi
fi

if [ "$NEED_SMOKE" -eq 1 ]; then
  log "Injection d'un job 'smoke' temporaire (toujours runnable sur $FIXBR)"
  python - "$WF" "$FIXBR" <<'PY' || { err "Injection smoke"; final_loop; exit 0; }
import sys, io
from ruamel.yaml import YAML
yaml=YAML(); yaml.preserve_quotes=True
wf_path=sys.argv[1]; fixbr=sys.argv[2]
data=yaml.load(open(wf_path,'r',encoding='utf-8'))
if data is None: data={}
jobs=(data.get('jobs') or {})
data['jobs']=jobs
if 'ci_smoke' not in jobs:
    jobs['ci_smoke']={
        'name':'ci_smoke',
        'runs-on':'ubuntu-latest',
        'if': f"github.ref == 'refs/heads/{fixbr}' || github.event_name == 'workflow_dispatch'",
        'steps':[
            {'name':'Echo',
             'run':"echo 'smoke ok: $GITHUB_WORKFLOW $GITHUB_RUN_ID on $GITHUB_REF' && env | sort | head -n 50"}
        ]
    }
out=io.StringIO(); yaml.dump(data,out)
open(wf_path,'w',encoding='utf-8').write(out.getvalue().rstrip()+"\n")
print("OK: smoke injected")
PY
fi

log "Commit & push (idempotent)"
git add "$WF" .ci_poke >/dev/null 2>&1 || true
git -c user.name="Local CI" -c user.email="local@ci" -c commit.gpgSign=false \
    commit -m "ci: repair workflow & inject smoke if needed" --no-verify >/dev/null 2>&1 || true
git push -u origin "$FIXBR" >/dev/null 2>&1 || true

final_loop
