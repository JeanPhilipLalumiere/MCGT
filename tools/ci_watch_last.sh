#!/usr/bin/env bash
set +e
branch="${1:-main}"
id="$(gh run list --workflow sanity.yml -b "$branch" -L1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
[ -n "$id" ] || { echo "No CI run found on $branch"; exit 2; }
echo "Watching sanity.yml run $id on $branch…"
gh run watch --exit-status "$id" || true
