#!/usr/bin/env bash
set -euo pipefail
[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }
cp -f Makefile "Makefile.bak.$(date -u +%Y%m%dT%H%M%SZ)"

awk '
  BEGIN{in_recipe=0}
  # début de règle: "target: ..." (exclut les lignes .PHONY etc. -> on les laisse telles quelles)
  /^[A-Za-z0-9_.%-]+ *:/{in_recipe=1; print; next}
  # lignes vides : on sort du bloc recette
  /^\s*$/ {in_recipe=0; print; next}
  # commentaires: on n\'y touche pas
  /^\s*#/ {print; next}
  {
    if (in_recipe) {
      # si la ligne commence par des espaces (pas tab), on remplace le bloc d\'espaces de tête par une tabulation
      if ($0 ~ /^[ ]+/) { sub(/^[ ]+/, "\t") }
      print
    } else {
      print
    }
  }
' Makefile > Makefile.__fixed__

mv -f Makefile.__fixed__ Makefile
echo "✅ Makefile corrigé (tabs de recette). Backup: $(ls -1t Makefile.bak.* | head -1)"
