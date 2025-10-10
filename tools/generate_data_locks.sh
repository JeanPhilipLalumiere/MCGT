#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if ! command -v jq >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq && sudo apt-get install -y -qq jq
  else
    echo "::error::jq is required"; exit 2
  fi
fi

count=0
while IFS= read -r -d '' f; do
  lock="${f}.lock.json"
  if [ -s "$lock" ]; then
    continue
  fi
  sha="$(sha256sum "$f" | awk '{print $1}')"
  sz="$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f")"
  bn="$(basename "$f")"
  ch="$(basename "$(dirname "$f")")"
  src="INTERNAL"
  license="UNKNOWN"
  case "$bn" in
    *pantheon* ) src="Pantheon compilation (placeholder)"; license="per-source";;
    *bao* ) src="BAO compilation (placeholder)"; license="per-source";;
    *gwtc*|*GWTC* ) src="GWTC-3 catalog (placeholder)"; license="per-source";;
    *planck* ) src="Planck (placeholder)"; license="per-source";;
  esac
  mkdir -p "$(dirname "$lock")"
  cat > "$lock" <<JSON
{
  "file": "$bn",
  "chapter": "$ch",
  "sha256": "$sha",
  "size_bytes": $sz,
  "provenance": {
    "source": "$src",
    "license": "$license",
    "note": "Populate exact DOI/URL/license later if external."
  },
  "generated_at_utc": "$(date -u +%FT%TZ)"
}
JSON
  echo "lock -> $lock"
  count=$((count+1))
done < <(find zz-data -type f -not -name '*.lock.json' -print0 2>/dev/null)

echo "Locks generated: $count"
