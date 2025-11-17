#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo; echo "[FIN] code=$rc"; read -rp "Entrée pour fermer... " _' EXIT

PR="${1:-59}"

echo "[0] Récupère la branche head de la PR"
HEADB="$(gh pr view "$PR" --json headRefName --jq .headRefName)"
git fetch origin "$HEADB:$HEADB" || true
git switch "$HEADB"

echo "[1] Commit local SANS signature (évite SSH agent)"
# S’il y a des modifs (manifest/README), on commit sans signer
if ! git diff --quiet || ! git diff --staged --quiet; then
  git add -A
  git -c commit.gpgsign=false commit -m "chore(manifests): sync from FS; purge missing · docs(readme): sync meta"
else
  echo "    (rien à commit)"
fi

echo "[2] Push"
git push -u origin "$HEADB"

echo "[3] Titre PR conforme semantic-pr"
gh pr edit "$PR" --title "chore(manifests,readme,sdist): replay PR58 · sync manifest; sdist code-only" || true

echo "[4] Relance ciblée des guards"
for id in $(gh run list --limit 50 --json databaseId,name,headBranch \
  --jq '.[] | select(.headBranch=="'"$HEADB"'" and (.name|test("manifest-guard|readme-guard|guard-ignore-and-sdist|semantic"))) | .databaseId'); do
  gh run rerun "$id" --failed || true
done

echo "[5] Watch (quitte quand tout vert ou blocage persistant)"
gh pr checks "$PR" --watch || true
