# repo_write_readme_repro_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/mcgt_readme_repro_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'echo; echo "[GUARD] Fin (exit=$?) — log: $LOG"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; BR="$(git rev-parse --abbrev-ref HEAD)"; echo "$BR"
[ "$BR" = "fix/ch09-fig03-parse" ] || echo "[WARN] Branche=$BR (attendu: fix/ch09-fig03-parse)"

cat > README-REPRO.md <<'MD'
# Reproduction Round-2 (MCGT)

Cette note décrit **comment régénérer exactement** les figures de Round-2 et vérifier l’état attendu (ADD 20/20, REVIEW 16/16).

## Prérequis rapides
- Python 3.10–3.12, `pip install -r zz-scripts/chapter10/requirements.txt`
- Données déjà présentes sous `zz-data/` (dont `.csv.gz`)

## Génération — Chapitre 10
```bash
python zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
  --results zz-data/chapter10/10_mc_results.circ.csv.gz \
  --out zz-figures/chapter10/10_fig_01_iso_p95_maps.png --dpi 150

python zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py \
  --results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz \
  --out zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png --dpi 150

python zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  --results zz-data/chapter10/10_mc_results.circ.csv.gz \
  --out zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png --dpi 150

python zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  --results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz \
  --out zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png --dpi 150

python zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  --results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz \
  --out zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png --dpi 150
