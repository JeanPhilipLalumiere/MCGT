#!/usr/bin/env bash
# tools/merge_when_green.sh
# Surveille les checks d'une PR et fusionne (rebase) seulement si DO_MERGE=1 + checks OK.
# Dépendances : gh CLI connecté au repo.

set -euo pipefail

PR_NUMBER="${1:-19}"
MERGE_MODE="${MERGE_MODE:-rebase}"   # rebase | squash
DO_MERGE="${DO_MERGE:-0}"

echo "[INFO] PR ciblée : #$PR_NUMBER (merge_mode=$MERGE_MODE, do_merge=$DO_MERGE)"

# 1) Surveiller les checks jusqu’à terminaison
echo "[INFO] Surveillance des checks (gh pr checks --watch)…"
if ! gh pr checks "$PR_NUMBER" --watch; then
  echo "[ERROR] Certains checks ont échoué ou sont requis mais non verts."
  echo "        Corrige puis relance ce script."
  exit 1
fi

# 2) Vérifier l’état de merge et la politique anti-merge-commit
echo "[INFO] Vérification de l’état de merge de la PR…"
gh pr view "$PR_NUMBER" --json state,mergeable,mergeStateStatus,isDraft,baseRefName,headRefName \
  -q '"state=\(.state) mergeable=\(.mergeable) draft=\(.isDraft) mergeState=\(.mergeStateStatus) base=\(.baseRefName) head=\(.headRefName)"'

# 3) Si DO_MERGE=1, on fusionne en rebase (ou squash). Sinon, on s’arrête proprement.
if [[ "$DO_MERGE" != "1" ]]; then
  echo "[DONE] Tous les checks sont verts."
  echo "       Pour fusionner : DO_MERGE=1 MERGE_MODE=rebase bash tools/merge_when_green.sh $PR_NUMBER"
  echo "       (ou MERGE_MODE=squash selon préférence)"
  exit 0
fi

# 4) Merge safe (sans merge-commit) selon le mode demandé
case "$MERGE_MODE" in
  rebase)
    echo "[RUN] gh pr merge #$PR_NUMBER --rebase --delete-branch"
    gh pr merge "$PR_NUMBER" --rebase --delete-branch
    ;;
  squash)
    echo "[RUN] gh pr merge #$PR_NUMBER --squash --delete-branch"
    gh pr merge "$PR_NUMBER" --squash --delete-branch
    ;;
  *)
    echo "[ERROR] MERGE_MODE invalide : $MERGE_MODE (attendu: rebase|squash)"
    exit 2
    ;;
esac

echo "[OK] PR fusionnée avec succès en mode $MERGE_MODE (pas de merge-commit)."
echo "[NOTE] Préviens l’équipe : git fetch --all && git checkout main && git reset --hard origin/main"
