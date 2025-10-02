#!/usr/bin/env bash
set -euo pipefail
STAMP="$(date +%Y%m%dT%H%M%S)"
DEST=".ci-archive/workflows-bak-${STAMP}"
mkdir -p "$DEST"

shopt -s nullglob
mv .github/workflows/*.bak* "$DEST" 2>/dev/null || true
echo "Archivé dans: $DEST"
ls -lah "$DEST" || true
