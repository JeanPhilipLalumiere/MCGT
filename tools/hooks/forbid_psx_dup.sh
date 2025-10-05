#!/usr/bin/env bash
set -euo pipefail
# échoue si une bannière "PSX ROBUST OVERRIDE" apparaît plus d'une fois dans un fichier
ok=0
while IFS= read -r -d '' f; do
  c=$(grep -c "PSX ROBUST OVERRIDE" "$f" || true)
  if [ "$c" -gt 1 ]; then
    echo "Duplicate PSX banner in: $f"
    ok=1
  fi
done < <(git ls-files -z tools/*.sh 2>/dev/null)
exit $ok
