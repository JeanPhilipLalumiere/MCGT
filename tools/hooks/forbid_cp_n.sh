#!/usr/bin/env bash
set -euo pipefail
status=0
for f in tools/*.sh; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "dallidbsx.sh" ] && continue

  # awk: ignore commentaires et HEREDOCs (<<TAG ... TAG)
  if awk '
    BEGIN{bad=0; inhd=0; endtag=""; dash=0}
    function starts_heredoc(line,   m){
      if (match(line, /<<-?[ \t]*([\"\047]?)([A-Za-z0-9_]+)\1/, m)) {
        dash = (index(line, "<<-")>0)
        endtag = m[2]
        inhd=1
        next
      }
    }
    {
      if (inhd) {
        if (dash) {
          if ($0 ~ "^\t*" endtag "$") { inhd=0 }
        } else {
          if ($0 ~ "^" endtag "$") { inhd=0 }
        }
        next
      }
      if ($0 ~ /^[[:space:]]*#/) next
      starts_heredoc($0)
      if ($0 ~ /(^|[[:space:];])cp[[:space:]]+-n([[:space:]]|$)/) { 
        print "E: cp -n détecté dans " FILENAME; bad=1; exit 1 
      }
    }
    END{exit bad}
  ' "$f"; then :; else status=1; fi
done
exit $status
