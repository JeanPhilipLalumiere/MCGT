# MCGT – TODO par chapitre (manifests & artefacts)

> NOTE : document auto-généré à partir de `_tmp/`. Ne pas éditer à la main.

Ce fichier liste, par chapitre, les fichiers à trier avant la publication : soit à intégrer au `manifest_publication.json`, soit à déplacer dans `attic/`, soit à supprimer.

## Vue globale

### Gaps de manifest (CHAPTER_MANIFEST_GAPS.md)

```text
# Gaps manifest ↔ filesystem par chapitre

_Généré automatiquement, ne pas éditer à la main._

## Chapter 1 — chapter_manifest_01.json

Section résolue (2025-12-03) : les metas et le guide existent dans le filesystem et sont couverts par les manifests globaux.

- `assets/zz-data/chapter01/01_P_vs_T.meta.json`
- `assets/zz-data/chapter01/01_optimized_data.meta.json`
- `01-introduction-applications/CHAPTER1_GUIDE.txt`

Aucun gap restant spécifique au chapitre 01.

## Chapter 2 — chapter_manifest_02.json

Section résolue (2025-12-04) : les fichiers de données d’entrée, figures, metas, scripts
et le guide du chapitre 02 existent dans le filesystem et sont couverts par les
manifests globaux (`manifest_publication.json` et `manifest_master.json`).

Aucun gap restant spécifique au chapitre 02.

## Chapter 3 — chapter_manifest_03.json

Section résolue (2025-12-04) : les fichiers de données d’entrée, figures, metas,
scripts et le guide du chapitre 03 existent dans le filesystem et sont couverts
par les manifests globaux (`manifest_publication.json` et `manifest_master.json`).

Aucun gap restant spécifique au chapitre 03.

## Chapter 4 — chapter_manifest_04.json

Section résolue (2025-12-04) : les fichiers de données d’entrée, figures, metas,
scripts et le guide du chapitre 04 existent dans le filesystem et sont couverts
par les manifests globaux (`manifest_publication.json` et `manifest_master.json`).

Aucun gap restant spécifique au chapitre 04.

## Chapter 5 — chapter_manifest_05.json

- **files.data_inputs** (3 manquants)
  - `assets/zz-data/chapter05/05_bbn_chi2_vs_T.csv`
  - `assets/zz-data/chapter05/05_bbn_parameters.json`
  - `assets/zz-data/chapter05/05_chi2_derivative.csv`

- **files.figures** (4 manquants)
  - `assets/zz-figures/chapter05/05_fig_01_bbn_reaction_network.png`
  - `assets/zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png`
  - `assets/zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png`
  - `assets/zz-figures/chapter05/05_fig_04_chi2_vs_T.png`

- **files.metas** (1 manquants)
  - `assets/zz-data/chapter05/05_bbn_chi2_vs_T.meta.json`

- **files.others** (1 manquants)
  - `05-nucleosynthese-primordiale/CHAPTER5_GUIDE.txt`

- **scripts** (1 manquants)
  - `scripts/05_primordial_bbn/generate_chapter5_data.py`

## Chapter 6 — chapter_manifest_06.json

- **files.data_inputs** (2 manquants)
  - `assets/zz-data/chapter06/06_cmb_chi2_scan2d.csv`
  - `assets/zz-data/chapter06/06_delta_rs_full_scan.csv`

- **files.figures** (5 manquants)
  - `assets/zz-figures/chapter06/06_fig_01_cmb_dataflow_diagram.png`
  - `assets/zz-figures/chapter06/06_fig_02_cls_lcdm_vs_mcgt.png`
  - `assets/zz-figures/chapter06/06_fig_03_delta_cls_rel.png`
  - `assets/zz-figures/chapter06/06_fig_04_delta_rs_vs_params.png`
  - `assets/zz-figures/chapter06/06_fig_05_heatmap_delta_chi2.png`

- **files.metas** (1 manquants)
  - `assets/zz-data/chapter06/06_cmb_full_results.meta.json`

- **files.others** (1 manquants)
  - `06-rayonnement-cmb/CHAPTER6_GUIDE.txt`

- **paths.configs** (1 manquants)
  - `config/camb_plateau_exact.ini`

- **scripts** (3 manquants)
  - `scripts/06_early_growth_jwst/generate_chapter6_data.py`
  - `scripts/06_early_growth_jwst/10_fig03_delta_cls_rel.py`
  - `scripts/06_early_growth_jwst/10_fig05_heatmap_delta_chi2.py`

## Chapter 7 — chapter_manifest_07.json

- **files.data_inputs** (3 manquants)
  - `assets/zz-data/chapter07/07_main_scalar_perturbations_data.csv`
  - `assets/zz-data/chapter07/07_scalar_perturbations_meta.json`
  - `assets/zz-data/chapter07/07_scalar_perturbations_params.json`

- **files.figures** (7 manquants)
  - `assets/zz-figures/chapter07/07_fig_01_heatmap_cs2_k_a.png`
  - `assets/zz-figures/chapter07/07_fig_02_heatmap_delta_phi_k_a.png`
  - `assets/zz-figures/chapter07/07_fig_03_invariant_I1.png`
  - `assets/zz-figures/chapter07/07_fig_04_dcs2_dk_vs_k.png`
  - `assets/zz-figures/chapter07/07_fig_05_ddelta_phi_dk_vs_k.png`
  - `assets/zz-figures/chapter07/07_fig_06_comparison.png`
  - `assets/zz-figures/chapter07/07_fig_07_invariant_I2.png`

- **files.metas** (1 manquants)
  - `assets/zz-data/chapter07/07_perturbations_domain.meta.json`

- **files.others** (1 manquants)
  - `07-perturbations-scalaires/CHAPTER7_GUIDE.txt`

- **scripts** (4 manquants)
  - `scripts/07_bao_geometry/generate_chapter7_data.py`
  - `scripts/07_bao_geometry/10_fig01_heatmap_cs2.py`
  - `scripts/07_bao_geometry/10_fig02_heatmap_delta_phi.py`
  - `scripts/07_bao_geometry/10_fig03_invariant_I1.py`

## Chapter 8 — chapter_manifest_08.json

- **files.data_inputs** (5 manquants)
  - `assets/zz-data/chapter08/08_chi2_scan2d.csv`
  - `assets/zz-data/chapter08/08_dv_theory_vs_q0star.csv`
  - `assets/zz-data/chapter08/08_dv_theory_vs_z.csv`
  - `assets/zz-data/chapter08/08_mu_theory_vs_q0star.csv`
  - `assets/zz-data/chapter08/08_mu_theory_vs_z.csv`

- **files.figures** (7 manquants)
  - `assets/zz-figures/chapter08/08_fig_01_chi2_total_vs_q0.png`
  - `assets/zz-figures/chapter08/08_fig_02_dv_vs_z.png`
  - `assets/zz-figures/chapter08/08_fig_03_mu_vs_z.png`
  - `assets/zz-figures/chapter08/08_fig_04_heatmap_chi2.png`
  - `assets/zz-figures/chapter08/08_fig_05_residuals.png`
  - `assets/zz-figures/chapter08/08_fig_06_pulls.png`
  - `assets/zz-figures/chapter08/08_fig_07_chi2_profile.png`

- **files.metas** (1 manquants)
  - `assets/zz-data/chapter08/08_chi2_scan2d.meta.json`

- **files.others** (1 manquants)
  - `08-couplage-sombre/CHAPTER8_GUIDE.txt`

- **scripts** (2 manquants)
  - `scripts/08_sound_horizon/generate_chapter8_data.py`
  - `scripts/08_sound_horizon/10_fig04_heatmap_chi2.py`

## Chapter 9 — chapter_manifest_09.json

- **files.data_inputs** (1 manquants)
  - `assets/zz-data/chapter09/09_phase_difference.csv`

- **files.figures** (5 manquants)
  - `assets/zz-figures/chapter09/09_fig_01_phase_overlay.png`
  - `assets/zz-figures/chapter09/09_fig_02_residual_phase.png`
  - `assets/zz-figures/chapter09/09_fig_03_hist_abs_dphi_20_300.png`
  - `assets/zz-figures/chapter09/09_fig_04_milestones_abs_dphi_vs_f.png`
  - `assets/zz-figures/chapter09/09_fig_05_scatter_phi_at_fpeak.png`

- **files.metas** (1 manquants)
  - `assets/zz-data/chapter09/09_metrics_phase.meta.json`

- **files.others** (1 manquants)
  - `09-phase-ondes-gravitationnelles/CHAPTER9_GUIDE.txt`

- **scripts** (3 manquants)
  - `scripts/09_dark_energy_cpl/generate_chapter9_data.py`
  - `scripts/09_dark_energy_cpl/10_fig03_hist_abs_dphi_20_300.py`
  - `scripts/09_dark_energy_cpl/10_fig04_milestones_abs_dphi_vs_f.py`

## Chapter 10 — chapter_manifest_10.json

- **files.metas** (2 manquants)
  - `assets/zz-data/chapter10/10_mc_best.meta.json`
  - `assets/zz-data/chapter10/10_mc_results.meta.json`

- **scripts** (1 manquants)
  - `scripts/10_global_scan/generate_chapter10_data.py`
```

### Figures à reconstruire (FIGURES_REBUILD_LATER_TODO.md)

```text
# Figures REBUILD_LATER – snapshot

_Généré le 2025-11-21T15:16:18Z_

## chapter07

- **fig_03_invariant_i1**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./scripts/07_bao_geometry/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

- **fig_06_comparison**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./scripts/07_bao_geometry/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

- **fig_07_invariant_i2**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./scripts/07_bao_geometry/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

## chapter09

- **fig_01_phase_overlay**  — decision=`REBUILD_LATER`
  - issue      : `MANIFEST_COVERAGE_NO_PNG`
  - path_hint  : `assets/zz-figures/chapter09/09_fig_01_phase_overlay.png`
  - scripts_dir: `./scripts/09_dark_energy_cpl/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

- **fig_02_residual_phase**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./scripts/09_dark_energy_cpl/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

- **fig_05_scatter_phi_at_fpeak**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./scripts/09_dark_energy_cpl/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)
```

---

## Chapter 01

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 01).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-data/chapter01/01_P_derivative_initial.csv`
- [ ] `assets/zz-data/chapter01/01_P_derivative_optimized.csv`
- [ ] `assets/zz-data/chapter01/01_P_vs_T.dat`
- [ ] `assets/zz-data/chapter01/01_dimensionless_invariants.csv`
- [ ] `assets/zz-data/chapter01/01_initial_grid_data.dat`
- [ ] `assets/zz-data/chapter01/01_optimized_data.csv`
- [ ] `assets/zz-data/chapter01/01_optimized_data_and_derivatives.csv`
- [ ] `assets/zz-data/chapter01/01_optimized_grid_data.dat`
- [ ] `assets/zz-data/chapter01/01_relative_error_timeline.csv`
- [ ] `assets/zz-data/chapter01/01_timeline_milestones.csv`

---

## Chapter 02

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 02).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-data/chapter02/02_As_ns_vs_alpha.csv`
- [ ] `assets/zz-data/chapter02/02_FG_series.csv`
- [ ] `assets/zz-data/chapter02/02_P_R_sampling.csv`
- [ ] `assets/zz-data/chapter02/02_P_derivative_data.dat`
- [ ] `assets/zz-data/chapter02/02_P_vs_T_grid_data.dat`
- [ ] `assets/zz-data/chapter02/02_milestones_meta.csv`
- [ ] `assets/zz-data/chapter02/02_optimal_parameters.json`
- [ ] `assets/zz-data/chapter02/02_primordial_spectrum_spec.json`
- [ ] `assets/zz-data/chapter02/02_relative_error_timeline.csv`
- [ ] `assets/zz-data/chapter02/02_timeline_milestones.csv`

---

## Chapter 03

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 03).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-data/chapter03/03_fR_stability_boundary.csv`
- [ ] `assets/zz-data/chapter03/03_fR_stability_data.csv`
- [ ] `assets/zz-data/chapter03/03_fR_stability_domain.csv`
- [ ] `assets/zz-data/chapter03/03_fR_stability_meta.json`
- [ ] `assets/zz-data/chapter03/03_meta_stability_fR.json`
- [ ] `assets/zz-data/chapter03/03_ricci_fR_milestones.csv`
- [ ] `assets/zz-data/chapter03/03_ricci_fR_vs_T.csv`
- [ ] `assets/zz-data/chapter03/03_ricci_fR_vs_z.csv`
- [ ] `assets/zz-data/chapter03/placeholder.csv`

---

## Chapter 04

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 04).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-data/chapter04/04_P_vs_T.dat`
- [ ] `assets/zz-data/chapter04/04_dimensionless_invariants.csv`
- [ ] `assets/zz-figures/chapter04/04_fig_01_invariants_schematic.png`
- [ ] `assets/zz-figures/chapter04/04_fig_03_invariants_vs_t.png`

---

## Chapter 05

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 05).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-data/chapter05/05_bbn_data.csv`
- [ ] `assets/zz-data/chapter05/05_bbn_grid.csv`
- [ ] `assets/zz-data/chapter05/05_bbn_invariants.csv`
- [ ] `assets/zz-data/chapter05/05_bbn_milestones.csv`
- [ ] `assets/zz-data/chapter05/05_bbn_params.json`
- [ ] `assets/zz-data/chapter05/05_chi2_bbn_vs_T.csv`
- [ ] `assets/zz-data/chapter05/05_dchi2_vs_T.csv`
- [ ] `assets/zz-figures/chapter05/05_fig_01_bbn_reaction_network.png`
- [ ] `assets/zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png`

---

## Chapter 06

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 06).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-data/chapter06/01_P_vs_T.dat`
- [ ] `assets/zz-data/chapter06/06_alpha_evolution.csv`
- [ ] `assets/zz-data/chapter06/06_cls_spectrum.dat`
- [ ] `assets/zz-data/chapter06/06_cls_spectrum_lcdm.dat`
- [ ] `assets/zz-data/chapter06/06_cmb_chi2_scan2D.csv`
- [ ] `assets/zz-data/chapter06/06_cmb_full_results.csv`
- [ ] `assets/zz-data/chapter06/06_delta_Tm_scan.csv`
- [ ] `assets/zz-data/chapter06/06_delta_cls.csv`
- [ ] `assets/zz-data/chapter06/06_delta_cls_relative.csv`
- [ ] `assets/zz-data/chapter06/06_delta_rs_scan.csv`
- [ ] `assets/zz-data/chapter06/06_delta_rs_scan2D.csv`
- [ ] `assets/zz-data/chapter06/06_delta_rs_scan_full.csv`
- [ ] `assets/zz-data/chapter06/06_hubble_mcgt.dat`
- [ ] `assets/zz-data/chapter06/06_params_cmb.json`

---

## Chapter 07

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 07).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-data/chapter07/07_cs2_matrix.csv`
- [ ] `assets/zz-data/chapter07/07_cs2_matrix.csv.gz`
- [ ] `assets/zz-data/chapter07/07_dcs2_vs_k.csv`
- [ ] `assets/zz-data/chapter07/07_ddelta_phi_vs_k.csv`
- [ ] `assets/zz-data/chapter07/07_delta_phi_matrix.csv`
- [ ] `assets/zz-data/chapter07/07_delta_phi_matrix.csv.gz`
- [ ] `assets/zz-data/chapter07/07_meta_perturbations.json`
- [ ] `assets/zz-data/chapter07/07_params_perturbations.json`
- [ ] `assets/zz-data/chapter07/07_perturbations_boundary.csv`
- [ ] `assets/zz-data/chapter07/07_perturbations_domain.csv`
- [ ] `assets/zz-data/chapter07/07_perturbations_main_data.csv`
- [ ] `assets/zz-data/chapter07/07_perturbations_meta.json`
- [ ] `assets/zz-data/chapter07/07_perturbations_params.json`
- [ ] `assets/zz-data/chapter07/07_phase_run.csv`
- [ ] `assets/zz-data/chapter07/07_scalar_invariants.csv`
- [ ] `assets/zz-data/chapter07/07_scalar_perturbations_results.csv`
- [ ] `assets/zz-data/chapter07/placeholder.csv`

---

## Chapter 08

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 08).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-data/chapter08/08_bao_data.csv`
- [ ] `assets/zz-data/chapter08/08_chi2_derivative.csv`
- [ ] `assets/zz-data/chapter08/08_chi2_scan2D.csv`
- [ ] `assets/zz-data/chapter08/08_chi2_scan2D.csv.gz`
- [ ] `assets/zz-data/chapter08/08_chi2_total_vs_q0.csv`
- [ ] `assets/zz-data/chapter08/08_coupling_milestones.csv`
- [ ] `assets/zz-data/chapter08/08_coupling_params.json`
- [ ] `assets/zz-data/chapter08/08_dv_theory_q0star.csv`
- [ ] `assets/zz-data/chapter08/08_dv_theory_z.csv`
- [ ] `assets/zz-data/chapter08/08_mu_theory_q0star.csv`
- [ ] `assets/zz-data/chapter08/08_mu_theory_z.csv`
- [ ] `assets/zz-data/chapter08/08_pantheon_data.csv`

---

## Chapter 09

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 09).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-figures/chapter09/09_fig_01_phase_overlay.png`

---

## Chapter 10

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapter 10).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `assets/zz-data/chapter10/10_mc_results.agg.csv.gz`
- [ ] `assets/zz-data/chapter10/10_mc_results.circ.agg.csv.gz`
- [ ] `assets/zz-data/chapter10/10_mc_results.circ.csv.gz`
- [ ] `assets/zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz`
- [ ] `assets/zz-data/chapter10/10_mc_results.csv.gz`
- [ ] `assets/zz-data/chapter10/dummy_results.csv`

---
