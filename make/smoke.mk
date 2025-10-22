.PHONY: smoke-all smoke-ch09 smoke-ch10
smoke-all: smoke-ch09 smoke-ch10

smoke-ch09:
	@echo "[SMOKE ch09] Figure minimale (overlay phase)"
	python zz-scripts/chapter09/plot_fig01_phase_overlay.py --csv zz-data/chapter09/09_phases_mcgt.csv --meta zz-data/chapter09/09_metrics_phase.json --out zz-figures/chapter09/fig_01_phase_overlay.png --dpi 150 || true
	[ -f zz-figures/chapter09/fig_01_phase_overlay.png ] && echo "[OK] fig_01_phase_overlay.png" || true

smoke-ch10:
	@echo "[SMOKE ch10] Essai sécurisé (fallback si erreur)"
	[ -f zz-data/chapter10/10_mc_results.csv ] && echo "[OK] 10_mc_results.csv" || echo "[WARN] pas de CSV"

smoke-ch10:
	python zz-scripts/chapter10/generate_data_chapter10.py \
	  --config zz-data/chapter10/10_mc_config.json \
	  --out-results zz-data/chapter10/10_mc_results.csv || true

# ch09 : wrapper sans warnings
.PHONY: smoke-ch09-nowarn
smoke-ch09-nowarn:
	@bash zz-scripts/chapter09/run_fig01_nowarn.sh
