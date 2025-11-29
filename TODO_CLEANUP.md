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
