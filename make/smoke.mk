.PHONY: smoke-all smoke-ch09 smoke-ch10

smoke-all: smoke-ch09 smoke-ch10

smoke-ch09:
	@echo "[SMOKE ch09] Prétraitement"
	python zz-scripts/chapter09/generate_data_chapter09.py --ref zz-data/chapter09/09_phases_imrphenom.csv \
	        --out-prepoly zz-data/chapter09/09_phases_mcgt_prepoly.csv \
	        --out-diff zz-data/chapter09/09_phase_diff.csv --log-level INFO || true
	@echo "[SMOKE ch09] Figures minimales"
	python zz-scripts/chapter09/plot_fig01_phase_overlay.py \
	        --csv zz-data/chapter09/09_phases_mcgt.csv --meta zz-data/chapter09/09_metrics_phase.json \
	        --out zz-figures/chapter09/fig_01_phase_overlay.png --dpi 150 || true

smoke-ch10:
	@echo "[SMOKE ch10] Échantillonnage réduit"
	python zz-scripts/chapter10/generate_data_chapter10.py \
	        --config zz-data/chapter10/10_mc_config.json \
	        --out-results zz-data/chapter10/10_mc_results.csv || true
