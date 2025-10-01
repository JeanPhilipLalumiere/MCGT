#!/usr/bin/env bash
set -euo pipefail
[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }
bak="Makefile.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -f Makefile "$bak"

# Commente toute ligne qui commence par '>' ou par des espaces puis '>' (mais pas \t>)
# (on n'altère donc pas une ligne de recette valide qui commencerait par une TAB)
tmp="$(mktemp)"
awk '
  BEGIN{fixed=0}
  {
    if ($0 ~ /^[ ]*>/) {            # espaces puis >
      print "# " $0; fixed++
    } else if ($0 ~ /^>/) {         # > en 1ère colonne
      print "# " $0; fixed++
    } else {
      print $0
    }
  }
  END{ printf("fixed_gt=%d\n", fixed) > "/dev/stderr" }
' Makefile > "$tmp"
mv -f "$tmp" Makefile

echo "✅ Lignes '>' hors-recette commentées (backup: $bak)"
