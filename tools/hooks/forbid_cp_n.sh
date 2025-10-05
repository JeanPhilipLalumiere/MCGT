#!/usr/bin/env bash
set -euo pipefail
status=0
for f in tools/*.sh; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "dallidbsx.sh" ] && continue
  # Ignore les lignes qui commencent par # ; détecte "cp -n" ailleurs
  if awk 'BEGIN{status=0}
           /^[[:space:]]*#/ {next}
           { if ($0 ~ /(^|[[:space:];])cp[[:space:]]+-n([[:space:]]|$)/) { status=1; print "E: cp -n détecté dans " FILENAME; exit 1 } }
           END{exit status}' "$f"; then
    :
  else
    status=1
  fi
done
exit $status
