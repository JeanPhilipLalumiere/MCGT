#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

# Detect & optionally fix BOM/CRLF/TABS in YAML workflows.
# Usage: tools/forbid_bom_crlf_tabs.sh [--fix] [files...]
fix=0
if [[ "${1-}" == "--fix" ]]; then
  fix=1
  shift
fi

files=("$@")
if [[ ${#files[@]} -eq 0 ]]; then
  files=(.github/workflows/*.yml .github/workflows/*.yaml)
fi

has_issue=0
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  bom=0 crlf=0 tabs=0

  # BOM?
  if [[ -s "$f" ]]; then
    bomhex="$(head -c3 -- "$f" | od -An -t x1 | tr -d ' \n')"
    [[ "$bomhex" == "efbbbf" ]] && bom=1
  fi
  # CRLF ?
  grep -q $'\r' -- "$f" && crlf=1 || true
  # Tabs ?
  grep -q $'\t' -- "$f" && tabs=1 || true

  if ((bom || crlf || tabs)); then
    echo "[BAD] $f: BOM=${bom} CRLF=${crlf} TABS=${tabs}"
    if ((fix)); then
      tmp="$(mktemp)"
      # strip BOM
      awk 'NR==1{sub(/^\xef\xbb\xbf/,"")} {print}' "$f" >"$tmp"
      mv "$tmp" "$f"
      # CRLF -> LF
      sed -i 's/\r$//' "$f"
      # Tabs -> 2 spaces
      tmp="$(mktemp)"
      expand -t2 "$f" >"$tmp" && mv "$tmp" "$f"
      echo "[FIX] $f normalisé (BOM/CRLF/TABS)"
    else
      has_issue=1
    fi
  fi
done

exit $has_issue
