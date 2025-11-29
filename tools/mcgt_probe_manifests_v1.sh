#!/usr/bin/env bash
# Fichier : tools/mcgt_probe_manifests_v1.sh
# Objectif : extraire un aperçu des manifests globaux (master, publication, report, figures).
# Mode : lecture seule.

set -Eeuo pipefail

trap 'code=$?;
echo;
echo "[ERREUR] Le script s est arrêté avec le code $code.";
echo "[ASTUCE] Lecture seule : aucun manifest n a été modifié.";
read -rp "Appuie sur Entrée pour fermer ce script... ";
exit "$code"' ERR

cd "$(dirname "${BASH_SOURCE[0]}")/.." || {
  echo "[ERREUR] Impossible de remonter à la racine du dépôt."
  read -rp "Appuie sur Entrée pour fermer ce script... "
  exit 1
}

echo "=== MCGT: probe manifests v1 ==="
echo "Dossier courant: $(pwd)"
echo

if [ -d "zz-manifests" ]; then
  echo "### (1) Contenu de zz-manifests/ (niveau 1)"
  ls -1 zz-manifests
  echo
else
  echo "[ERREUR] Dossier zz-manifests absent."
  read -rp "Appuie sur Entrée pour fermer ce script... "
  exit 1
fi

show_head_tail () {
  local label="$1"
  local path="$2"
  local n="${3:-40}"
  if [ -f "$path" ]; then
    echo "---- $label : $path (premières $n lignes) ----"
    head -n "$n" "$path"
    echo
    echo "---- $label : $path (dernières $n lignes) ----"
    tail -n "$n" "$path"
    echo
  else
    echo "---- $label : $path [absent] ----"
    echo
  fi
}

show_head_tail "manifest_master" "zz-manifests/manifest_master.json" 40
show_head_tail "manifest_publication" "zz-manifests/manifest_publication.json" 40
show_head_tail "manifest_report_md" "zz-manifests/manifest_report.md" 40
show_head_tail "manifest_report_json" "zz-manifests/manifest_report.json" 40
show_head_tail "README_manifest" "zz-manifests/README_manifest.md" 40

show_head_tail "figure_manifest_csv" "zz-manifests/figure_manifest.csv" 40
show_head_tail "coverage_fig_scripts_data_csv" "zz-manifests/coverage_fig_scripts_data.csv" 40

echo
echo "[INFO] mcgt_probe_manifests_v1: extraction terminée (lecture seule)."
read -rp "Appuie sur Entrée pour fermer ce script... "
exit 0
