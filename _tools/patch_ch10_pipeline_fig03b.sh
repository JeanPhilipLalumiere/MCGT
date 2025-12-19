#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

target="_tools/run_ch10_pipeline_minimal.sh"
backup="${target}.bak_$(date -u +%Y%m%dT%H%M%SZ)"

if [[ -f "${target}" ]]; then
  cp "${target}" "${backup}"
  echo "[BACKUP] ${backup} créé"
fi

cat << 'SHEOF' > "${target}"
#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "== CH10 – PIPELINE MINIMAL : exploration-globale =="

echo
echo "[1/2] Génération des données..."
data_script="zz-scripts/chapter10/generate_data_chapter10.py"
results_csv="zz-data/chapter10/10_results_global_scan.csv"
echo "[INFO] Utilisation du script de données : ${data_script}"
echo "[INFO] Fichier de résultats : ${results_csv}"

python "${data_script}" --out-results "${results_csv}"

echo
echo "[2/2] Génération des figures..."

scripts=(zz-scripts/chapter10/plot_fig*.py)
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
        --out "zz-figures/chapter10/10_fig_03_b_bootstrap_coverage_vs_n.png"
      ;;
    *)
      python "${script}"
      ;;
  esac
done

echo
echo "[OK] CH10 pipeline minimal terminé sans erreur."
SHEOF

chmod +x "${target}"
echo "[OK] _tools/run_ch10_pipeline_minimal.sh mis à jour (cas spécial fig03b)."
