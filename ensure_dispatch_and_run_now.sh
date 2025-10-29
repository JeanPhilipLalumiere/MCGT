#!/usr/bin/env bash
# ensure_dispatch_and_run_now.sh — vérifie/assure workflow_dispatch sur main, déclenche et poll
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _logs _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/ci_dispatch_${TS}.log"
say(){ echo -e "$*"; echo -e "$*" >>"$LOG"; }
guard(){ read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true; }
trap guard EXIT

# 0) Contexte
say "[CTX] Repo: $(gh repo view --json nameWithOwner -q .nameWithOwner) | branch main"

# 1) Vérifie la protection stricte (lecture seule)
PROT_JSON="$(gh api repos/:owner/:repo/branches/main/protection 2>/dev/null || true)"
echo "$PROT_JSON" | jq '{strict:(.required_status_checks?.strict//false),
                        checks:((.required_status_checks?.checks//[])|map(.context)),
                        reviews:(.required_pull_request_reviews?.required_approving_review_count//0),
                        conv:(.required_conversation_resolution?.enabled//false)}' \
  | tee "_tmp/protect.read.${TS}.json" >>"$LOG"

# 2) Inspecte les workflows présents
mapfile -t WF_LIST < <(gh workflow list --limit 200 | awk '{print $1}' )
HAS_PYPI=0; HAS_SECSCAN=0
for w in "${WF_LIST[@]}"; do
  [[ "$w" == "pypi-build.yml" ]] && HAS_PYPI=1
  [[ "$w" == "secret-scan.yml" ]] && HAS_SECSCAN=1
done
say "[WF] pypi-build.yml: $HAS_PYPI | secret-scan.yml: $HAS_SECSCAN"

# 3) Vérifie la présence de 'workflow_dispatch:' dans les fichiers locaux (main)
need_hint=0
chk_dispatch(){
  local f="$1"
  [[ -f ".github/workflows/$f" ]] || { say "[MISS] .github/workflows/$f absent sur disque"; need_hint=1; return; }
  if ! awk 'BEGIN{f=0} /^[[:space:]]*workflow_dispatch:/ {f=1} END{exit !f}' ".github/workflows/$f"; then
    say "[WARN] $f sans 'workflow_dispatch:' sur main"
    need_hint=1
  else
    say "[OK] $f contient 'workflow_dispatch:'"
  fi
}
[[ "$HAS_PYPI" -eq 1 ]] && chk_dispatch "pypi-build.yml" || need_hint=1
[[ "$HAS_SECSCAN" -eq 1 ]] && chk_dispatch "secret-scan.yml" || need_hint=1

# 4) Tentatives de dispatch (ne modifie pas les fichiers)
say "[DISPATCH] Essai sur ref=main (ignoré si pas supporté)…"
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || say "[HINT] pypi-build: dispatch non supporté (sans 'workflow_dispatch')."
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || say "[HINT] secret-scan: dispatch non supporté (sans 'workflow_dispatch')."
sleep 5

# 5) Poll ≤ 120 s pour 2 succès
say "[POLL] ≤120s pour SUCCESS de pypi-build & secret-scan"
ok=0
for i in $(seq 1 24); do
  line="$(gh run list --branch main --limit 20 2>/dev/null | awk '/pypi-build|secret-scan/ {print $2}' | paste -sd, -)"
  echo "[POLL $i] ${line:-'(no runs yet)'}" | tee -a "$LOG"
  succ=$(echo "${line:-}" | grep -c success || true)
  if [[ "$succ" -ge 2 ]]; then ok=1; break; fi
  sleep 5
done

if [[ "$ok" -eq 1 ]]; then
  say "[OK] Deux checks verts observés sur main."
else
  say "[WARN] Pas de double SUCCESS observé."
  if [[ "$need_hint" -eq 1 ]]; then
    cat <<'EOF'
[TODO] Ajoute 'workflow_dispatch:' dans ces fichiers sur main puis re-lance ce script :
  .github/workflows/pypi-build.yml
  .github/workflows/secret-scan.yml

Exemple minimal sûr :
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  push:
    branches: [ main ]
  workflow_dispatch:
EOF
  fi
fi
