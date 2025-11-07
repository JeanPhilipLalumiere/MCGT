#!/usr/bin/env bash
# tools/push_and_nudge_ci.sh
# Usage:
#   bash tools/push_and_nudge_ci.sh 19 rewrite/main-20251026T134200
#   (par défaut: PR=19, BR=rewrite/main-20251026T134200)

set -Eeuo pipefail
trap 'printf "\n[INFO] Fin (mode safe). Aucun arrêt brutal.\n"' EXIT

PR_NUMBER="${1:-19}"
BRANCH="${2:-rewrite/main-20251026T134200}"
NEW_TITLE='chore(repo): history rewrite & CI triggers for homogenization'

info(){ printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

info "Branche cible : $BRANCH ; PR : #$PR_NUMBER"

# 1) Push des commits locaux (si en avance)
LOCAL="$(git rev-parse --short HEAD || echo local)"
REMOTE="$(git rev-parse --short "origin/$BRANCH" 2>/dev/null || echo none)"
if [ "$LOCAL" != "$REMOTE" ]; then
  info "Push des commits locaux vers origin/$BRANCH…"
  git push -u origin "$BRANCH" || warn "Push échoué (vérifie l'auth)."
else
  info "Aucun nouveau commit local à pousser."
fi

# 2) Tentative d’édition du titre (non bloquant si gh indisponible)
if command -v gh >/dev/null 2>&1; then
  info "Tentative de mise à jour du titre PR (Conventional Commits)…"
  if gh pr edit "$PR_NUMBER" --title "$NEW_TITLE"; then
    info "Titre PR mis à jour."
  else
    warn "Impossible d’éditer via gh. Modifie le titre via l’interface GitHub."
  fi
else
  warn "gh non installé ou non connecté — modifie le titre PR dans l’UI GitHub."
fi

# 3) Relance CI (dispatch) — non bloquant
if command -v gh >/dev/null 2>&1; then
  info "Dispatch workflows build/ci si présents…"
  gh workflow run .github/workflows/build-publish.yml -r "$BRANCH" || warn "Dispatch build-publish.yml indisponible."
  gh workflow run .github/workflows/ci-accel.yml       -r "$BRANCH" || warn "Dispatch ci-accel.yml indisponible."
else
  warn "gh non disponible — le push déclenchera les jobs configurés sur push/pull_request."
fi

info "Next: vérifier les checks sur la PR #$PR_NUMBER, corriger les gardes restants si besoin."
