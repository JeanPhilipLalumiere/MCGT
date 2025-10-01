#!/usr/bin/env bash
set -euo pipefail
branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"

id="$(gh run list --workflow sanity.yml -b "$branch" -L1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
[ -n "${id:-}" ] || { echo "No CI run found on $branch"; exit 2; }

echo "== Debug run $id on $branch =="
# Vue synthétique des jobs (avec étapes)
gh run view "$id" -v || true

echo
echo "-- Failed-step logs (if any) --"
# Affiche uniquement les logs des steps en échec (pratique)
gh run view "$id" --log-failed || true

echo
echo "-- All logs (download) --"
rm -rf .ci-logs && mkdir -p .ci-logs
gh run download "$id" --dir .ci-logs || true
find .ci-logs -type f -name '*.txt' -maxdepth 2 -print -exec sh -c 'printf "\n==== %s ====\n" "$1"; sed -n "1,200p" "$1"' _ {} \; || true
echo
echo "Logs complets sous .ci-logs/"
