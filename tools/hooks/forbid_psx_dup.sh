#!/usr/bin/env bash
set -euo pipefail
status=0
for f in tools/*.sh; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "dallidbsx.sh" ] && continue
  count=$(grep -c 'PSX ROBUST OVERRIDE' "$f" || true)
  if [ "${count:-0}" -gt 1 ]; then
    echo "E: Bannière 'PSX ROBUST OVERRIDE' dupliquée dans $f" >&2
    status=1
  fi
  pc=$(grep -c '^[[:space:]]*psx_install[[:space:]]*\(' "$f" || true)
  if [ "${pc:-0}" -gt 1 ]; then
    echo "E: psx_install multiple dans $f" >&2
    status=1
  fi
done
exit $status
