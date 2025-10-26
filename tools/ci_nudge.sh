#!/usr/bin/env bash
# tools/ci_nudge.sh
# Déclenche la CI en poussant un commit vide sur la branche rewrite.
# Never-fail: n’interrompt pas le shell si une étape échoue.

set -u
BRANCH="${1:-rewrite/main-20251026T134200}"

echo "[INFO] Branche cible : $BRANCH"
# Assure-toi qu’on est sur la bonne branche locale
if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ]]; then
  echo "[INFO] Checkout $BRANCH (créée localement si nécessaire)…"
  git fetch origin "$BRANCH" >/dev/null 2>&1 || true
  git checkout -B "$BRANCH" "origin/$BRANCH" 2>/dev/null || git checkout "$BRANCH" || true
fi

echo "[RUN] Commit vide pour nudge CI…"
git commit --allow-empty -m "ci: nudge Actions on $BRANCH" || true

echo "[RUN] Push vers origin/$BRANCH…"
git push -u origin "$BRANCH" || echo "[WARN] push a échoué (vérifie droits réseau/auth)."

echo "[INFO] Si les workflows écoutent 'pull_request' ou 'push', la CI devrait démarrer."
echo "       Sinon, applique l’Option B pour ajouter 'workflow_dispatch' (et 'pull_request')."
