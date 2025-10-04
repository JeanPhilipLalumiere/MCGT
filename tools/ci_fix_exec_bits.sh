#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail

# Parcourt les fichiers suivis par git
git ls-files -z | while IFS= read -r -d '' f; do
  # Mode dans l'index (100755 => exécutable)
  mode="$(git ls-files -s -- "$f" | awk '{print $1}' | head -n1 || true)"
  has_shebang=0
  if [ -f "$f" ]; then
    if head -c 2 "$f" 2>/dev/null | grep -q '^#!'; then
      has_shebang=1
    fi
  fi

  if [ "$mode" = "100755" ] && [ "$has_shebang" -eq 0 ]; then
    echo "[-x] $f"
    git update-index --chmod=-x -- "$f"
  elif [ "$mode" != "100755" ] && [ "$has_shebang" -eq 1 ]; then
    echo "[+x] $f"
    git update-index --chmod=+x -- "$f"
  fi
done
