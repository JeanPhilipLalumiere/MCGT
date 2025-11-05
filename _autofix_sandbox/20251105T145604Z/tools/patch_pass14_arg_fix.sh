#!/usr/bin/env bash
# source POSIX copy helper (safe_cp)
. "$(dirname "$0")/lib_posix_cp.sh" 2>/dev/null || . "/home/jplal/MCGT/tools/lib_posix_cp.sh" 2>/dev/null

# Corrige l'appel xargs -> bash -c pour que run_one reçoive bien le fichier en $1
set -Eeuo pipefail

FILE="tools/pass14_smoke_with_mapping.sh"
[[ -f "$FILE" ]] || { echo "[ERREUR] Introuvable: $FILE" >&2; exit 2; }

# Sauvegarde une copie
safe_cp "$FILE" "${FILE}.bak"

# Remplacement ciblé : 'run_one "$0"' -> 'run_one "$1"' _   (avec bash --noprofile --norc -c ...)
# On ne touche qu'à la ligne contenant 'xargs' et 'bash --noprofile --norc -c'
tmp="$(mktemp)"
awk '
  {
    line=$0
    if (line ~ /xargs/ && line ~ /bash[[:space:]]+--noprofile[[:space:]]+--norc[[:space:]]+-c/ && line ~ /run_one[[:space:]]*\"\$0\"/) {
      gsub(/run_one[[:space:]]*\"\$0\"/, "run_one \"$1\"", line)
      # Si pas déjà un placeholder après -c "..." on ajoute " _"
      if (line !~ /-c[[:space:]]*\x27[^ \x27]*\x27[[:space:]]+_([[:space:]]|$)/ && line !~ /-c[[:space:]]*\"[^\"]*\"[[:space:]]+_([[:space:]]|$)/) {
        line = line " _"
      }
    }
    print line
  }
' "$FILE" > "$tmp"

mv "$tmp" "$FILE"
echo "[OK] Patch appliqué. Copie de sauvegarde : ${FILE}.bak"
