#!/usr/bin/env bash
set +e
wf="${1:-sanity_dispatch.yml}"
branch="${2:-main}"
rid="$(gh run list --workflow "$wf" -b "$branch" -L1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
[ -n "$rid" ] || { echo "No CI run found on $branch"; exit 2; }
echo "Watching $wf run $rid on $branch…"
gh run watch --exit-status "$rid" || true
