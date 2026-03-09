#!/usr/bin/env bash
set -Eeuo pipefail

echo "== CH07 – PIPELINE MINIMAL : perturbations-scalaires =="
echo

echo "[1/2] Génération des données..."

# ----------------------------------------------------------------------
# 1) Détection du fichier INI pour les perturbations scalaires
# ----------------------------------------------------------------------
INI_DEFAULT="config/chapter07_scalar_perturbations.ini"
INI_FILE=""

if [ -f "$INI_DEFAULT" ]; then
  INI_FILE="$INI_DEFAULT"
else
  # On cherche quelque chose de raisonnable dans config/
  INI_CANDIDATES=$(ls config/*07*.ini config/*perturb*ini 2>/dev/null || true)
  if [ -n "$INI_CANDIDATES" ]; then
    # On prend le premier par défaut
    INI_FILE=$(printf "%s\n" $INI_CANDIDATES | head -n 1)
  fi
fi

if [ -z "$INI_FILE" ]; then
  echo "[ERREUR] Aucun fichier INI CH07 trouvé dans config/."
  echo "[ASTUCE] Vérifie config/ et mets à jour INI_DEFAULT dans tools/run_ch07_pipeline_minimal.sh."
  exit 1
fi

EXPORT_RAW="assets/zz-data/07_bao_geometry/07_perturbations_main_data.csv"

echo "[INFO] Utilisation de l'INI : $INI_FILE"
echo "[INFO] Export brut         : $EXPORT_RAW"
echo

# ----------------------------------------------------------------------
# 2) Appel de generate_data_chapter07.py avec les bons arguments
# ----------------------------------------------------------------------
if python scripts/07_bao_geometry/generate_data_chapter07.py \
        -i "$INI_FILE" \
        --export-raw "$EXPORT_RAW" \
        --export-2d \
        --n-k 128 \
        --n-a 256; then
  echo "✅ Génération Chapter 7 OK"
else
  code=$?
  echo "[ERREUR] CH07 pipeline interrompu (code $code)"
  echo "[ASTUCE] Vérifie le log ci-dessus pour identifier l'étape qui a échoué."
  exit "$code"
fi

echo
echo "[2/2] Génération des figures..."

for script in \
  scripts/07_bao_geometry/plot_fig01_cs2_heatmap.py \
  scripts/07_bao_geometry/plot_fig02_delta_phi_heatmap.py \
  scripts/07_bao_geometry/plot_fig03_invariant_i1.py \
  scripts/07_bao_geometry/plot_fig04_dcs2_vs_k.py \
  scripts/07_bao_geometry/plot_fig05_ddelta_phi_vs_k.py \
  scripts/07_bao_geometry/plot_fig06_comparison.py \
  scripts/07_bao_geometry/plot_fig07_invariant_i2.py
do
  echo "[INFO] Exécution de $script"
  python "$script"
done

echo
echo "[OK] CH07 pipeline minimal terminé sans erreur."
