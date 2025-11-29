#!/usr/bin/env bash
# Fichier: tools/mcgt_probe_tree_v2.sh
# Objectif : extraire une vue d'ensemble structurée de l'arborescence MCGT
#            (sans lister chaque fichier de data/figures, seulement les dossiers clés).

set -Eeuo pipefail

trap 'code=$?;
echo;
echo "[ERREUR] Le script s est arrêté avec le code $code.";
echo "[ASTUCE] Rien n a été modifié; le script ne fait que lire l arborescence.";
read -rp "Appuie sur Entrée pour fermer ce script... ";
exit "$code"' ERR

# Se placer à la racine du dépôt (dossier parent de tools/)
cd "$(dirname "${BASH_SOURCE[0]}")/.." || {
  echo "[ERREUR] Impossible de remonter à la racine du dépôt."
  read -rp "Appuie sur Entrée pour fermer ce script... "
  exit 1
}

echo "=== MCGT: probe tree v2 (vue d ensemble) ==="
echo "Dossier courant: $(pwd)"
echo

echo "### (1) Dossiers racine (profondeur 1)"
find . -maxdepth 1 -mindepth 1 -type d | sort
echo

echo "### (2) Dossiers racine structurants (profondeur 2)"
for d in \
  "mcgt" \
  "zz_tools" "zz-tools" \
  "zz-scripts" "zz-data" "zz-figures" "zz-out" \
  "zz-manifests" "zz-schemas" "zz-configuration" "zz-config" \
  "docs" "make" "tests" "zz-tests" \
  "attic" "_attic_untracked" "_autofix_sandbox" "_tmp" ".ci-out" "_ci-out"
do
  if [ -d "$d" ]; then
    echo "---- $d (profondeur 2) ----"
    find "$d" -maxdepth 2 -mindepth 1 -type d | sort
    echo
  fi
done

echo "### (3) Dossiers de chapitres LaTeX (profondeur 2)"
for d in 0*-*; do
  if [ -d "$d" ]; then
    echo "---- $d ----"
    find "$d" -maxdepth 2 -mindepth 1 -type d | sort
    echo
  fi
done

echo "### (4) Arborescence logique des chapitres (zz-scripts/zz-data/zz-figures/zz-out, profondeur 2)"
for nn in 01 02 03 04 05 06 07 08 09 10; do
  echo "---- Chapter ${nn} ----"
  for base in zz-scripts zz-data zz-figures zz-out; do
    path="${base}/chapter${nn}"
    if [ -d "$path" ]; then
      echo "  ${path}/ (profondeur 2)"
      find "$path" -maxdepth 2 -mindepth 1 -type d | sort | sed 's/^/    /'
    else
      echo "  ${path}/ : [absent]"
    fi
  done
  echo
done

echo "### (5) Dossiers d attic / sauvegardes (niveau 2)"
for d in attic _attic_untracked _autofix_sandbox _snapshots; do
  if [ -d "$d" ]; then
    echo "---- $d (profondeur 2) ----"
    find "$d" -maxdepth 2 -mindepth 1 -type d | sort
    echo
  fi
done

echo
echo "[INFO] mcgt_probe_tree_v2: extraction terminée (lecture seule)."
read -rp "Appuie sur Entrée pour fermer ce script... "
exit 0
