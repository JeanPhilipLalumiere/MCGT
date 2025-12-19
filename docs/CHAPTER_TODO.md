# MCGT – TODO par chapitre (manifests & artefacts)

> NOTE : document auto-généré à partir de `_tmp/`. Ne pas éditer à la main.

Ce fichier liste, par chapitre, les fichiers à trier avant la publication : soit à intégrer au `manifest_publication.json`, soit à déplacer dans `attic/`, soit à supprimer.

## Vue globale

### Gaps de manifest (CHAPTER_MANIFEST_GAPS.md)

```text
# Gaps manifest ↔ filesystem par chapitre

_Généré automatiquement, ne pas éditer à la main._

## Chapitre 1 — chapter_manifest_01.json

Section résolue (2025-12-03) : les metas et le guide existent dans le filesystem et sont couverts par les manifests globaux.

- `zz-data/chapter01/01_P_vs_T.meta.json`
- `zz-data/chapter01/01_optimized_data.meta.json`
- `01-introduction-applications/CHAPTER1_GUIDE.txt`

Aucun gap restant spécifique au chapitre 01.

## Chapitre 2 — chapter_manifest_02.json

Section résolue (2025-12-04) : les fichiers de données d’entrée, figures, metas, scripts
et le guide du chapitre 02 existent dans le filesystem et sont couverts par les
manifests globaux (`manifest_publication.json` et `manifest_master.json`).

Aucun gap restant spécifique au chapitre 02.

## Chapitre 3 — chapter_manifest_03.json

Section résolue (2025-12-04) : les fichiers de données d’entrée, figures, metas,
scripts et le guide du chapitre 03 existent dans le filesystem et sont couverts
par les manifests globaux (`manifest_publication.json` et `manifest_master.json`).

Aucun gap restant spécifique au chapitre 03.

## Chapitre 4 — chapter_manifest_04.json

Section résolue (2025-12-04) : les fichiers de données d’entrée, figures, metas,
scripts et le guide du chapitre 04 existent dans le filesystem et sont couverts
par les manifests globaux (`manifest_publication.json` et `manifest_master.json`).

Aucun gap restant spécifique au chapitre 04.

## Chapitre 5 — chapter_manifest_05.json

- **files.data_inputs** (3 manquants)
  - `zz-data/chapter05/05_bbn_chi2_vs_T.csv`
  - `zz-data/chapter05/05_bbn_parameters.json`
  - `zz-data/chapter05/05_chi2_derivative.csv`

- **files.figures** (4 manquants)
  - `zz-figures/chapter05/05_fig_01_bbn_reaction_network.png`
  - `zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png`
  - `zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png`
  - `zz-figures/chapter05/05_fig_04_chi2_vs_T.png`

- **files.metas** (1 manquants)
  - `zz-data/chapter05/05_bbn_chi2_vs_T.meta.json`

- **files.others** (1 manquants)
  - `05-nucleosynthese-primordiale/CHAPTER5_GUIDE.txt`

- **scripts** (1 manquants)
  - `zz-scripts/chapter05/generate_chapter5_data.py`

## Chapitre 6 — chapter_manifest_06.json

- **files.data_inputs** (2 manquants)
  - `zz-data/chapter06/06_cmb_chi2_scan2d.csv`
  - `zz-data/chapter06/06_delta_rs_full_scan.csv`

- **files.figures** (5 manquants)
  - `zz-figures/chapter06/06_fig_01_cmb_dataflow_diagram.png`
  - `zz-figures/chapter06/06_fig_02_cls_lcdm_vs_mcgt.png`
  - `zz-figures/chapter06/06_fig_03_delta_cls_rel.png`
  - `zz-figures/chapter06/06_fig_04_delta_rs_vs_params.png`
  - `zz-figures/chapter06/06_fig_05_heatmap_delta_chi2.png`

- **files.metas** (1 manquants)
  - `zz-data/chapter06/06_cmb_full_results.meta.json`

- **files.others** (1 manquants)
  - `06-rayonnement-cmb/CHAPTER6_GUIDE.txt`

- **paths.configs** (1 manquants)
  - `zz-configuration/camb_plateau_exact.ini`

- **scripts** (3 manquants)
  - `zz-scripts/chapter06/generate_chapter6_data.py`
  - `zz-scripts/chapter06/10_fig03_delta_cls_rel.py`
  - `zz-scripts/chapter06/10_fig05_heatmap_delta_chi2.py`

## Chapitre 7 — chapter_manifest_07.json

- **files.data_inputs** (3 manquants)
  - `zz-data/chapter07/07_main_scalar_perturbations_data.csv`
  - `zz-data/chapter07/07_scalar_perturbations_meta.json`
  - `zz-data/chapter07/07_scalar_perturbations_params.json`

- **files.figures** (7 manquants)
  - `zz-figures/chapter07/07_fig_01_heatmap_cs2_k_a.png`
  - `zz-figures/chapter07/07_fig_02_heatmap_delta_phi_k_a.png`
  - `zz-figures/chapter07/07_fig_03_invariant_I1.png`
  - `zz-figures/chapter07/07_fig_04_dcs2_dk_vs_k.png`
  - `zz-figures/chapter07/07_fig_05_ddelta_phi_dk_vs_k.png`
  - `zz-figures/chapter07/07_fig_06_comparison.png`
  - `zz-figures/chapter07/07_fig_07_invariant_I2.png`

- **files.metas** (1 manquants)
  - `zz-data/chapter07/07_perturbations_domain.meta.json`

- **files.others** (1 manquants)
  - `07-perturbations-scalaires/CHAPTER7_GUIDE.txt`

- **scripts** (4 manquants)
  - `zz-scripts/chapter07/generate_chapter7_data.py`
  - `zz-scripts/chapter07/10_fig01_heatmap_cs2.py`
  - `zz-scripts/chapter07/10_fig02_heatmap_delta_phi.py`
  - `zz-scripts/chapter07/10_fig03_invariant_I1.py`

## Chapitre 8 — chapter_manifest_08.json

- **files.data_inputs** (5 manquants)
  - `zz-data/chapter08/08_chi2_scan2d.csv`
  - `zz-data/chapter08/08_dv_theory_vs_q0star.csv`
  - `zz-data/chapter08/08_dv_theory_vs_z.csv`
  - `zz-data/chapter08/08_mu_theory_vs_q0star.csv`
  - `zz-data/chapter08/08_mu_theory_vs_z.csv`

- **files.figures** (7 manquants)
  - `zz-figures/chapter08/08_fig_01_chi2_total_vs_q0.png`
  - `zz-figures/chapter08/08_fig_02_dv_vs_z.png`
  - `zz-figures/chapter08/08_fig_03_mu_vs_z.png`
  - `zz-figures/chapter08/08_fig_04_heatmap_chi2.png`
  - `zz-figures/chapter08/08_fig_05_residuals.png`
  - `zz-figures/chapter08/08_fig_06_pulls.png`
  - `zz-figures/chapter08/08_fig_07_chi2_profile.png`

- **files.metas** (1 manquants)
  - `zz-data/chapter08/08_chi2_scan2d.meta.json`

- **files.others** (1 manquants)
  - `08-couplage-sombre/CHAPTER8_GUIDE.txt`

- **scripts** (2 manquants)
  - `zz-scripts/chapter08/generate_chapter8_data.py`
  - `zz-scripts/chapter08/10_fig04_heatmap_chi2.py`

## Chapitre 9 — chapter_manifest_09.json

- **files.data_inputs** (1 manquants)
  - `zz-data/chapter09/09_phase_difference.csv`

- **files.figures** (5 manquants)
  - `zz-figures/chapter09/09_fig_01_phase_overlay.png`
  - `zz-figures/chapter09/09_fig_02_residual_phase.png`
  - `zz-figures/chapter09/09_fig_03_hist_abs_dphi_20_300.png`
  - `zz-figures/chapter09/09_fig_04_milestones_abs_dphi_vs_f.png`
  - `zz-figures/chapter09/09_fig_05_scatter_phi_at_fpeak.png`

- **files.metas** (1 manquants)
  - `zz-data/chapter09/09_metrics_phase.meta.json`

- **files.others** (1 manquants)
  - `09-phase-ondes-gravitationnelles/CHAPTER9_GUIDE.txt`

- **scripts** (3 manquants)
  - `zz-scripts/chapter09/generate_chapter9_data.py`
  - `zz-scripts/chapter09/10_fig03_hist_abs_dphi_20_300.py`
  - `zz-scripts/chapter09/10_fig04_milestones_abs_dphi_vs_f.py`

## Chapitre 10 — chapter_manifest_10.json

- **files.metas** (2 manquants)
  - `zz-data/chapter10/10_mc_best.meta.json`
  - `zz-data/chapter10/10_mc_results.meta.json`

- **scripts** (1 manquants)
  - `zz-scripts/chapter10/generate_chapter10_data.py`
```

### Figures à reconstruire (FIGURES_REBUILD_LATER_TODO.md)

```text
# Figures REBUILD_LATER – snapshot

_Généré le 2025-11-21T15:16:18Z_

## chapter07

- **fig_03_invariant_i1**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./zz-scripts/chapter07/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

- **fig_06_comparison**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./zz-scripts/chapter07/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

- **fig_07_invariant_i2**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./zz-scripts/chapter07/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

## chapter09

- **fig_01_phase_overlay**  — decision=`REBUILD_LATER`
  - issue      : `MANIFEST_COVERAGE_NO_PNG`
  - path_hint  : `zz-figures/chapter09/09_fig_01_phase_overlay.png`
  - scripts_dir: `./zz-scripts/chapter09/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

- **fig_02_residual_phase**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./zz-scripts/chapter09/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)

- **fig_05_scatter_phi_at_fpeak**  — decision=`REBUILD_LATER`
  - issue      : `COVERAGE_ONLY`
  - scripts_dir: `./zz-scripts/chapter09/`
  - comment    : auto: REBUILD_LATER (figure avec script; PNG/figure_manifest à régénérer avant publication)
```

---

## Chapitre 01

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 01).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-data/chapter01/01_P_derivative_initial.csv`
- [ ] `zz-data/chapter01/01_P_derivative_optimized.csv`
- [ ] `zz-data/chapter01/01_P_vs_T.dat`
- [ ] `zz-data/chapter01/01_dimensionless_invariants.csv`
- [ ] `zz-data/chapter01/01_initial_grid_data.dat`
- [ ] `zz-data/chapter01/01_optimized_data.csv`
- [ ] `zz-data/chapter01/01_optimized_data_and_derivatives.csv`
- [ ] `zz-data/chapter01/01_optimized_grid_data.dat`
- [ ] `zz-data/chapter01/01_relative_error_timeline.csv`
- [ ] `zz-data/chapter01/01_timeline_milestones.csv`

---

## Chapitre 02

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 02).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-data/chapter02/02_As_ns_vs_alpha.csv`
- [ ] `zz-data/chapter02/02_FG_series.csv`
- [ ] `zz-data/chapter02/02_P_R_sampling.csv`
- [ ] `zz-data/chapter02/02_P_derivative_data.dat`
- [ ] `zz-data/chapter02/02_P_vs_T_grid_data.dat`
- [ ] `zz-data/chapter02/02_milestones_meta.csv`
- [ ] `zz-data/chapter02/02_optimal_parameters.json`
- [ ] `zz-data/chapter02/02_primordial_spectrum_spec.json`
- [ ] `zz-data/chapter02/02_relative_error_timeline.csv`
- [ ] `zz-data/chapter02/02_timeline_milestones.csv`

---

## Chapitre 03

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 03).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-data/chapter03/03_fR_stability_boundary.csv`
- [ ] `zz-data/chapter03/03_fR_stability_data.csv`
- [ ] `zz-data/chapter03/03_fR_stability_domain.csv`
- [ ] `zz-data/chapter03/03_fR_stability_meta.json`
- [ ] `zz-data/chapter03/03_meta_stability_fR.json`
- [ ] `zz-data/chapter03/03_ricci_fR_milestones.csv`
- [ ] `zz-data/chapter03/03_ricci_fR_vs_T.csv`
- [ ] `zz-data/chapter03/03_ricci_fR_vs_z.csv`
- [ ] `zz-data/chapter03/placeholder.csv`

---

## Chapitre 04

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 04).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-data/chapter04/04_P_vs_T.dat`
- [ ] `zz-data/chapter04/04_dimensionless_invariants.csv`
- [ ] `zz-figures/chapter04/04_fig_01_invariants_schematic.png`
- [ ] `zz-figures/chapter04/04_fig_03_invariants_vs_t.png`

---

## Chapitre 05

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 05).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-data/chapter05/05_bbn_data.csv`
- [ ] `zz-data/chapter05/05_bbn_grid.csv`
- [ ] `zz-data/chapter05/05_bbn_invariants.csv`
- [ ] `zz-data/chapter05/05_bbn_milestones.csv`
- [ ] `zz-data/chapter05/05_bbn_params.json`
- [ ] `zz-data/chapter05/05_chi2_bbn_vs_T.csv`
- [ ] `zz-data/chapter05/05_dchi2_vs_T.csv`
- [ ] `zz-figures/chapter05/05_fig_01_bbn_reaction_network.png`
- [ ] `zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png`

---

## Chapitre 06

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 06).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-data/chapter06/01_P_vs_T.dat`
- [ ] `zz-data/chapter06/06_alpha_evolution.csv`
- [ ] `zz-data/chapter06/06_cls_spectrum.dat`
- [ ] `zz-data/chapter06/06_cls_spectrum_lcdm.dat`
- [ ] `zz-data/chapter06/06_cmb_chi2_scan2D.csv`
- [ ] `zz-data/chapter06/06_cmb_full_results.csv`
- [ ] `zz-data/chapter06/06_delta_Tm_scan.csv`
- [ ] `zz-data/chapter06/06_delta_cls.csv`
- [ ] `zz-data/chapter06/06_delta_cls_relative.csv`
- [ ] `zz-data/chapter06/06_delta_rs_scan.csv`
- [ ] `zz-data/chapter06/06_delta_rs_scan2D.csv`
- [ ] `zz-data/chapter06/06_delta_rs_scan_full.csv`
- [ ] `zz-data/chapter06/06_hubble_mcgt.dat`
- [ ] `zz-data/chapter06/06_params_cmb.json`

---

## Chapitre 07

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 07).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-data/chapter07/07_cs2_matrix.csv`
- [ ] `zz-data/chapter07/07_cs2_matrix.csv.gz`
- [ ] `zz-data/chapter07/07_dcs2_vs_k.csv`
- [ ] `zz-data/chapter07/07_ddelta_phi_vs_k.csv`
- [ ] `zz-data/chapter07/07_delta_phi_matrix.csv`
- [ ] `zz-data/chapter07/07_delta_phi_matrix.csv.gz`
- [ ] `zz-data/chapter07/07_meta_perturbations.json`
- [ ] `zz-data/chapter07/07_params_perturbations.json`
- [ ] `zz-data/chapter07/07_perturbations_boundary.csv`
- [ ] `zz-data/chapter07/07_perturbations_domain.csv`
- [ ] `zz-data/chapter07/07_perturbations_main_data.csv`
- [ ] `zz-data/chapter07/07_perturbations_meta.json`
- [ ] `zz-data/chapter07/07_perturbations_params.json`
- [ ] `zz-data/chapter07/07_phase_run.csv`
- [ ] `zz-data/chapter07/07_scalar_invariants.csv`
- [ ] `zz-data/chapter07/07_scalar_perturbations_results.csv`
- [ ] `zz-data/chapter07/placeholder.csv`

---

## Chapitre 08

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 08).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-data/chapter08/08_bao_data.csv`
- [ ] `zz-data/chapter08/08_chi2_derivative.csv`
- [ ] `zz-data/chapter08/08_chi2_scan2D.csv`
- [ ] `zz-data/chapter08/08_chi2_scan2D.csv.gz`
- [ ] `zz-data/chapter08/08_chi2_total_vs_q0.csv`
- [ ] `zz-data/chapter08/08_coupling_milestones.csv`
- [ ] `zz-data/chapter08/08_coupling_params.json`
- [ ] `zz-data/chapter08/08_dv_theory_q0star.csv`
- [ ] `zz-data/chapter08/08_dv_theory_z.csv`
- [ ] `zz-data/chapter08/08_mu_theory_q0star.csv`
- [ ] `zz-data/chapter08/08_mu_theory_z.csv`
- [ ] `zz-data/chapter08/08_pantheon_data.csv`

---

## Chapitre 09

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 09).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-figures/chapter09/09_fig_01_phase_overlay.png`

---

## Chapitre 10

Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre 10).

### Fichiers présents dans le FS mais absents de `manifest_publication.json`

Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, ou (c) supprimer si redondant.

- [ ] `zz-data/chapter10/10_mc_results.agg.csv.gz`
- [ ] `zz-data/chapter10/10_mc_results.circ.agg.csv.gz`
- [ ] `zz-data/chapter10/10_mc_results.circ.csv.gz`
- [ ] `zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz`
- [ ] `zz-data/chapter10/10_mc_results.csv.gz`
- [ ] `zz-data/chapter10/dummy_results.csv`

---
