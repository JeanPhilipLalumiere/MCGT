#!/usr/bin/env bash
set -euo pipefail
WS="${GITHUB_WORKSPACE:-$PWD}"
OUT="${WS}/.ci-out"
mkdir -p "${OUT}"
ts="$(date -u +%FT%TZ)"
cat > "${OUT}/diag.json" <<JSON
{"timestamp":"${ts}","errors":0,"warnings":0,"issues":[{"severity":"INFO","code":"PING","msg":"sanity OK"}]}
JSON
echo "${ts}" > "${OUT}/diag.ts"
echo "Contenu ${OUT}:"
ls -la "${OUT}" || true
