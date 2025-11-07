#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — met à jour la branche PR depuis main, relance les checks requis, arme auto-merge
set -u -o pipefail; set +e

PR="${1:-20}"
BASE="${2:-main}"

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

BR_PR="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)"
[ -z "${BR_PR:-}" ] && { echo "[ERR ] Impossible d’obtenir la branche PR (gh)."; exit 0; }
info "PR #$PR • base=$BASE • head=$BR_PR"

# 0) se placer sur la branche PR
git fetch origin >/dev/null 2>&1
git switch "$BR_PR" >/dev/null 2>&1 || git checkout "$BR_PR"

# 1) update-branch côté Git (équivalent du bouton « Update branch »)
#    on tente d’abord un merge fast-forward sinon merge --no-edit
if git merge-base --is-ancestor "origin/$BASE" "HEAD"; then
  info "HEAD contient déjà origin/$BASE (pas de retard)."
else
  info "Merge origin/$BASE -> $BR_PR (mise à jour requise)…"
  git merge --no-edit "origin/$BASE" && ok "Merge avec $BASE OK" || warn "Merge non fast-forward : vérifie les conflits si signalés."
fi

# 2) pousser la branche PR
git push || warn "Push impossible (droits ?)."

# 3) relancer les 2 checks REQUIS uniquement
relance(){
  local wf="$1"
  if gh workflow view "$wf" >/dev/null 2>&1; then
    gh workflow run "$wf" -r "$BR_PR" >/dev/null 2>&1 && ok "dispatch $wf@$BR_PR" || warn "dispatch $wf a échoué"
  else
    warn "$wf introuvable (pas de workflow_dispatch ?)."
  fi
}
relance ".github/workflows/pypi-build.yml"
relance ".github/workflows/secret-scan.yml"

# 4) tenter d’armer l’auto-merge rebase
if gh pr merge "$PR" --rebase --delete-branch --auto >/dev/null 2>&1; then
  ok "Auto-merge (rebase) armé. Le merge se fera dès que pypi-build & gitleaks seront VERTS."
else
  warn "Impossible d'armer l'auto-merge via CLI (droits/paramètres). Tu peux cliquer 'Enable auto-merge' (Rebase) dans l’UI."
fi

# 5) rappeler les requis
echo
info "Checks requis sur '$BASE' :"
gh api "repos/:owner/:repo/branches/$BASE/protection" -H "Accept: application/vnd.github+json" | jq -r '.required_status_checks.checks[]?.context'
echo
info "Surveille PR #$PR (onglet Checks). Quand les 2 requis sont VERTS :"
echo "  gh pr merge $PR --rebase --delete-branch"
echo
ok "Terminé — fenêtre laissée OUVERTE."
