# Reproduction minimale (MCGT v0.3.3)

> Deux commandes pour valider rapidement la publication (ch09 & ch10).

## 1) Chapter 09 — figure minimale (overlay phase)
```bash
python scripts/09_dark_energy_cpl/10_fig01_phase_overlay.py   --csv assets/zz-data/chapter09/09_phases_mcgt.csv   --meta assets/zz-data/chapter09/09_metrics_phase.json   --out assets/zz-figures/chapter09/09_fig_01_phase_overlay.png   --dpi 150
```
Sortie attendue : `assets/zz-figures/chapter09/09_fig_01_phase_overlay.png`.

## 2) Chapter 10 — générateur officiel (CSV)
```bash
python scripts/10_global_scan/generate_data_chapter10.py   --config assets/zz-data/chapter10/10_mc_config.json   --out-results assets/zz-data/chapter10/10_mc_results.csv
```
Sortie attendue : `assets/zz-data/chapter10/10_mc_results.csv` (en-têtes : `sample_id,q,m1,m2,fpeak_hz,phi_at_fpeak_rad,p95_rad`).

**Raccourcis Make (si dispos)**
- `make -f Makefile -f make/smoke.mk smoke-ch09`
- `make -f Makefile -f make/smoke.mk smoke-ch10`

### Astuce : exécution sans warning (ch09)
Pour éviter le message de warning lors de la lecture du méta JSON, vous pouvez utiliser le wrapper :
```bash
bash scripts/09_dark_energy_cpl/run_fig01_nowarn.sh
```
