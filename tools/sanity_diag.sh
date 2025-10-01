#!/usr/bin/env bash
set -euo pipefail
outdir=".ci-out"
mkdir -p "$outdir"
diag="$outdir/diag.json"
errors=0
warnings=0

# Exemple de checks légers (extensibles)
[ -d ".github/workflows" ] || { echo "WARN: .github/workflows manquant"; warnings=$((warnings+1)); }
command -v python >/dev/null || { echo "WARN: python manquant"; warnings=$((warnings+1)); }

# Écrit un JSON simple (sans Python) :
{
  printf '{'
  printf '"timestamp":"%s",' "$(date -u +%FT%TZ)"
  printf '"errors":%s,' "$errors"
  printf '"warnings":%s,' "$warnings"
  printf '"issues":['
  first=1
  if [ $warnings -gt 0 ]; then
    [ $first -eq 0 ] && printf ','; first=0
    printf '{"severity":"WARN","code":"BASIC_CHECK","path":"repo","msg":"Un ou plusieurs avertissements basiques"}'
  fi
  printf ']'
  printf '}\n'
} > "$diag"

echo "Diag écrit dans: $diag"
