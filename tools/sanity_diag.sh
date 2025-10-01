#!/usr/bin/env bash
set -euo pipefail
outdir=".ci-out"; mkdir -p "$outdir"
diag="$outdir/diag.json"
errors=0; warnings=0
[ -d ".github/workflows" ] || { warnings=$((warnings+1)); echo "WARN: .github/workflows manquant"; }
cat > "$diag" <<JSON
{"timestamp":"$(date -u +%FT%TZ)","errors":$errors,"warnings":$warnings,"issues":[{"severity":"INFO","code":"PING","path":"repo","msg":"sanity OK"}]}
JSON
echo "Diag écrit: $diag"
