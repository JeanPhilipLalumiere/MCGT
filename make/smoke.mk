.PHONY: smoke-all smoke-ch09 smoke-ch10
smoke-all: smoke-ch09 smoke-ch10

smoke-ch09:
	@echo "[SMOKE ch09] Figure minimale (milestones phase)"
	python scripts/09_dark_energy_cpl/09_fig_04_absdphi_milestones_vs_f.py --log-level WARNING
	[ -f assets/zz-figures/09_dark_energy_cpl/09_fig_04_absdphi_milestones_vs_f.png ] && echo "[OK] 09_fig_04_absdphi_milestones_vs_f.png"

smoke-ch10:
	@echo "[SMOKE ch10] Génération minimale (sans backends GW lourds)"
	@mkdir -p _tmp/smoke_ch10
	python scripts/10_global_scan/generate_data_chapter10.py \
	  --n 64 \
	  --batch 32 \
	  --n-workers 1 \
	  --skip-metrics \
	  --skip-jalons \
	  --skip-aggregate \
	  --overwrite \
	  --config assets/zz-data/10_global_scan/10_mc_config.json \
	  --samples-csv _tmp/smoke_ch10/10_mc_samples.csv \
	  --results-csv _tmp/smoke_ch10/10_mc_results.csv \
	  --results-agg-csv _tmp/smoke_ch10/10_mc_results.agg.csv \
	  --best-json _tmp/smoke_ch10/10_mc_best.json \
	  --summary _tmp/smoke_ch10/10_pipeline_summary.json
	[ -f _tmp/smoke_ch10/10_mc_samples.csv ] && echo "[OK] _tmp/smoke_ch10/10_mc_samples.csv"

# ch09 : wrapper sans warnings
.PHONY: smoke-ch09-nowarn
smoke-ch09-nowarn:
	@bash scripts/09_dark_energy_cpl/run_fig01_nowarn.sh
