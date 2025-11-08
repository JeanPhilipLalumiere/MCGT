#!/usr/bin/env bash
set -euo pipefail
status=0
for f in tools/*.sh; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "dallidbsx.sh" ] && continue

  # Compter en ignorant commentaires et HEREDOCs
  counts=$(awk '
    BEGIN{inhd=0; endtag=""; dash=0; c_psx=0; c_install=0}
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
        if (dash) { if ($0 ~ "^\t*" endtag "$") { inhd=0 } }
        else      { if ($0 ~ "^" endtag "$")    { inhd=0 } }
        next
      }
      if ($0 ~ /^[[:space:]]*#/) next
      starts_heredoc($0)
      if ($0 ~ /PSX ROBUST OVERRIDE/) c_psx++
      if ($0 ~ /^[[:space:]]*psx_install[[:space:]]*\(/) c_install++
    }
    END{ printf("%d %d\n", c_psx, c_install) }
  ' "$f")
  cpsx=$(printf "%s\n" "$counts" | awk '{print $1}')
  cins=$(printf "%s\n" "$counts" | awk '{print $2}')
  if [ "${cpsx:-0}" -gt 1 ]; then
    echo "E: Bannière 'PSX ROBUST OVERRIDE' dupliquée dans $f" >&2
    status=1
  fi
  if [ "${cins:-0}" -gt 1 ]; then
    echo "E: psx_install multiple dans $f" >&2
    status=1
  fi
done
exit $status
