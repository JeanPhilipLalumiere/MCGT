#!/usr/bin/env bash
set -euo pipefail
WS="${GITHUB_WORKSPACE:-$PWD}"
OUT="${WS}/.ci-out"
mkdir -p "$OUT"
DIAG="${OUT}/diag.json"
errors=0; warnings=0
# Exemple de vérif simple:
[ -d "${WS}/.github/workflows" ] || warnings=$((warnings+1))
cat > "$DIAG" <<JSON
{"timestamp":"$(date -u +%FT%TZ)","errors":$errors,"warnings":$warnings,"issues":[{"severity":"INFO","code":"PING","msg":"sanity OK"}]}
JSON
sync || true
echo "Diag écrit: $DIAG"
ls -la "$OUT" || true
