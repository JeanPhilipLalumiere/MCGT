# TODO_CLEANUP — Plan de nettoyage MCGT

Ce fichier a été généré automatiquement par `tools/mcgt_cleanup_step2_todo.sh`
à partir du scan : `/tmp/mcgt_cleanup_step1_20251128T221208`.

AUCUN fichier n'a encore été supprimé ou déplacé.  
Cette liste sert de base pour les décisions humaines (supprimer / attic / conserver).

---

## 1. Résumé quantitatif du scan

- Fichiers non suivis (untracked) : **1**
- Répertoires techniques "junk" détectés : **119**
- Fichiers "junk" (tmp, bak, logs, etc.) détectés : **772**

---

## 2. Répertoires "junk" à examiner

Source : `/tmp/mcgt_cleanup_step1_20251128T221208/junk_dirs.txt`

> **Action attendue (humaine)** :  
> - Décider quels répertoires peuvent être **supprimés** en toute sécurité  
> - Quels répertoires doivent être **déplacés vers un attic/**  
> - Quels répertoires doivent en fait être **conservés** et éventuellement documentés.

Liste brute :

```text
./.ruff_cache
./__pycache__
./_attic_untracked/help_shim_backup_20251106T192653/scripts/chapter07/tests/__pycache__
./_attic_untracked/help_shim_backup_20251106T192653/scripts/chapter07/utils/__pycache__
./_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_attic_untracked/migrate_staging/20251028T203441Z/tools/dev/__pycache__
./_autofix_sandbox/2025-11-06/_common.bak/__pycache__
./_autofix_sandbox/2025-11-06T122310_benign_glue_backup/chapter07/tests/__pycache__
./_autofix_sandbox/2025-11-06T122310_benign_glue_backup/chapter07/utils/__pycache__
./_autofix_sandbox/2025-11-06T122502_last_glue_fix/__pycache__
./_autofix_sandbox/2025-11-06T122816_last_glue_fix/__pycache__
./_autofix_sandbox/2025-11-06T123144_sentinels_backup/__pycache__
./_autofix_sandbox/2025-11-06T123326_sentinels_backup/__pycache__
./_autofix_sandbox/2025-11-06T123643_sentinels_backup/__pycache__
./_autofix_sandbox/2025-11-06T123659_sentinels_backup/__pycache__
./_autofix_sandbox/20251105T145604Z/__pycache__
./_autofix_sandbox/20251105T145604Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T145604Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/dev/__pycache__
./_autofix_sandbox/20251105T145604Z/mcgt/__pycache__
./_autofix_sandbox/20251105T145604Z/mcgt/backends/__pycache__
./_autofix_sandbox/20251105T145604Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T145604Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/backends/__pycache__
./_autofix_sandbox/20251105T145604Z/release_zenodo_codeonly/v0.3.x/tools/tools/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/__pycache__
./_autofix_sandbox/20251105T145604Z/tests/__pycache__
./_autofix_sandbox/20251105T145604Z/tools/__pycache__
./_autofix_sandbox/20251105T145604Z/assets/zz-manifests/__pycache__
./_autofix_sandbox/20251105T145604Z/assets/zz-schemas/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/_common/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter01/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter02/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter03/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter03/utils/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter04/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter05/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter06/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter07/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter07/tests/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter07/utils/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter08/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter08/utils/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter09/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/chapter10/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/manifesttools/__pycache__
./_autofix_sandbox/20251105T145604Z/tests/__pycache__
./_autofix_sandbox/20251105T145604Z/tools/__pycache__
./_autofix_sandbox/20251105T145604Z/tools/__pycache__
./_autofix_sandbox/20251105T150635Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T150635Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T150635Z/tools/__pycache__
./_autofix_sandbox/20251105T150635Z/assets/zz-manifests/__pycache__
./_autofix_sandbox/20251105T150635Z/assets/zz-schemas/__pycache__
./_autofix_sandbox/20251105T150635Z/tools/__pycache__
./_autofix_sandbox/20251105T150939Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T150939Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T150939Z/tools/__pycache__
./_autofix_sandbox/20251105T150939Z/assets/zz-manifests/__pycache__
./_autofix_sandbox/20251105T150939Z/assets/zz-schemas/__pycache__
./_autofix_sandbox/20251105T150939Z/tools/__pycache__
./_autofix_sandbox/20251105T150942Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T150942Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T150942Z/tools/__pycache__
./_autofix_sandbox/20251105T150942Z/assets/zz-manifests/__pycache__
./_autofix_sandbox/20251105T150942Z/assets/zz-schemas/__pycache__
./_autofix_sandbox/20251105T150942Z/tools/__pycache__
./_autofix_sandbox/20251105T151324Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T151324Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T151324Z/tools/__pycache__
./_autofix_sandbox/20251105T151324Z/assets/zz-manifests/__pycache__
./_autofix_sandbox/20251105T151324Z/assets/zz-schemas/__pycache__
./_autofix_sandbox/20251105T151324Z/tools/__pycache__
./_autofix_sandbox/20251105T151527Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T151527Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T151527Z/tools/__pycache__
./_autofix_sandbox/20251105T151527Z/assets/zz-manifests/__pycache__
./_autofix_sandbox/20251105T151527Z/assets/zz-schemas/__pycache__
./_autofix_sandbox/20251105T151527Z/tools/__pycache__
./_autofix_sandbox/20251105T152322Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T152322Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T152322Z/tools/__pycache__
./_autofix_sandbox/20251105T152322Z/assets/zz-manifests/__pycache__
./_autofix_sandbox/20251105T152322Z/assets/zz-schemas/__pycache__
./_autofix_sandbox/20251105T152322Z/tools/__pycache__
./_autofix_sandbox/20251105T152829Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T152829Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T152829Z/tools/__pycache__
./_autofix_sandbox/20251105T152829Z/assets/zz-manifests/__pycache__
./_autofix_sandbox/20251105T152829Z/assets/zz-schemas/__pycache__
./_autofix_sandbox/20251105T152829Z/tools/__pycache__
./attic/safe_runners/__pycache__
./mcgt/__pycache__
./mcgt/backends/__pycache__
./release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./release_zenodo_codeonly/v0.3.x/mcgt/mcgt/backends/__pycache__
./release_zenodo_codeonly/v0.3.x/tools/tools/__pycache__
./scripts/__pycache__
./tests/__pycache__
./tools/__pycache__
./assets/zz-manifests/__pycache__
./assets/zz-schemas/__pycache__
./scripts/_common/__pycache__
./scripts/chapter01/__pycache__
./scripts/chapter02/__pycache__
./scripts/chapter03/__pycache__
./scripts/chapter03/utils/__pycache__
./scripts/chapter04/__pycache__
./scripts/chapter05/__pycache__
./scripts/chapter06/__pycache__
./scripts/chapter07/__pycache__
./scripts/chapter07/tests/__pycache__
./scripts/chapter07/utils/__pycache__
./scripts/chapter08/__pycache__
./scripts/chapter08/utils/__pycache__
./scripts/chapter09/__pycache__
./scripts/chapter10/__pycache__
./scripts/manifesttools/__pycache__
./tests/__pycache__
./tools/__pycache__
./tools/__pycache__
```

---

## 3. Fichiers "junk" les plus volumineux (TOP 50)

Source : `/tmp/mcgt_cleanup_step1_20251128T221208/junk_files_sorted_by_size.txt`  
Format : `<taille_en_octets>  <chemin>`

> **Action attendue (humaine)** :  
> Pour chaque fichier listé ci-dessous :
> - Vérifier s'il s'agit d'un artefact purement temporaire / historique  
> - Si oui, le marquer pour **suppression**  
> - Sinon, envisager un déplacement vers **attic/** ou une meilleure intégration (manifest, doc).

```text
     1684026  ./.ci-out/manifest-guard_19210199668.log
      813575  ./_tmp/guards_logs/manifest-guard.log
      813572  ./_tmp/pr_58_logs_20251114T021551Z/19351620317_manifest-guard.log
      813572  ./_tmp/guards_logs_20251115T151458Z/manifest-guard.log
      813571  ./_tmp/pr_58_logs_20251114T020003Z/19351620317_manifest-guard.log
      813571  ./_tmp/guards_logs_20251115T151336Z/manifest-guard.log
      813571  ./_tmp/guards_logs_20251115T150556Z/manifest-guard.log
      813571  ./_tmp/guards_logs_20251115T150506Z/manifest-guard.log
      813571  ./_tmp/guards_logs_20251115T145657Z/manifest-guard.log
      813569  ./_tmp/pr_58_logs_20251114T020800Z/19351620317_manifest-guard.log
      813564  ./_tmp/pr_58_logs_20251114T021551Z/19352043464_manifest-guard.log
      812215  ./_tmp/pr_58_logs_20251114T021551Z/19351665271_manifest-guard.log
      812214  ./_tmp/pr_58_logs_20251114T020003Z/19351728047_manifest-guard.log
      812211  ./_tmp/pr_58_logs_20251114T021551Z/19351728047_manifest-guard.log
      812211  ./_tmp/pr_58_logs_20251114T020800Z/19351665271_manifest-guard.log
      812209  ./_tmp/pr_58_logs_20251114T020003Z/19351665271_manifest-guard.log
      812207  ./_tmp/pr_58_logs_20251114T020800Z/19351728047_manifest-guard.log
      280768  ./assets/zz-manifests/manifest_master.json.20251121T063556Z.bak
      279847  ./assets/zz-manifests/manifest_master.json.20251122T152226Z.bak
      279845  ./assets/zz-manifests/manifest_master.json.20251122T152705Z.bak
      272740  ./assets/zz-manifests/manifest_master.json.20251122T153232Z.bak
      244826  ./assets/zz-manifests/manifest_master.json.20251122T155427Z.bak
      244690  ./assets/zz-manifests/manifest_master.json.20251121T064206Z.bak
      237972  ./assets/zz-manifests/manifest_master.json.20251128T141647Z.bak
      237971  ./assets/zz-manifests/manifest_master.json.20251122T161418Z.bak
      237970  ./assets/zz-manifests/manifest_master.json.20251122T160125Z.bak
      235421  ./assets/zz-manifests/manifest_master.json.20251121T153534Z.bak
      235421  ./assets/zz-manifests/manifest_master.json.20251121T134742Z.bak
      235420  ./assets/zz-manifests/manifest_master.json.20251121T124657Z.bak
      235420  ./assets/zz-manifests/manifest_master.json.20251121T122250Z.bak
      235420  ./assets/zz-manifests/manifest_master.json.20251121T121009Z.bak
      235419  ./assets/zz-manifests/manifest_master.json.20251121T064453Z.bak
      124267  ./_ci-out/repo_probe_20251108T092528.log
      119565  ./.ci-out/sweep_v2_2025-11-06T125637.log
      118038  ./.ci-out/sweep_v2_2025-11-06T130059.log
      116357  ./.ci-out/sweep_v2_2025-11-06T124509.log
       90192  ./.ci-out/sweep_help_and_smoke_2025-11-06T124251.log
       90037  ./.ci-out/sweep_help_and_smoke_2025-11-06T124010.log
       82626  ./_logs/cleanup_safe_attic_20251029T134449Z.log
       82418  ./.ci-out/sweep_v2_2025-11-06T125106.log
       81966  ./_tmp/audit_run_19156722707.log
       81962  ./_tmp/audit_run_19156998457.log
       81063  ./.ci-out/manifest_guard_JOB_54923000920.log
       81063  ./.ci-out/manifest-guard_19215019681.log
       74315  ./_tmp/trace_guard_all_v2_20251115T151458Z.log
       74124  ./_tmp/pr58_guard_all_20251115T151458Z.log
       73886  ./.ci-out/manifest-guard_19214969330.log
       72045  ./_tmp/trace_guard_all_20251115T150556Z.log
       71854  ./_tmp/pr58_guard_all_20251115T150556Z.log
       65990  ./_logs/stepC_merge_and_protect_20251028T231330Z.log
```

---

## 4. Fichiers non suivis (untracked)

Source : `/tmp/mcgt_cleanup_step1_20251128T221208/untracked_files.txt`

> **Action attendue (humaine)** :  
> - Décider pour chaque fichier s'il doit être :  
>   - **Ajouté au dépôt** (git add + manifest/documentation)  
>   - **Ignoré** (ajout à .gitignore ou équivalent)  
>   - **Supprimé** ou déplacé dans un répertoire d'archives (attic/).

```text
tools/mcgt_cleanup_step1.sh
```

---

## 5. Plan d'action (à remplir à la main)

### 5.1. À supprimer (candidats évidents)

- [ ] ...

### 5.2. À déplacer vers `attic/` (archives historiques)

- [ ] ...

### 5.3. À conserver et documenter (manifests, README, etc.)

- [ ] ...

---

## 6. Notes supplémentaires

- Ce fichier doit rester **humainement éditable** : complète, corrige, et coche les éléments une fois traités.
- Après chaque vague de nettoyage, penser à :  
  - Mettre à jour les manifests (`manifest_master.json`, `manifest_publication.json`)  
  - Adapter `README-REPRO` si nécessaire  
  - Vérifier que la CI et les scripts de repro passent toujours.


## [2025-11-29T16:39:20Z] mcgt_cleanup_pkgmeta_v1
- Déplacé .bkp_pkgmeta_* vers attic/pkgmeta/
- Déplacé tools.egg-info vers attic/generated/ (suffixé par timestamp)

## [2025-11-29T16:46:44Z] mcgt_bump_citation_version_v1
- Version de référence (manifest_master.project.version) : 0.2.99
- CITATION.cff (racine) : champ version mis à jour.
- CITATION.cff (release_zenodo_codeonly/v0.3.x) : champ version mis à jour.

## Step07 – LOW_PRIORITY_DATA (classification et plan)

_Date : 2025-11-30 02:39 UTC_

### Fichiers à considérer comme **données officielles / obligatoires**

- `assets/zz-data/chapter10/dummy_results.csv`
  - Dataset principal (≈1200 lignes, 6 colonnes) pour les figures et analyses du chapitre 10.
  - Colonnes : `m1`, `m2`, `p95_20_300`, `p95_20_300_recalc`, `phi_ref_fpeak`, `phi_mcgt_fpeak`.
  - Utilisé par :
    - `tools/ch10_smoke.sh`
    - `tools/ch10_afterfix.sh`
    - plusieurs scripts `tools/ch10_fix_*.sh`
    - `tools/ch10_patch_and_test.sh`
  - → Statut : **CORE DATA CH10**, ne pas supprimer.

- `assets/zz-data/chapter10/example_results.csv`
  - Petit dataset d'exemple (5 lignes, 6 colonnes) de type GW-A…E.
  - Colonnes : `id`, `event`, `f_Hz`, `phi_mcgt_at_fpeak`, `obs_phase`, `sigma_phase`.
  - Référencé par les diagnostics de publication (`_diag_publication_*.json`) et les manifests.
  - → Statut : **EXAMPLE DATA OFFICIELLE**, à conserver comme jeu d'exemple.

### Fichiers à considérer comme **placeholders structurels** (candidats ménage futur)

- `assets/zz-data/chapter03/placeholder.csv`
- `assets/zz-data/chapter07/placeholder.csv`

Caractéristiques communes :
- Fichiers CSV **vides** (`No columns to parse from file`).
- Référencés dans :
  - plusieurs `_diag_master_*.json`
  - `assets/zz-manifests/manifest_master.json`
  - `assets/zz-manifests/integrity.json`
  - `assets/zz-manifests/master.json`
  - métadonnées locales (`03_meta_stability_fR.json`, `07_meta_perturbations.json`).
- → Statut provisoire :
  - **PLACEHOLDER STRUCTUREL**, sans contenu scientifique.
  - Candidats à suppression ou déplacement dans `attic/data/` après refactor des méta/manifestes.

### Plan futur (à exécuter plus tard)

1. **Phase A – Analyse d'usage des placeholders**
   - Confirmer qu'aucun script de production ne lit réellement ces fichiers CSV.
   - Documenter la fonction précise de `03_meta_stability_fR.json` et `07_meta_perturbations.json`.

2. **Phase B – Refactor méta & manifests**
   - Adapter les JSON de méta pour ne plus dépendre de ces placeholders (ou les remplacer par de vraies données).
   - Mettre à jour :
     - `assets/zz-manifests/manifest_master.json`
     - `assets/zz-manifests/integrity.json`
     - (et snapshot `release_zenodo_codeonly/v0.3.x` si nécessaire).
   - Vérifier que `diag_consistency` reste **sans erreurs**.

3. **Phase C – Ménage**
   - Déplacer les placeholders obsolètes vers `attic/data/chapter03/` et `attic/data/chapter07/`,
     ou les supprimer si plus aucune référence active.
   - Mettre à jour `TODO_CLEANUP.md` en conséquence.

---

## Step11 – FRONT_FILES_PAR_CHAPITRE

_Date : 2025-11-30 03:35 UTC_

Cette section liste, pour chaque chapitre, les fichiers « vitrine » à garder au premier plan
(scripts maîtres, données clés, figures principales). Le reste est considéré comme artefacts
de second niveau (backstage) ou candidats à attic/ à moyen terme.

### CH01 – Invariants thermiques & erreurs relatives

- **Scripts**
  - `scripts/chapter01/generate_data_chapter01.py`
  - `scripts/chapter01/10_fig03_relative_error_timeline.py`

- **Données**
  - `assets/zz-data/chapter01/01_optimized_data.csv`
  - `assets/zz-data/chapter01/01_relative_error_timeline.csv`

- **Figures**
  - `assets/zz-figures/chapter01/01_fig_01_early_plateau.png`
  - `assets/zz-figures/chapter01/01_fig_03_relative_error_timeline.png`


### CH02 – Spectre primordial & calibration

- **Scripts**
  - `scripts/chapter02/generate_data_chapter02.py`
  - `scripts/chapter02/10_fig00_spectrum.py`

- **Données**
  - `assets/zz-data/chapter02/02_primordial_spectrum_spec.json`
  - `assets/zz-data/chapter02/02_As_ns_vs_alpha.csv`

- **Figures**
  - `assets/zz-figures/chapter02/02_fig_00_spectrum.png`
  - `assets/zz-figures/chapter02/02_fig_03_relative_errors.png`


### CH03 – Stabilité f(R) & courbure de Ricci

- **Scripts**
  - `scripts/chapter03/generate_data_chapter03.py`
  - `scripts/chapter03/10_fig01_fR_stability_domain.py`

- **Données**
  - `assets/zz-data/chapter03/03_fR_stability_domain.csv`
  - `assets/zz-data/chapter03/03_ricci_fR_vs_T.csv`

- **Figures**
  - `assets/zz-figures/chapter03/03_fig_01_fr_stability_domain.png`
  - `assets/zz-figures/chapter03/03_fig_08_ricci_fr_vs_t.png`

(Remarque : `assets/zz-data/chapter03/placeholder.csv` reste classé comme placeholder structurel,
hors vitrine.)


### CH04 – Invariants sans dimension

- **Scripts**
  - `scripts/chapter04/generate_data_chapter04.py`

- **Données**
  - `assets/zz-data/chapter04/04_dimensionless_invariants.csv`

- **Figures**
  - `assets/zz-figures/chapter04/04_fig_01_invariants_schematic.png`
  - `assets/zz-figures/chapter04/04_fig_03_invariants_vs_t.png`


### CH05 – Nucléosynthèse primordiale (BBN)

- **Scripts**
  - `scripts/chapter05/generate_data_chapter05.py`
  - `scripts/chapter05/10_fig02_dh_model_vs_obs.py`

- **Données**
  - `assets/zz-data/chapter05/05_bbn_data.csv`
  - `assets/zz-data/chapter05/05_bbn_invariants.csv`
  - `assets/zz-data/chapter05/05_chi2_bbn_vs_T.csv`

- **Figures**
  - `assets/zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png`
  - `assets/zz-figures/chapter05/05_fig_04_chi2_vs_t.png`


### CH06 – CMB & Δχ²

- **Scripts**
  - `scripts/chapter06/generate_data_chapter06.py`
  - `scripts/chapter06/10_fig02_cls_lcdm_vs_mcgt.py`

- **Données**
  - `assets/zz-data/chapter06/06_cmb_full_results.csv`
  - `assets/zz-data/chapter06/06_delta_cls_relative.csv`
  - `assets/zz-data/chapter06/06_cmb_chi2_scan2D.csv`

- **Figures**
  - `assets/zz-figures/chapter06/06_fig_02_cls_lcdm_vs_mcgt.png`
  - `assets/zz-figures/chapter06/06_fig_05_delta_chi2_heatmap.png`


### CH07 – Perturbations scalaires

- **Scripts**
  - `scripts/chapter07/generate_data_chapter07.py`
  - `scripts/chapter07/launch_scalar_perturbations_solver.py`

- **Données**
  - `assets/zz-data/chapter07/07_scalar_perturbations_results.csv`
  - `assets/zz-data/chapter07/07_scalar_invariants.csv`
  - `assets/zz-data/chapter07/07_cs2_matrix.csv`

- **Figures**
  - `assets/zz-figures/chapter07/07_fig_01_cs2_heatmap.png`
  - `assets/zz-figures/chapter07/07_fig_06_comparison.png`

(Remarque : `assets/zz-data/chapter07/placeholder.csv` reste un placeholder structurel,
hors vitrine.)


### CH08 – BAO, SN Ia & couplage

- **Scripts**
  - `scripts/chapter08/generate_data_chapter08.py`

- **Données**
  - `assets/zz-data/chapter08/08_pantheon_data.csv`
  - `assets/zz-data/chapter08/08_bao_data.csv`
  - `assets/zz-data/chapter08/08_chi2_total_vs_q0.csv`
  - `assets/zz-data/chapter08/08_coupling_params.json`

- **Figures**
  - `assets/zz-figures/chapter08/08_fig_01_chi2_total_vs_q0.png`
  - `assets/zz-figures/chapter08/08_fig_05_residuals.png`


### CH09 – Phases IMRPhenom vs MCGT

- **Scripts**
  - `scripts/chapter09/generate_data_chapter09.py`
  - `scripts/chapter09/10_fig01_phase_overlay.py`

- **Données**
  - `assets/zz-data/chapter09/09_best_params.json`
  - `assets/zz-data/chapter09/09_metrics_phase.json`
  - `assets/zz-data/chapter09/09_phases_imrphenom.csv`
  - `assets/zz-data/chapter09/09_phases_mcgt.csv`

- **Figures**
  - `assets/zz-figures/chapter09/09_fig_01_phase_overlay.png`
  - `assets/zz-figures/chapter09/09_fig_02_residual_phase.png`

- **Note**
  - La tension SNIa suggere un reajustement de Omega_m ou l'inclusion d'une courbure non nulle Omega_k.


### CH10 – Bootstrap & métriques sur p95

- **Scripts**
  - `scripts/chapter10/generate_data_chapter10.py`
  - `scripts/chapter10/eval_primary_metrics_20_300.py`

- **Données**
  - `assets/zz-data/chapter10/10_mc_results.circ.with_fpeak.csv`
  - `assets/zz-data/chapter10/10_mc_best_bootstrap.json`
  - `assets/zz-data/chapter10/dummy_results.csv`   (CORE DATA CH10)
  - `assets/zz-data/chapter10/example_results.csv` (EXAMPLE OFFICIELLE)

- **Figures**
  - `assets/zz-figures/chapter10/10_fig_01_iso_p95_maps.png`
  - `assets/zz-figures/chapter10/10_fig_07_synthesis.png`
---
## Step14 – FRONT/BACKSTAGE (snapshot)

_Dernière génération via Step14 (stats FRONT / BACKSTAGE par chapitre)._

```text
=== MCGT Step14 : stats FRONT / BACKSTAGE ===
[INFO] Source Step12 : zz-logs/step12_backstage_candidates_20251130T034239Z.txt
[INFO] Généré le (UTC) : 20251130T035910Z

# Par chapitre : inventory, front, backstage, ratios (%)

CH01 :
  - inventory total : 20
  - front_files     : 6
  - backstage       : 14
  - ratio FRONT     :  30.0%
  - ratio BACKSTAGE :  70.0%

CH02 :
  - inventory total : 24
  - front_files     : 6
  - backstage       : 18
  - ratio FRONT     :  25.0%
  - ratio BACKSTAGE :  75.0%

CH03 :
  - inventory total : 26
  - front_files     : 7
  - backstage       : 19
  - ratio FRONT     :  26.9%
  - ratio BACKSTAGE :  73.1%

CH04 :
  - inventory total : 10
  - front_files     : 4
  - backstage       : 6
  - ratio FRONT     :  40.0%
  - ratio BACKSTAGE :  60.0%

CH05 :
  - inventory total : 16
  - front_files     : 7
  - backstage       : 9
  - ratio FRONT     :  43.8%
  - ratio BACKSTAGE :  56.2%

CH06 :
  - inventory total : 22
  - front_files     : 7
  - backstage       : 15
  - ratio FRONT     :  31.8%
  - ratio BACKSTAGE :  68.2%

CH07 :
  - inventory total : 31
  - front_files     : 8
  - backstage       : 23
  - ratio FRONT     :  25.8%
  - ratio BACKSTAGE :  74.2%

CH08 :
  - inventory total : 27
  - front_files     : 7
  - backstage       : 20
  - ratio FRONT     :  25.9%
  - ratio BACKSTAGE :  74.1%

CH09 :
  - inventory total : 29
  - front_files     : 8
  - backstage       : 21
  - ratio FRONT     :  27.6%
  - ratio BACKSTAGE :  72.4%

CH10 :
  - inventory total : 40
  - front_files     : 8
  - backstage       : 32
  - ratio FRONT     :  20.0%
  - ratio BACKSTAGE :  80.0%
```


---
## Step22 – HEALTH_CHECK_COMPLET (snapshot)

_Dernière exécution Step22 (health-check complet) – log : `step22_health_20251130T172933Z.log`._

```text
=== MCGT Step22 : health-check complet (diag + smoke) ===
[INFO] Repo root : /home/jplal/MCGT
[INFO] Horodatage (UTC) : 20251130T172933Z
------------------------------------------------------------
[STEP] Smoke CH09 (fast)
    -> bash tools/smoke_ch09_fast.sh
[INFO] Smoke CH09 (fast)
[2025-11-30 12:29:33] [INFO] Paramètres MCGT: PhaseParams(m1=30.0, m2=25.0, q0star=0.0, alpha=0.0, phi0=0.0, tc=0.0, tol=1e-06)
[2025-11-30 12:29:33] [INFO] Référence existante utilisée (232 pts).
[2025-11-30 12:29:33] [INFO] Calage phi0_tc (poids=1/f2): φ0=-1.128308e+02 rad, t_c=1.628968e-01 s (n=117, window=[20.0, 300.0])
[2025-11-30 12:29:33] [INFO] Contrôle p95 avant resserrage: p95(|Δφ|)@[20.0-300.0]=164.413475 rad (seuil=5.000)
[2025-11-30 12:29:33] [INFO] Resserrement automatique: refit sur [30.0, 250.0] Hz.
[2025-11-30 12:29:33] [INFO] Calage phi0_tc (poids=1/f2): φ0=-5.894512e+01 rad, t_c=7.323216e-02 s (n=92, window=[30.0, 250.0])
[2025-11-30 12:29:33] [INFO] Après resserrage: p95(|Δφ|)@[20.0-300.0]=81.291949 rad
[2025-11-30 12:29:33] [INFO] Conserver fichier existant (utilisez --overwrite pour écraser): assets/zz-data/chapter09/09_phases_mcgt.csv
[2025-11-30 12:29:33] [INFO] Écrit → assets/zz-data/chapter09/09_metrics_phase.json
[2025-11-30 12:29:33] [INFO] Terminé. Variante ACTIVE: calibrated | p95(|Δφ|)@20–300 = 81.291949 rad
[2025-11-30 12:29:34] [WARNING] Lecture JSON méta échouée ('float' object has no attribute 'get').
[2025-11-30 12:29:34] [INFO] Calibration meta: enabled=False, model=phi0,tc, window=[20.0, 300.0]
[2025-11-30 12:29:34] [INFO] Plateau terminal φ_ref: masquage > f=1819.701 Hz
[2025-11-30 12:29:34] [INFO] k (médiane des cycles) = 1
[2025-11-30 12:29:34] [INFO] Fit visuel: dphi0=-3.231e+02 rad, dtc=8.940e-02 s
[2025-11-30 12:29:34] [INFO] |Δφ| 20–300 Hz (après rebranch k=1): mean=1.671 ; p95=3.045 ; max=3.101 (n=117)
[2025-11-30 12:29:34] [INFO] Figure écrite → assets/zz-figures/chapter09/09_fig_01_phase_overlay.png
[OK] fig02_input.csv → zz-out/chapter09/fig02_input.csv (n=232) ; IMR(f_Hz,phi_ref) vs MCGT(f_Hz,phi_mcgt)
[OK] fig02_input normalisé
[2025-11-30 12:29:35] [INFO] Variante active: phi_mcgt
[2025-11-30 12:29:35] [INFO] Rebranch k (20.0–300.0 Hz) = 1 cycles
[2025-11-30 12:29:35] [INFO] Stats 20–300 Hz: mean=1.671  p95=3.045  max=3.101
[2025-11-30 12:29:36] [INFO] Figure enregistrée → assets/zz-figures/chapter09/09_fig_02_residual_phase.png
[OK] CH09 complet
[INFO] Commande terminée avec code 0
------------------------------------------------------------
[STEP] Smoke global (squelette)
    -> bash tools/smoke_all_skeleton.sh
[INFO] Smoke global (squelette)
[INFO] Smoke CH09 (fast)
[2025-11-30 12:29:36] [INFO] Paramètres MCGT: PhaseParams(m1=30.0, m2=25.0, q0star=0.0, alpha=0.0, phi0=0.0, tc=0.0, tol=1e-06)
[2025-11-30 12:29:36] [INFO] Référence existante utilisée (232 pts).
[2025-11-30 12:29:36] [INFO] Calage phi0_tc (poids=1/f2): φ0=-1.128308e+02 rad, t_c=1.628968e-01 s (n=117, window=[20.0, 300.0])
[2025-11-30 12:29:36] [INFO] Contrôle p95 avant resserrage: p95(|Δφ|)@[20.0-300.0]=164.413475 rad (seuil=5.000)
[2025-11-30 12:29:36] [INFO] Resserrement automatique: refit sur [30.0, 250.0] Hz.
[2025-11-30 12:29:36] [INFO] Calage phi0_tc (poids=1/f2): φ0=-5.894512e+01 rad, t_c=7.323216e-02 s (n=92, window=[30.0, 250.0])
[2025-11-30 12:29:36] [INFO] Après resserrage: p95(|Δφ|)@[20.0-300.0]=81.291949 rad
[2025-11-30 12:29:36] [INFO] Conserver fichier existant (utilisez --overwrite pour écraser): assets/zz-data/chapter09/09_phases_mcgt.csv
[2025-11-30 12:29:36] [INFO] Écrit → assets/zz-data/chapter09/09_metrics_phase.json
[2025-11-30 12:29:36] [INFO] Terminé. Variante ACTIVE: calibrated | p95(|Δφ|)@20–300 = 81.291949 rad
[2025-11-30 12:29:37] [WARNING] Lecture JSON méta échouée ('float' object has no attribute 'get').
[2025-11-30 12:29:37] [INFO] Calibration meta: enabled=False, model=phi0,tc, window=[20.0, 300.0]
[2025-11-30 12:29:37] [INFO] Plateau terminal φ_ref: masquage > f=1819.701 Hz
[2025-11-30 12:29:37] [INFO] k (médiane des cycles) = 1
[2025-11-30 12:29:37] [INFO] Fit visuel: dphi0=-3.231e+02 rad, dtc=8.940e-02 s
[2025-11-30 12:29:37] [INFO] |Δφ| 20–300 Hz (après rebranch k=1): mean=1.671 ; p95=3.045 ; max=3.101 (n=117)
[2025-11-30 12:29:37] [INFO] Figure écrite → assets/zz-figures/chapter09/09_fig_01_phase_overlay.png
[OK] fig02_input.csv → zz-out/chapter09/fig02_input.csv (n=232) ; IMR(f_Hz,phi_ref) vs MCGT(f_Hz,phi_mcgt)
[OK] fig02_input normalisé
[2025-11-30 12:29:38] [INFO] Variante active: phi_mcgt
[2025-11-30 12:29:38] [INFO] Rebranch k (20.0–300.0 Hz) = 1 cycles
[2025-11-30 12:29:38] [INFO] Stats 20–300 Hz: mean=1.671  p95=3.045  max=3.101
[2025-11-30 12:29:39] [INFO] Figure enregistrée → assets/zz-figures/chapter09/09_fig_02_residual_phase.png
[OK] CH09 complet
[INFO] Commande terminée avec code 0
------------------------------------------------------------
[STEP] Resync manifest CH09 (mcgt_step25_fix_manifest_ch09)
    -> python tools/mcgt_step25_fix_manifest_ch09.py
=== STEP25 : resync CH09 metrics & fig dans le manifest ===
[INFO] Repo root      : /home/jplal/MCGT
[INFO] Manifest path  : /home/jplal/MCGT/assets/zz-manifests/manifest_master.json
[INFO] assets/zz-data/chapter09/09_metrics_phase.json :
       size_bytes = 1839
       sha256     = eb1aa2bfff603ceb7c9d95ab9ea1de34e189fc7b60231422c67d48a99f683a7b
       mtime_iso  = 2025-11-30T17:29:36Z
       git_hash   = a5fb6e5415fdf039a2ef770f4453e6906d430589
[INFO] Blocs patchés pour assets/zz-data/chapter09/09_metrics_phase.json : 1
[INFO] assets/zz-figures/chapter09/09_fig_01_phase_overlay.png :
       size_bytes = 302968
       sha256     = d2e70a8c3e17a2b1f9770e60882ddf86c69fc7b915d25becb0f05338511179ac
       mtime_iso  = 2025-11-30T17:29:37Z
       git_hash   = 64b805360b13ceb34522ce3c787f2c1ca3eb72aa
[INFO] Blocs patchés pour assets/zz-figures/chapter09/09_fig_01_phase_overlay.png : 1
[INFO] Manifest mis à jour : /home/jplal/MCGT/assets/zz-manifests/manifest_master.json
[INFO] Total blocs patchés : 2
[INFO] Commande terminée avec code 0
------------------------------------------------------------
[STEP] Diagnostic de cohérence des manifests
    -> python assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_master.json --report text
Errors: 0  |  Warnings: 0
OK: no problems detected.
[INFO] Commande terminée avec code 0
------------------------------------------------------------
[STEP] Probe des versions (mcgt_probe_versions_v1)
    -> python tools/mcgt_probe_versions_v1.py
=== MCGT: probe versions v1 ===
Root: /home/jplal/MCGT


### Manifestes (root)
---------------------
root.manifest_master                          : name='mcgt-core', version='0.2.99', homepage=''
root.manifest_publication                     : name='mcgt-core', version='0.2.99', homepage=''

### Manifestes (release_zenodo_codeonly/v0.3.x)
-----------------------------------------------
snapshot.manifest_master                      : name='mcgt-core', version='0.2.99', homepage=''
snapshot.manifest_publication                 : name='mcgt-core', version='0.2.99', homepage=''

### pyproject.toml
------------------
root.pyproject                                : name='tools', version='0.3.14'
release_zenodo_codeonly/v0.3.x                : name='tools', version='0.3.14'

### __init__ (__version__)
--------------------------
mcgt.__init__                                 : version='0.3.0' (/home/jplal/MCGT/mcgt/__init__.py)
tools.__init__                             : version='0.3.14' (/home/jplal/MCGT/tools/__init__.py)

### CITATION.cff
----------------
root CITATION.cff                             : version='0.2.99' (/home/jplal/MCGT/CITATION.cff)
release_zenodo_codeonly CITATION.cff          : version='0.2.99' (/home/jplal/MCGT/release_zenodo_codeonly/v0.3.x/CITATION.cff)

[INFO] mcgt_probe_versions_v1 terminé.
[INFO] Commande terminée avec code 0

[INFO] Step22 terminé avec code 0.
[INFO] Log complet : /home/jplal/MCGT/zz-logs/step22_health_20251130T172933Z.log
```
