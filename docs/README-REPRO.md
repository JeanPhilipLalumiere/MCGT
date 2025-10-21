# Reproduction minimale (MCGT v0.3.3)

> Deux commandes pour valider rapidement la publication (ch09 & ch10).

## 1) Chapter 09 — figure minimale (overlay phase)
```bash
python zz-scripts/chapter09/plot_fig01_phase_overlay.py   --csv zz-data/chapter09/09_phases_mcgt.csv   --meta zz-data/chapter09/09_metrics_phase.json   --out zz-figures/chapter09/fig_01_phase_overlay.png   --dpi 150
```
Sortie attendue : `zz-figures/chapter09/fig_01_phase_overlay.png`.

## 2) Chapter 10 — générateur officiel (CSV)
```bash
python zz-scripts/chapter10/generate_data_chapter10.py   --config zz-data/chapter10/10_mc_config.json   --out-results zz-data/chapter10/10_mc_results.csv
```
Sortie attendue : `zz-data/chapter10/10_mc_results.csv` (en-têtes : `sample_id,q,m1,m2,fpeak_hz,phi_at_fpeak_rad,p95_rad`).

**Raccourcis Make (si dispos)**
- `make -f Makefile -f make/smoke.mk smoke-ch09`
- `make -f Makefile -f make/smoke.mk smoke-ch10`
