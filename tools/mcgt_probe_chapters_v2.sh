#!/usr/bin/env bash
# Fichier: tools/mcgt_probe_chapters_v2.sh
# Objectif : cartographie fine par chapitre (01..10)
#            scripts, données, figures, extraits de manifest.

set -Eeuo pipefail

trap 'code=$?;
echo;
echo "[ERREUR] Le script s est arrêté avec le code $code.";
echo "[ASTUCE] Lecture seule : aucun fichier n a été modifié.";
read -rp "Appuie sur Entrée pour fermer ce script... ";
exit "$code"' ERR

cd "$(dirname "${BASH_SOURCE[0]}")/.." || {
  echo "[ERREUR] Impossible de remonter à la racine du dépôt."
  read -rp "Appuie sur Entrée pour fermer ce script... "
  exit 1
}

echo "=== MCGT: probe chapters v2 (01..10) ==="
echo "Dossier courant: $(pwd)"
echo

for nn in 01 02 03 04 05 06 07 08 09 10; do
  echo "############################################################"
  echo "### CHAPTER ${nn}"
  echo "############################################################"

  echo
  echo ">>> (A) Scripts Python officiels (zz-scripts/chapter${nn})"
  if [ -d "zz-scripts/chapter${nn}" ]; then
    find "zz-scripts/chapter${nn}" -maxdepth 1 -type f -name '*.py' | sort || true
  else
    echo "zz-scripts/chapter${nn} : [absent]"
  fi
  echo

  echo ">>> (B) Données & méta (zz-data/chapter${nn}, niveau 1)"
  if [ -d "zz-data/chapter${nn}" ]; then
    ls -1 "zz-data/chapter${nn}" || true
  else
    echo "zz-data/chapter${nn} : [absent]"
  fi
  echo

  echo ">>> (C) Figures (zz-figures/chapter${nn}, niveau 1)"
  if [ -d "zz-figures/chapter${nn}" ]; then
    ls -1 "zz-figures/chapter${nn}" || true
  else
    echo "zz-figures/chapter${nn} : [absent]"
  fi
  echo

  echo ">>> (D) Sorties intermédiaires (zz-out/chapter${nn}, niveau 1)"
  if [ -d "zz-out/chapter${nn}" ]; then
    ls -1 "zz-out/chapter${nn}" || true
  else
    echo "zz-out/chapter${nn} : [absent]"
  fi
  echo

  echo ">>> (E) Extraits de manifest pour chapter${nn}"
  if [ -f "zz-manifests/manifest_publication.json" ]; then
    echo "-- manifest_publication.json (lignes contenant 'chapter${nn}')"
    grep -n "chapter${nn}" zz-manifests/manifest_publication.json || echo "[aucune entrée]"
    echo
  fi

  if [ -f "zz-manifests/figure_manifest.csv" ]; then
    echo "-- figure_manifest.csv (lignes contenant 'chapter${nn}')"
    grep -n "chapter${nn}" zz-manifests/figure_manifest.csv || echo "[aucune entrée]"
    echo
  fi

  if [ -f "zz-manifests/coverage_fig_scripts_data.csv" ]; then
    echo "-- coverage_fig_scripts_data.csv (lignes contenant 'chapter${nn}')"
    grep -n "chapter${nn}" zz-manifests/coverage_fig_scripts_data.csv || echo "[aucune entrée]"
    echo
  fi

  echo
done

echo
echo "[INFO] mcgt_probe_chapters_v2: extraction terminée (lecture seule)."
read -rp "Appuie sur Entrée pour fermer ce script... "
exit 0
