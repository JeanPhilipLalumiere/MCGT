#!/usr/bin/env bash
set -euo pipefail
outdir=".ci-out"
mkdir -p "$outdir"
diag="$outdir/diag.json"
errors=0; warnings=0
[ -d ".github/workflows" ] || { warnings=$((warnings+1)); echo "WARN: .github/workflows manquant"; }
command -v python >/dev/null || { warnings=$((warnings+1)); echo "WARN: python manquant"; }
{
  printf '{'
  printf '"timestamp":"%s",' "$(date -u +%FT%TZ)"
  printf '"errors":%s,' "$errors"
  printf '"warnings":%s,' "$warnings"
  printf '"issues":['
  first=1
  if [ $warnings -gt 0 ]; then
    [ $first -eq 0 ] && printf ','; first=0
    printf '{"severity":"WARN","code":"BASIC_CHECK","path":"repo","msg":"Avertissements basiques présents"}'
  fi
  printf ']'
  printf '}\n'
} > "$diag"
echo "Diag écrit: $diag"
