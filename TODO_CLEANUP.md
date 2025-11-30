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
./_attic_untracked/help_shim_backup_20251106T192653/zz-scripts/chapter07/tests/__pycache__
./_attic_untracked/help_shim_backup_20251106T192653/zz-scripts/chapter07/utils/__pycache__
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
./_autofix_sandbox/20251105T145604Z/release_zenodo_codeonly/v0.3.x/zz_tools/zz_tools/__pycache__
./_autofix_sandbox/20251105T145604Z/scripts/__pycache__
./_autofix_sandbox/20251105T145604Z/tests/__pycache__
./_autofix_sandbox/20251105T145604Z/tools/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-manifests/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-schemas/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/_common/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter01/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter02/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter03/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter03/utils/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter04/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter05/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter06/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter07/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter07/tests/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter07/utils/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter08/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter08/utils/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter09/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/chapter10/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-scripts/manifest_tools/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-tests/__pycache__
./_autofix_sandbox/20251105T145604Z/zz-tools/__pycache__
./_autofix_sandbox/20251105T145604Z/zz_tools/__pycache__
./_autofix_sandbox/20251105T150635Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T150635Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T150635Z/tools/__pycache__
./_autofix_sandbox/20251105T150635Z/zz-manifests/__pycache__
./_autofix_sandbox/20251105T150635Z/zz-schemas/__pycache__
./_autofix_sandbox/20251105T150635Z/zz-tools/__pycache__
./_autofix_sandbox/20251105T150939Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T150939Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T150939Z/tools/__pycache__
./_autofix_sandbox/20251105T150939Z/zz-manifests/__pycache__
./_autofix_sandbox/20251105T150939Z/zz-schemas/__pycache__
./_autofix_sandbox/20251105T150939Z/zz-tools/__pycache__
./_autofix_sandbox/20251105T150942Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T150942Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T150942Z/tools/__pycache__
./_autofix_sandbox/20251105T150942Z/zz-manifests/__pycache__
./_autofix_sandbox/20251105T150942Z/zz-schemas/__pycache__
./_autofix_sandbox/20251105T150942Z/zz-tools/__pycache__
./_autofix_sandbox/20251105T151324Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T151324Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T151324Z/tools/__pycache__
./_autofix_sandbox/20251105T151324Z/zz-manifests/__pycache__
./_autofix_sandbox/20251105T151324Z/zz-schemas/__pycache__
./_autofix_sandbox/20251105T151324Z/zz-tools/__pycache__
./_autofix_sandbox/20251105T151527Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T151527Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T151527Z/tools/__pycache__
./_autofix_sandbox/20251105T151527Z/zz-manifests/__pycache__
./_autofix_sandbox/20251105T151527Z/zz-schemas/__pycache__
./_autofix_sandbox/20251105T151527Z/zz-tools/__pycache__
./_autofix_sandbox/20251105T152322Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T152322Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T152322Z/tools/__pycache__
./_autofix_sandbox/20251105T152322Z/zz-manifests/__pycache__
./_autofix_sandbox/20251105T152322Z/zz-schemas/__pycache__
./_autofix_sandbox/20251105T152322Z/zz-tools/__pycache__
./_autofix_sandbox/20251105T152829Z/_attic_untracked/migrate_staging/20251028T203441Z/tools/__pycache__
./_autofix_sandbox/20251105T152829Z/release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./_autofix_sandbox/20251105T152829Z/tools/__pycache__
./_autofix_sandbox/20251105T152829Z/zz-manifests/__pycache__
./_autofix_sandbox/20251105T152829Z/zz-schemas/__pycache__
./_autofix_sandbox/20251105T152829Z/zz-tools/__pycache__
./attic/safe_runners/__pycache__
./mcgt/__pycache__
./mcgt/backends/__pycache__
./release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__pycache__
./release_zenodo_codeonly/v0.3.x/mcgt/mcgt/backends/__pycache__
./release_zenodo_codeonly/v0.3.x/zz_tools/zz_tools/__pycache__
./scripts/__pycache__
./tests/__pycache__
./tools/__pycache__
./zz-manifests/__pycache__
./zz-schemas/__pycache__
./zz-scripts/_common/__pycache__
./zz-scripts/chapter01/__pycache__
./zz-scripts/chapter02/__pycache__
./zz-scripts/chapter03/__pycache__
./zz-scripts/chapter03/utils/__pycache__
./zz-scripts/chapter04/__pycache__
./zz-scripts/chapter05/__pycache__
./zz-scripts/chapter06/__pycache__
./zz-scripts/chapter07/__pycache__
./zz-scripts/chapter07/tests/__pycache__
./zz-scripts/chapter07/utils/__pycache__
./zz-scripts/chapter08/__pycache__
./zz-scripts/chapter08/utils/__pycache__
./zz-scripts/chapter09/__pycache__
./zz-scripts/chapter10/__pycache__
./zz-scripts/manifest_tools/__pycache__
./zz-tests/__pycache__
./zz-tools/__pycache__
./zz_tools/__pycache__
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
      280768  ./zz-manifests/manifest_master.json.20251121T063556Z.bak
      279847  ./zz-manifests/manifest_master.json.20251122T152226Z.bak
      279845  ./zz-manifests/manifest_master.json.20251122T152705Z.bak
      272740  ./zz-manifests/manifest_master.json.20251122T153232Z.bak
      244826  ./zz-manifests/manifest_master.json.20251122T155427Z.bak
      244690  ./zz-manifests/manifest_master.json.20251121T064206Z.bak
      237972  ./zz-manifests/manifest_master.json.20251128T141647Z.bak
      237971  ./zz-manifests/manifest_master.json.20251122T161418Z.bak
      237970  ./zz-manifests/manifest_master.json.20251122T160125Z.bak
      235421  ./zz-manifests/manifest_master.json.20251121T153534Z.bak
      235421  ./zz-manifests/manifest_master.json.20251121T134742Z.bak
      235420  ./zz-manifests/manifest_master.json.20251121T124657Z.bak
      235420  ./zz-manifests/manifest_master.json.20251121T122250Z.bak
      235420  ./zz-manifests/manifest_master.json.20251121T121009Z.bak
      235419  ./zz-manifests/manifest_master.json.20251121T064453Z.bak
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
- Déplacé zz_tools.egg-info vers attic/generated/ (suffixé par timestamp)

## [2025-11-29T16:46:44Z] mcgt_bump_citation_version_v1
- Version de référence (manifest_master.project.version) : 0.2.99
- CITATION.cff (racine) : champ version mis à jour.
- CITATION.cff (release_zenodo_codeonly/v0.3.x) : champ version mis à jour.

## Step07 – LOW_PRIORITY_DATA (classification et plan)

_Date : 2025-11-30 02:39 UTC_

### Fichiers à considérer comme **données officielles / obligatoires**

- `zz-data/chapter10/dummy_results.csv`
  - Dataset principal (≈1200 lignes, 6 colonnes) pour les figures et analyses du chapitre 10.
  - Colonnes : `m1`, `m2`, `p95_20_300`, `p95_20_300_recalc`, `phi_ref_fpeak`, `phi_mcgt_fpeak`.
  - Utilisé par :
    - `tools/ch10_smoke.sh`
    - `tools/ch10_afterfix.sh`
    - plusieurs scripts `tools/ch10_fix_*.sh`
    - `tools/ch10_patch_and_test.sh`
  - → Statut : **CORE DATA CH10**, ne pas supprimer.

- `zz-data/chapter10/example_results.csv`
  - Petit dataset d'exemple (5 lignes, 6 colonnes) de type GW-A…E.
  - Colonnes : `id`, `event`, `f_Hz`, `phi_mcgt_at_fpeak`, `obs_phase`, `sigma_phase`.
  - Référencé par les diagnostics de publication (`_diag_publication_*.json`) et les manifests.
  - → Statut : **EXAMPLE DATA OFFICIELLE**, à conserver comme jeu d'exemple.

### Fichiers à considérer comme **placeholders structurels** (candidats ménage futur)

- `zz-data/chapter03/placeholder.csv`
- `zz-data/chapter07/placeholder.csv`

Caractéristiques communes :
- Fichiers CSV **vides** (`No columns to parse from file`).
- Référencés dans :
  - plusieurs `_diag_master_*.json`
  - `zz-manifests/manifest_master.json`
  - `zz-manifests/integrity.json`
  - `zz-manifests/master.json`
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
     - `zz-manifests/manifest_master.json`
     - `zz-manifests/integrity.json`
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
  - `zz-scripts/chapter01/generate_data_chapter01.py`
  - `zz-scripts/chapter01/plot_fig03_relative_error_timeline.py`

- **Données**
  - `zz-data/chapter01/01_optimized_data.csv`
  - `zz-data/chapter01/01_relative_error_timeline.csv`

- **Figures**
  - `zz-figures/chapter01/01_fig_01_early_plateau.png`
  - `zz-figures/chapter01/01_fig_03_relative_error_timeline.png`


### CH02 – Spectre primordial & calibration

- **Scripts**
  - `zz-scripts/chapter02/generate_data_chapter02.py`
  - `zz-scripts/chapter02/plot_fig00_spectrum.py`

- **Données**
  - `zz-data/chapter02/02_primordial_spectrum_spec.json`
  - `zz-data/chapter02/02_As_ns_vs_alpha.csv`

- **Figures**
  - `zz-figures/chapter02/02_fig_00_spectrum.png`
  - `zz-figures/chapter02/02_fig_03_relative_errors.png`


### CH03 – Stabilité f(R) & courbure de Ricci

- **Scripts**
  - `zz-scripts/chapter03/generate_data_chapter03.py`
  - `zz-scripts/chapter03/plot_fig01_fR_stability_domain.py`

- **Données**
  - `zz-data/chapter03/03_fR_stability_domain.csv`
  - `zz-data/chapter03/03_ricci_fR_vs_T.csv`

- **Figures**
  - `zz-figures/chapter03/03_fig_01_fr_stability_domain.png`
  - `zz-figures/chapter03/03_fig_08_ricci_fr_vs_t.png`

(Remarque : `zz-data/chapter03/placeholder.csv` reste classé comme placeholder structurel,
hors vitrine.)


### CH04 – Invariants sans dimension

- **Scripts**
  - `zz-scripts/chapter04/generate_data_chapter04.py`

- **Données**
  - `zz-data/chapter04/04_dimensionless_invariants.csv`

- **Figures**
  - `zz-figures/chapter04/04_fig_01_invariants_schematic.png`
  - `zz-figures/chapter04/04_fig_03_invariants_vs_t.png`


### CH05 – Nucléosynthèse primordiale (BBN)

- **Scripts**
  - `zz-scripts/chapter05/generate_data_chapter05.py`
  - `zz-scripts/chapter05/plot_fig02_dh_model_vs_obs.py`

- **Données**
  - `zz-data/chapter05/05_bbn_data.csv`
  - `zz-data/chapter05/05_bbn_invariants.csv`
  - `zz-data/chapter05/05_chi2_bbn_vs_T.csv`

- **Figures**
  - `zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png`
  - `zz-figures/chapter05/05_fig_04_chi2_vs_t.png`


### CH06 – CMB & Δχ²

- **Scripts**
  - `zz-scripts/chapter06/generate_data_chapter06.py`
  - `zz-scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py`

- **Données**
  - `zz-data/chapter06/06_cmb_full_results.csv`
  - `zz-data/chapter06/06_delta_cls_relative.csv`
  - `zz-data/chapter06/06_cmb_chi2_scan2D.csv`

- **Figures**
  - `zz-figures/chapter06/06_fig_02_cls_lcdm_vs_mcgt.png`
  - `zz-figures/chapter06/06_fig_05_delta_chi2_heatmap.png`


### CH07 – Perturbations scalaires

- **Scripts**
  - `zz-scripts/chapter07/generate_data_chapter07.py`
  - `zz-scripts/chapter07/launch_scalar_perturbations_solver.py`

- **Données**
  - `zz-data/chapter07/07_scalar_perturbations_results.csv`
  - `zz-data/chapter07/07_scalar_invariants.csv`
  - `zz-data/chapter07/07_cs2_matrix.csv`

- **Figures**
  - `zz-figures/chapter07/07_fig_01_cs2_heatmap.png`
  - `zz-figures/chapter07/07_fig_06_comparison.png`

(Remarque : `zz-data/chapter07/placeholder.csv` reste un placeholder structurel,
hors vitrine.)


### CH08 – BAO, SN Ia & couplage

- **Scripts**
  - `zz-scripts/chapter08/generate_data_chapter08.py`

- **Données**
  - `zz-data/chapter08/08_pantheon_data.csv`
  - `zz-data/chapter08/08_bao_data.csv`
  - `zz-data/chapter08/08_chi2_total_vs_q0.csv`
  - `zz-data/chapter08/08_coupling_params.json`

- **Figures**
  - `zz-figures/chapter08/08_fig_01_chi2_total_vs_q0.png`
  - `zz-figures/chapter08/08_fig_05_residuals.png`


### CH09 – Phases IMRPhenom vs MCGT

- **Scripts**
  - `zz-scripts/chapter09/generate_data_chapter09.py`
  - `zz-scripts/chapter09/plot_fig01_phase_overlay.py`

- **Données**
  - `zz-data/chapter09/09_best_params.json`
  - `zz-data/chapter09/09_metrics_phase.json`
  - `zz-data/chapter09/09_phases_imrphenom.csv`
  - `zz-data/chapter09/09_phases_mcgt.csv`

- **Figures**
  - `zz-figures/chapter09/09_fig_01_phase_overlay.png`
  - `zz-figures/chapter09/09_fig_02_residual_phase.png`


### CH10 – Bootstrap & métriques sur p95

- **Scripts**
  - `zz-scripts/chapter10/generate_data_chapter10.py`
  - `zz-scripts/chapter10/eval_primary_metrics_20_300.py`

- **Données**
  - `zz-data/chapter10/10_mc_results.circ.with_fpeak.csv`
  - `zz-data/chapter10/10_mc_best_bootstrap.json`
  - `zz-data/chapter10/dummy_results.csv`   (CORE DATA CH10)
  - `zz-data/chapter10/example_results.csv` (EXAMPLE OFFICIELLE)

- **Figures**
  - `zz-figures/chapter10/10_fig_01_iso_p95_maps.png`
  - `zz-figures/chapter10/10_fig_07_synthesis.png`


