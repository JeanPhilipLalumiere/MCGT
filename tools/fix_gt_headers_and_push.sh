#!/usr/bin/env bash
set -euo pipefail

PAUSE="${PAUSE:-1}"
_pause(){
  # Ne pas fermer la fenêtre : attendre une touche si on est dans un terminal
  if [[ "${PAUSE}" != "0" && -t 0 ]]; then
    echo
    read -r -p "✓ Terminé. Appuie sur Entrée pour fermer ce script..." _
  fi
}
trap _pause EXIT

echo "== Fix ciblé des lignes '>' hors-recette + vérifications =="

# Garde-fou
[ -d .git ] || { echo "❌ Lance ce script à la racine du dépôt (.git/)."; exit 2; }
[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }
echo "• Branche: $(git rev-parse --abbrev-ref HEAD)"

# Backup
bak="Makefile.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -f Makefile "$bak"

# Commente les lignes qui commencent par '>' ou '   >' (mais pas celles qui commencent par TAB)
tmp="$(mktemp)"
fixed=0
awk '
  {
    if ($0 ~ /^[ ]*>/ ) {          # espaces puis >
      print "# " $0; fixed++
    } else if ($0 ~ /^>/ ) {       # > en première colonne
      print "# " $0; fixed++
    } else {
      print $0
    }
  }
  END { printf("fixed_gt=%d\n", fixed) > "/dev/stderr" }
' Makefile > "$tmp"
mv -f "$tmp" Makefile

echo "✅ Lignes '>' hors-recette commentées (backup: $bak)"

# Affiche un petit contexte (lignes 68..80) avec ^I pour les TAB
echo "— Contexte Makefile lignes 68..80 (TAB = ^I) —"
nl -ba -w3 -s': ' Makefile | sed -n '68,80p' | sed -e 's/\t/^I/g' -e 's/$/$/'

# Dry-run make
echo "— make -n —"
log="$(mktemp)"
if make -n >"$log" 2>&1; then
  echo "✅ make -n: OK"
else
  echo "⚠️  make -n a signalé des erreurs:"
  grep -n "Makefile:[0-9]\+:" "$log" | sed 's/^/  /' || true
  # Contexte pour chaque ligne fautive
  while read -r hit; do
    ln="${hit#Makefile:}"; ln="${ln%%:*}"
    echo "----- contexte autour de la ligne $ln -----"
    nl -ba -w3 -s': ' Makefile | sed -n "$((ln-4)),$((ln+4))p" | sed -e 's/\t/^I/g' -e 's/$/$/'
  done < <(grep -o "Makefile:[0-9]\+:" "$log" | sort -u || true)
  echo "Journal complet: $log"
  exit 3
fi

# Push automatisé si disponible
if [ -x tools/push_all.sh ]; then
  tools/push_all.sh
else
  echo "ℹ️  tools/push_all.sh non trouvé — étape push/skippée."
fi
