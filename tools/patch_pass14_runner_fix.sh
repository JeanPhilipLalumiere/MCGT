#!/usr/bin/env bash
# tools/patch_pass14_runner_fix.sh — remplace le runner xargs par une boucle null-safe
set -Eeuo pipefail

F=tools/pass14_smoke_with_mapping.sh
[[ -f "$F" ]] || { echo "[ERREUR] Introuvable: $F" >&2; exit 2; }

# sauvegarde
cp -n "$F" "$F.bak" 2>/dev/null || true
command -v dos2unix >/dev/null && dos2unix -k "$F" >/dev/null 2>&1 || true

tmp="$F.tmp"

# Utilise awk via un heredoc *entièrement* quoted pour éviter les problèmes d'échappement.
awk -v sroot_var='$SROOT' '
  BEGIN { repl=0; in_rng=0 }
  {
    # Début du bloc à remplacer
    if ($0 ~ /mapfile[[:space:]]*-t[[:space:]]*FILES/) { in_rng=1; next }
    # Fin du bloc: ligne xargs qui invoque run_one
    if (in_rng && $0 ~ /xargs[[:space:]].*bash[[:space:]].*-c.*run_one/) {
      # Insère notre boucle null-safe
      print "  # === Runner robuste, null-safe, sans xargs ==="
      print "  while IFS= read -r -d \"\" f; do"
      print "    bash --noprofile --norc -c '\''run_one \"$1\"'\'' _ \"$f\""
      print "  done < <( find \"" sroot_var "\"/chapter0{1..9} \"" sroot_var "\"/chapter10 -type f -name \"*.py\" -print0 | sort -z )"
      print "  # ==============================================="
      in_rng=0; repl=1
      next
    }
    # Si on est dans le bloc (entre mapfile et xargs), on saute les lignes
    if (in_rng) { next }
    # Sinon, on recopie la ligne telle quelle
    print
  }
  END { if (!repl) exit 3 }
' "$F" > "$tmp" <<'AWK_END'
AWK_END

rc=$?; if [[ $rc -ne 0 ]]; then
  if [[ $rc -eq 3 ]]; then
    echo "[ERREUR] Bloc xargs introuvable à remplacer (déjà patché ?)" >&2
  else
    echo "[ERREUR] awk a échoué (rc=$rc)" >&2
  fi
  rm -f "$tmp"; exit "$rc"
fi

mv "$tmp" "$F"
chmod +x "$F"
echo "[OK] Runner remplacé par une boucle null-safe. Sauvegarde: $F.bak"
