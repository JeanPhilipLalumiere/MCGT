#!/usr/bin/env bash
# Affiche tout ce qui suit la 1ère ligne égale à "# === COPY LOGS FROM HERE ==="
# Usage:
#   tools/extract_from_marker.sh <fichier_log>
#   <commande> | tools/extract_from_marker.sh
set -euo pipefail
marker='^# === COPY LOGS FROM HERE ===$'
awk -v m="$marker" '
  $0 ~ m { start=1; next }
  start { print }
' "${1:-/dev/stdin}"
