#!/usr/bin/env bash
set -euo pipefail

PR_NUM="${PR_NUM:-26}"

REPO_ROOT="$(git rev-parse --show-toplevel)"; cd "$REPO_ROOT"
mkdir -p _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/rebase_pr${PR_NUM}_${TS}.log"

echo "[INFO] Start rebase helper for PR #$PR_NUM" | tee -a "$LOG"

# 0) Contexte PR
BR_PR="$(gh pr view "$PR_NUM" --json headRefName -q .headRefName)"
echo "[INFO] PR branch: $BR_PR" | tee -a "$LOG"

# 1) Mise à jour remote
git fetch origin main "$BR_PR" | tee -a "$LOG" || true

# 2) Checkout PR et branche de secours
git switch "$BR_PR" 2>/dev/null || git checkout -b "$BR_PR" "origin/$BR_PR"
SAFE="backup/${BR_PR}_before_rebase_${TS}"
git branch -f "$SAFE" "$BR_PR" >/dev/null 2>&1 || git branch "$SAFE"
echo "[INFO] Safety branch created: $SAFE" | tee -a "$LOG"

# 3) Rebase
set +e
git rebase origin/main
REBASERC=$?
set -e

if [[ $REBASERC -ne 0 ]]; then
  echo "[CONFLICT] Rebase en conflit. Liste des fichiers :" | tee -a "$LOG"
  git status --porcelain=v1 | tee -a "$LOG"
  echo
  echo "Étapes à faire maintenant :"
  echo "  a) Résous les conflits dans les fichiers marqués (UU/AA/etc.)."
  echo "  b) git add <fichiers_résolus>"
  echo "  c) Reprends le rebase :   git rebase --continue"
  echo "  d) Si besoin d'annuler :  git rebase --abort && git reset --hard $SAFE"
  echo
  read -r -p $'Quand tu as fini la résolution (ou si tu veux annuler), appuie sur ENTER pour poursuivre…\n' _ </dev/tty || true

  # Détection post-intervention
  if git rebase --continue 2>/dev/null; then
    echo "[OK] Rebase terminé après résolution." | tee -a "$LOG"
  else
    echo "[ABORT] Rebase non terminé. Tu peux relancer ce script plus tard." | tee -a "$LOG"
    read -r -p $'ENTER pour fermer cette fenêtre…\n' _ </dev/tty || true
    exit 3
  fi
else
  echo "[OK] Rebase passé sans conflit." | tee -a "$LOG"
fi

# 4) Push branch PR (déclenche checks PR: pull_request/synchronize)
git push -u origin "$BR_PR" | tee -a "$LOG"

# 5) Attente checks requis au HEAD
HEAD="$(gh pr view "$PR_NUM" --json headRefOid -q .headRefOid)"
echo "[WAIT] Checks requis sur HEAD=$HEAD" | tee -a "$LOG"
for i in $(seq 1 40); do
  sleep 6
  JSON="$(gh api repos/:owner/:repo/commits/$HEAD/check-runs)"
  echo "$JSON" | jq -r '.check_runs[]|[.name,.app.name,.status,.conclusion]|@tsv' | tee -a "$LOG"
  BUILD_OK="$(echo "$JSON" | jq -r '[.check_runs[]|select(.app.name=="GitHub Actions" and .name=="build")|.conclusion]|any(.=="success")')"
  GITL_OK="$(echo "$JSON" | jq -r '[.check_runs[]|select(.app.name=="GitHub Actions" and .name=="gitleaks")|.conclusion]|any(.=="success")')"
  echo "  - build=$BUILD_OK ; gitleaks=$GITL_OK"
  if [[ "$BUILD_OK" == "true" && "$GITL_OK" == "true" ]]; then
    echo "[OK] Required checks green." | tee -a "$LOG"; break
  fi
done

# 6) Merge PR (politique actuelle exige 1 review). Tente normal, sinon suggère options.
if gh pr merge "$PR_NUM" --rebase; then
  echo "[OK] PR merged." | tee -a "$LOG"
else
  echo "[BLOCK] Merge encore bloqué (probablement review manquante)." | tee -a "$LOG"
  echo "Options :" | tee -a "$LOG"
  echo "  - Obtenir un APPROVE d'un reviewer avec write" | tee -a "$LOG"
  echo "  - OU baisser temporairement required_approving_review_count=0, merger, puis restaurer=1" | tee -a "$LOG"
fi

read -r -p $'Fin. Appuie sur ENTER pour fermer cette fenêtre…\n' _ </dev/tty || true
