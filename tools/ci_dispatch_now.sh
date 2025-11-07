#!/usr/bin/env bash
# tools/ci_dispatch_now.sh
# Déclenche la CI sur la branche rewrite et affiche/suit les runs.
# - Ne casse pas le shell si 'gh' n'est pas loggé ou si un run n'existe pas encore.
# - Si des runs sont déjà en cours, on affiche leur état.
# Dépendances : gh CLI connecté au repo.

set -u
BRANCH="${1:-rewrite/main-20251026T134200}"

echo "[INFO] Branche cible : $BRANCH"

run_dispatch() {
  local wf="$1"
  if [[ -f "$wf" ]]; then
    echo "[RUN] gh workflow run $wf -r $BRANCH"
    gh workflow run "$wf" -r "$BRANCH" || echo "[WARN] Dispatch échoué ou non nécessaire pour $wf."
  else
    # Autorise aussi le nom simple (au cas où)
    echo "[RUN] gh workflow run $wf -r $BRANCH"
    gh workflow run "$wf" -r "$BRANCH" || echo "[WARN] Dispatch échoué ou non nécessaire pour $wf."
  fi
}

# Déclenche les 2 workflows connus
run_dispatch ".github/workflows/build-publish.yml"
run_dispatch ".github/workflows/ci-accel.yml"

echo "[INFO] Récupération des runs récents sur $BRANCH…"
# Affiche les runs triés du plus récent au plus ancien
gh run list --branch "$BRANCH" --limit 10 --json databaseId,name,status,conclusion,headBranch,htmlURL \
  -q '.[] | select(.headBranch=="'"$BRANCH"'") | "\(.databaseId)\t\(.name)\t\(.status)\t\(.conclusion)\t\(.htmlURL)"' \
  2>/dev/null || echo "[WARN] Impossible de lister les runs (gh non connecté ?)."

# Optionnel : suivre le plus récent si présent
LAST_ID="$(gh run list --branch "$BRANCH" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
if [[ -n "${LAST_ID:-}" ]]; then
  echo "[INFO] Suivi du run le plus récent : $LAST_ID"
  gh run watch "$LAST_ID" || echo "[WARN] gh run watch a terminé (ou a échoué)."
else
  echo "[INFO] Aucun run détecté pour l’instant (peut prendre quelques secondes après le dispatch)."
fi

echo "[DONE] Quand les checks sont verts, fusionne la PR #19 en 'Rebase and merge' (ou 'Squash and merge')."
