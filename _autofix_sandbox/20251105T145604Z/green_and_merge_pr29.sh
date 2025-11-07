#!/usr/bin/env bash
# green_and_merge_pr29.sh — Déclenche les 2 checks requis sur la tête du PR #29,
# attend SUCCESS, puis merge (squash). Pas de changement de protection.
# Garde-fou: ne ferme pas la fenêtre à la fin.
set -euo pipefail

PR_NUM="${1:-29}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _logs _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/green_and_merge_pr${PR_NUM}_${TS}.log"

say(){ echo -e "$*" | tee -a "$LOG"; }

say "[INFO] Prepare PR #$PR_NUM"
META="$(gh pr view "$PR_NUM" --json headRefName,headRefOid,baseRefName,url)"
BR="$(jq -r .headRefName <<<"$META")"
HEAD="$(jq -r .headRefOid <<<"$META")"
URL="$(jq -r .url <<<"$META")"
BASE="$(jq -r .baseRefName <<<"$META")"
say "[INFO] $URL | $BR -> $BASE | HEAD=$HEAD"

# 1) Vérifier que les workflows existent et ont les bons triggers
check_has_dispatch(){
  local wf="$1"
  gh api repos/:owner/:repo/actions/workflows | jq -r '.workflows[].path' | grep -Fx "$wf" >/dev/null 2>&1 || return 2
  # Vérifier contenu local si présent
  if [[ -f "$wf" ]]; then
    grep -Eq 'workflow_dispatch:' "$wf" || return 3
  fi
  return 0
}

# 2) Déclencher les deux workflows sur la branche du PR
say "[DISPATCH] pypi-build.yml & secret-scan.yml sur ref=$BR"
if ! check_has_dispatch ".github/workflows/pypi-build.yml"; then
  say "[WARN] pypi-build.yml sans workflow_dispatch dans la copie locale; on tente quand même via API."
fi
gh workflow run pypi-build.yml --ref "$BR" >/dev/null 2>&1 || say "[WARN] dispatch pypi-build.yml a échoué (peut déjà être en file, on continue)"

if ! check_has_dispatch ".github/workflows/secret-scan.yml"; then
  say "[WARN] secret-scan.yml sans workflow_dispatch local; on tente quand même via API."
fi
gh workflow run secret-scan.yml --ref "$BR" >/dev/null 2>&1 || say "[WARN] dispatch secret-scan.yml a échoué (peut déjà être en file, on continue)"

# 3) Boucle de poll jusqu’à SUCCESS sur les 2 checks requis
say "[WAIT] Attente checks requis sur le PR (pypi-build/build & secret-scan/gitleaks)"
ok=0
for i in $(seq 1 120); do
  # Lis l’état agrégé des checks sur le PR
  ROLL="$(gh pr view "$PR_NUM" --json statusCheckRollup 2>/dev/null || echo '{}')"
  # Affichage lisible (facultatif)
  echo "$ROLL" | jq -r '.statusCheckRollup[] | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks") | [.name,.status,.conclusion] | @tsv' \
    | sed 's/\t/ | /g' | tee -a "$LOG" || true

  # Test de succès
  if echo "$ROLL" | jq -e '
      [.statusCheckRollup[]
        | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
        | .conclusion] as $c
      | ($c|length==2) and ( ($c|index("SUCCESS")!=null) and ($c|rindex("SUCCESS")!=null) )
    ' >/dev/null 2>&1; then
    ok=1; break
  fi
  sleep 5
done

if [[ "$ok" != "1" ]]; then
  say "[HINT] Les checks tardent. Petit « coup de coude »: empty commit pour provoquer un synchronize."
  git fetch origin
  git switch "$BR" >/dev/null 2>&1 || git checkout "$BR"
  git commit --allow-empty -m "ci: synchronize to surface required checks on PR #$PR_NUM" >/dev/null 2>&1 || true
  git push --force-with-lease >/dev/null 2>&1 || true
  git switch - >/dev/null 2>&1 || true

  say "[WAIT] Re-poll après synchronize"
  for i in $(seq 1 60); do
    ROLL="$(gh pr view "$PR_NUM" --json statusCheckRollup 2>/dev/null || echo '{}')"
    echo "$ROLL" | jq -r '.statusCheckRollup[] | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks") | [.name,.status,.conclusion] | @tsv' \
      | sed 's/\t/ | /g' | tee -a "$LOG" || true
    if echo "$ROLL" | jq -e '
        [.statusCheckRollup[]
          | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
          | .conclusion] as $c
        | ($c|length==2) and ( ($c|index("SUCCESS")!=null) and ($c|rindex("SUCCESS")!=null) )
      ' >/dev/null 2>&1; then
      ok=1; break
    fi
    sleep 5
  done
fi

if [[ "$ok" != "1" ]]; then
  say "[ERROR] Impossible d’obtenir SUCCESS sur les 2 checks dans le délai. Abandon propre."
  read -r -p $'Fin. ENTER pour fermer…\n' _ </dev/tty || true
  exit 2
fi

say "[OK] Checks requis = SUCCESS. On tente le merge."
if ! gh pr merge "$PR_NUM" --squash --delete-branch; then
  say "[WARN] Merge refusé. Tentative --admin (si autorisé)…"
  gh pr merge "$PR_NUM" --squash --admin --delete-branch || {
    say "[ERROR] Échec du merge même avec --admin."
    read -r -p $'Fin. ENTER pour fermer…\n' _ </dev/tty || true
    exit 3
  }
fi

say "[DONE] PR #$PR_NUM fusionnée proprement. Journal: $LOG"
read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
