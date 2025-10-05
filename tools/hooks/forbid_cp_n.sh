#!/usr/bin/env bash
set -euo pipefail
status=0
for f in tools/*.sh; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "dallidbsx.sh" ] && continue
  # Ignore lignes commentées ; détecte "cp -n" ailleurs
  if awk 'BEGIN{bad=0}
           /^[[:space:]]*#/ {next}
           { if ($0 ~ /(^|[[:space:];])cp[[:space:]]+-n([[:space:]]|$)/) { bad=1; print "E: cp -n détecté dans " FILENAME; exit 1 } }
           END{exit bad}' "$f"; then :; else status=1; fi
done
exit $status
