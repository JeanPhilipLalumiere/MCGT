#!/usr/bin/env bash
set -euo pipefail
branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"

id="$(gh run list --workflow sanity.yml -b "$branch" -L1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
[ -n "${id:-}" ] || { echo "No CI run found on $branch"; exit 2; }

echo "== Logs pour sanity.yml run $id sur $branch =="

echo
echo "-- Journal complet (toutes étapes) --"
# Affiche tout le log console du run
gh run view "$id" --log || true

echo
echo "-- Jobs & étapes (vue détaillée) --"
# Liste les jobs avec étapes et durées
gh run view "$id" -v || true

echo
echo "-- Logs des étapes en échec (si présent) --"
gh run view "$id" --log-failed || true

echo
echo "-- Artifacts (si existants) --"
rm -rf .ci-logs && mkdir -p .ci-logs
if gh run download "$id" --dir .ci-logs 2>/dev/null; then
  find .ci-logs -type f -name '*.txt' -print -exec sh -c 'printf "\n==== %s ====\n" "$1"; sed -n "1,80p" "$1"' _ {} \;
  [ -f .ci-logs/diag.json ] && { echo; echo "diag.json (head):"; head -n 80 .ci-logs/diag.json; }
  [ -f .ci-logs/diag.err ] && { echo; echo "diag.err (head):"; sed -n '1,120p' .ci-logs/diag.err; }
else
  echo "pas d'artifacts à télécharger (normal pour l’instant)."
fi
echo "== Fin =="
