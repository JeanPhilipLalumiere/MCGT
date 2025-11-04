#!/usr/bin/env bash
set -euo pipefail

FAIL_LIST="zz-out/homog_cli_fail_list.txt"
[[ -s "$FAIL_LIST" ]] || { echo "[PASS6-REM] Pas de fail list. Lance tools/homog_pass4_cli_inventory_safe_v4.sh d'abord."; exit 1; }

echo "[PASS6-REM] Analyse des FAIL restants par chapitre…"
# Extraire les chapitres (02, 07, 10, …) présents dans la fail list
mapfile -t CHAPS < <(sed -nE 's@^zz-scripts/chapter([0-9]{2})/.*@\1@p' "$FAIL_LIST" | sort -u)

if [[ ${#CHAPS[@]} -eq 0 ]]; then
  echo "[PASS6-REM] Aucune entrée : tout est déjà vert."
  exit 0
fi

echo "[PASS6-REM] Chapitres encore en échec : ${CHAPS[*]}"
echo
echo "[PASS6-REM] Top 10 des fichiers en échec (aperçu) :"
head -n 10 "$FAIL_LIST" || true
echo

# Stubification en une passe (tous les chapitres détectés)
echo "[PASS6-REM] Stubify automatique des chapitres : ${CHAPS[*]}"
tools/homog_pass6_stubify_range.sh "${CHAPS[@]}"

# Re-scan inventaire en mode sûr
echo "[PASS6-REM] Re-scan (Pass4-SAFE v4)…"
tools/homog_pass4_cli_inventory_safe_v4.sh

echo
echo "=== Résumé (dernières lignes du rapport) ==="
tail -n 12 zz-out/homog_cli_inventory_pass4.txt || true

echo
echo "[PASS6-REM] Fichier de travail : zz-out/homog_cli_fail_list.txt"
