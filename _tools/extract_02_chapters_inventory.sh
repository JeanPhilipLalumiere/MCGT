#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Le log complet est visible ci-dessus.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== MCGT – Inventaire par chapitre (zz-data / zz-figures / zz-scripts) =="
echo

for ch in 01 02 03 04 05 06 07 08 09 10; do
  echo "==============================="
  echo "===== CHAPITRE ${ch} ====="
  echo "==============================="
  echo

  for kind in data figures scripts; do
    dir="zz-${kind}/chapter${ch}"
    echo "-- ${dir} --"
    if [ -d "${dir}" ]; then
      # fichiers uniquement, niveau 1
      find "${dir}" -maxdepth 1 -type f | sort
    else
      echo "(dossier absent)"
    fi
    echo
  done

  echo
done

read -rp "Terminé (extract_02_chapters_inventory). Appuie sur Entrée pour revenir au shell..." _
