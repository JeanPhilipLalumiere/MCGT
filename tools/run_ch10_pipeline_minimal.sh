#!/usr/bin/env bash
# NOTE : ce pipeline minimal CH10 utilise generate_data_chapter10.py (générateur jouet)
# pour produire 10_results_global_scan.csv, afin de tester rapidement la chaîne de
# figures 10-01…10-07. Le pipeline scientifique complet (generer_donnees_chapitre10.py)
# sera branché séparément.

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "== CH10 – PIPELINE MINIMAL : exploration-globale =="

echo
echo "[1/2] Génération des données..."
data_script="scripts/10_global_scan/generate_data_chapter10.py"
results_csv="assets/zz-data/chapter10/10_results_global_scan.csv"
echo "[INFO] Utilisation du script de données : ${data_script}"
echo "[INFO] Fichier de résultats : ${results_csv}"

python "${data_script}" --out-results "${results_csv}"

echo
echo "[2/2] Génération des figures..."

scripts=(scripts/10_global_scan/plot_fig*.py)
echo "[INFO] Scripts de figures détectés :"
for s in "${scripts[@]}"; do
  echo "  - ${s}"
done

for script in "${scripts[@]}"; do
  echo "[INFO] Exécution de ${script}"
  base=$(basename "${script}")
  case "${base}" in
    plot_fig03b_bootstrap_coverage_vs_n.py)
      python "${script}" \
        --results "${results_csv}" \
        --out "assets/zz-figures/chapter10/10_fig_03_b_bootstrap_coverage_vs_n.png"
      ;;
    *)
      python "${script}"
      ;;
  esac
done

echo
echo "[OK] CH10 pipeline minimal terminé sans erreur."
