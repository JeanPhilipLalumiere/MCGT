#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
FIGDIR="${FIGDIR:-$ROOT/zz-figures}"
QUAR="$FIGDIR/_legacy_conflicts"
OUT="${OUT:-$ROOT/zz-manifests/manifest_figures.sha256sum}"

mkdir -p "$(dirname "$OUT")"

# Inventaire: fichiers réels (pas de symlinks), extensions images, en excluant la quarantaine
# Trié pour stabilité.
find "$FIGDIR" -path "$QUAR" -prune -o \
  -type f ! -xtype l \
  \( -iname '*.png' -o -iname '*.svg' -o -iname '*.pdf' \) -print0 \
| sort -z \
| xargs -0 -I{} sha256sum "{}" > "$OUT"

echo "Wrote $OUT ($(
  awk 'END{print NR}' "$OUT"
) entries)"
