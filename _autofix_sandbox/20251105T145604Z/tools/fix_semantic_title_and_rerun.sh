#!/usr/bin/env bash
# tools/fix_semantic_title_and_rerun.sh
# Usage:
#   bash tools/fix_semantic_title_and_rerun.sh 19 rewrite/main-20251026T134200

set -Eeuo pipefail
trap 'printf "\n[INFO] Script terminé (mode safe).\n"' EXIT

PR_NUMBER="${1:-19}"
BRANCH="${2:-rewrite/main-20251026T134200}"
NEW_TITLE='chore(repo): history rewrite & CI triggers for homogenization'
PR_URL="https://github.com/JeanPhilipLalumiere/MCGT/pull/${PR_NUMBER}"

info(){ printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

info "Titre à coller dans la PR #$PR_NUMBER :"
printf "\n%s\n\n" "$NEW_TITLE"

# Met le titre dans le presse-papiers si possible
if command -v xclip >/dev/null 2>&1; then
  printf "%s" "$NEW_TITLE" | xclip -selection clipboard && info "Titre copié (xclip)."
elif command -v pbcopy >/dev/null 2>&1; then
  printf "%s" "$NEW_TITLE" | pbcopy && info "Titre copié (pbcopy)."
else
  warn "Aucun utilitaire de presse-papiers détecté (copie manuelle nécessaire)."
fi

# Ouvre la PR dans le navigateur si possible
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$PR_URL" >/dev/null 2>&1 || true
elif command -v open >/dev/null 2>&1; then
  open "$PR_URL" >/dev/null 2>&1 || true
else
  info "Ouvre cette URL et colle le titre : $PR_URL"
fi

# Optionnel : commenter la PR (non bloquant)
if command -v gh >/dev/null 2>&1; then
  gh pr comment "$PR_NUMBER" --body "Updated title to Conventional Commits. Re-running CI on \`$BRANCH\`." || true
fi

# Relance CI via workflow_dispatch (non bloquant)
if command -v gh >/dev/null 2>&1; then
  info "Relance CI (workflow_dispatch)…"
  gh workflow run .github/workflows/build-publish.yml -r "$BRANCH" || warn "Dispatch build-publish.yml indisponible."
  gh workflow run .github/workflows/ci-accel.yml       -r "$BRANCH" || warn "Dispatch ci-accel.yml indisponible."
else
  warn "gh non disponible — le renommage + push/PR déclencheront déjà les jobs."
fi

info "Après renommage : surveille 'gh pr checks $PR_NUMBER' ou 'bash tools/merge_when_green.sh $PR_NUMBER'."
