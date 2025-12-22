# RUNBOOK — Exécution opératoire (MCGT)

Ce runbook est une **checklist opératoire** pour (1) préparer l’environnement, (2) régénérer les artefacts, (3) vérifier la qualité, (4) empaqueter la remise.
Tous les noms de fichiers et de répertoires sont **en anglais** (ex. `assets/zz-data/chapter09/...`, `scripts/10_global_scan/...`). Les seuls fichiers pouvant rester en français sont les sources **.tex** des chapitres.

---

## Phase 0 — Préparation

\[ ] Cloner le dépôt et se placer sur le commit/branche à livrer
\[ ] Vérifier la présence des fichiers/répertoires clés (anglais) :

* `Makefile`
* `requirements.txt`, `environment.yml`
* `convention.md`
* `config/mcgt-global-config.ini`
* `assets/zz-schemas/`

  * schémas : `*.schema.json` (ex. `mc_config_schema.json`, `metrics_phase_schema.json`, …)
  * validateurs : `validate_json.py`, `validate_csv_table.py`
  * règles : `consistency_rules.json`
* `assets/zz-manifests/`

  * `manifest_master.json`, `manifest_publication.json` (+ `.bak` si présent)
  * `manifest_report.md` (ou `.json`), `README_manifest.md`
  * outils : `diag_consistency.py`, `add_to_manifest.py` (si présent)

\[ ] Choisir la méthode d’environnement : **Conda/Mamba** (recommandé) ou **venv+pip**

Commandes (une des deux options) :

* Conda/Mamba

  ```
  conda env create -f environment.yml -n mcgt
  conda activate mcgt
  ```
* venv + pip

  ```
  python3 -m venv .venv
  . .venv/bin/activate
  pip install -r requirements.txt
  ```

Points de contrôle :

* `python -V` retourne une 3.12.x (compatible)
* Imports rapides (doivent réussir) : `python -c "import numpy,pandas,matplotlib,jsonschema"`

Variables d’environnement :

* `MCGT_CONFIG` → chemin du fichier de config global (défaut : `config/mcgt-global-config.ini`)

---

## Phase 1 — Génération des données

### 1.1 Patron par chapitre (scripts Python)

Chaque chapitre dispose de générateurs dédiés sous `scripts/chapterXX/`. Patron :

```
python scripts/chapterNN/generate_data_chapterNN.py
```

Exemples utiles :

* Chapter 02 (spectre primordial)
  `python scripts/02_primordial_spectrum/generate_data_chapter02.py`
* Chapter 07 (perturbations scalaires)
  `python scripts/07_bao_geometry/generate_data_chapter07.py`
* Chapter 08 (couplage sombre)
  `python scripts/08_sound_horizon/generate_data_chapter08.py`
* Chapter 09 (phase GW)
  `python scripts/09_dark_energy_cpl/generate_data_chapter09.py`
* Chapter 10 (Monte Carlo 8D)
  `python scripts/10_global_scan/generate_data_chapter10.py`

Sorties attendues (anglais) :

* `assets/zz-data/chapter{NN}/...` (CSV/JSON)
* un `*.meta.json` par groupe d’artefacts (conforme à `assets/zz-schemas/meta_schema.json` ou schéma dédié)

Points de contrôle :

* Les CSV/JSON existent et sont horodatés récents
* Les `*.meta.json` déclarent : `generated_at`, `git_hash`, `files`, `checksum_sha256`, etc.

---

## Phase 2 — Tracés et figures

Patron :

```
python scripts/chapterNN/10_figXX_*.py
```

Exemples :

* Chapter 09 :
  `10_fig01_phase_overlay.py`, `10_fig02_residual_phase.py`, `10_fig03_hist_absdphi_20_300.py`, `10_fig04_absdphi_milestones_vs_f.py`, `10_fig05_scatter_phi_at_fpeak.py`
* Chapter 10 :
  `10_fig01_iso_p95_maps.py`, `10_fig02_scatter_phi_at_fpeak.py`, `10_fig03_convergence_p95_vs_n.py`, `10_fig03b_bootstrap_coverage_vs_n.py`, `10_fig04_scatter_p95_recalc_vs_orig.py`, `10_fig05_hist_cdf_metrics.py`, `10_fig06_residual_map.py`, `10_fig07_synthesis.py`

Sorties attendues :

* `assets/zz-figures/chapter{NN}/fig_*.png` (et éventuels `.pdf`)

Points de contrôle :

* Les figures critiques existent et s’ouvrent (pas de PNG vide ou corrompu)

---

## Phase 3 — Diagnostics (QA)

### 3.1 Cibles Makefile (rapides et sûres)

```
make env            # affiche la version Python et l’exécutable
make paths          # répertoires clés
make validate       # JSON + CSV (schémas ↔ instances)
make validate-json  # JSON uniquement
make validate-csv   # CSV uniquement
make ch09           # filtre validation chapitre 09
make ch10           # filtre validation chapitre 10
make audit-schemas  # charge tous les *.schema.json (sanity)
make audit-data     # présence des fichiers de données clés
make manifestscheck # vérifie manifest_master.json
make manifests-md   # génère assets/zz-manifests/manifest_report.md
make jsoncheck-strict  # audit JSON strict dans tout le dépôt
```

### 3.2 Validation JSON (schéma ↔ instance)

Exemples (chemins en anglais) :

```
python assets/zz-schemas/validate_json.py assets/zz-schemas/mc_config_schema.json assets/zz-data/chapter10/10_mc_config.json
python assets/zz-schemas/validate_json.py assets/zz-schemas/mc_best_schema.json   assets/zz-data/chapter10/10_mc_best.json
python assets/zz-schemas/validate_json.py assets/zz-schemas/metrics_phase_schema.json assets/zz-data/chapter09/09_metrics_phase.json
```

### 3.3 Validation CSV (tables ↔ schéma de table)

```
python assets/zz-schemas/validate_csv_table.py assets/zz-schemas/mc_results_table_schema.json assets/zz-data/chapter10/10_mc_results.csv
python assets/zz-schemas/validate_csv_table.py assets/zz-schemas/mc_results_table_schema.json assets/zz-data/chapter10/10_mc_results.circ.csv
python assets/zz-schemas/validate_csv_table.py assets/zz-schemas/comparison_milestones_table_schema.json assets/zz-data/chapter09/09_comparison_milestones.csv
```

### 3.4 Diagnostic de manifestes + règles transverses

* Audit/normalisation (avec règles) :

```
python assets/zz-manifests/diag_consistency.py \
  assets/zz-manifests/manifest_master.json \
  --report md \
  --fix --normalize-paths --strip-internal \
  --fail-on errors \
  --set-repo-root
```

* Les **règles transverses** (seuils, fenêtres, alias de chemins, renommages) sont dans
  `assets/zz-schemas/consistency_rules.json`. Le script de diagnostic les lit automatiquement si présent.

Résultats attendus :

* `assets/zz-manifests/manifest_report.md` : erreurs = 0 ; avertissements tolérés si justifiés
* Chemins relatifs, SHA-256 cohérents, tailles exactes

---

## Phase 4 — Pipelines spécifiques (vérifications techniques)

### 4.1 Chapter 09 — Phase GW

* Données clés :
  `assets/zz-data/chapter09/09_phases_imrphenom.csv` (+ `.meta.json`),
  `assets/zz-data/chapter09/09_phases_mcgt.csv`,
  `assets/zz-data/chapter09/09_metrics_phase.json`,
  `assets/zz-data/chapter09/09_comparison_milestones.csv` (+ `.meta.json`)
* Contrôles conseillés :

  * cohérence p95 sur `[20,300]` Hz (principal)
  * stabilité de `rebranch_k` (tester k±1)
  * `flagging` des jalons (si script présent) :

    ```
    python scripts/09_dark_energy_cpl/flag_jalons.py \
      --csv  assets/zz-data/chapter09/09_comparison_milestones.csv \
      --meta assets/zz-data/chapter09/09_comparison_milestones.meta.json \
      --out-csv assets/zz-data/chapter09/09_comparison_milestones.flagged.csv \
      --write-meta
    ```

### 4.2 Chapter 10 — Monte Carlo 8D

* Données clés :
  `assets/zz-data/chapter10/10_mc_config.json`, `10_mc_results.csv`, `10_mc_results.circ.csv`,
  `10_mc_best.json`, `10_mc_best_bootstrap.json`, `10_mc_milestones_eval.csv` (si présent)
* Contrôles conseillés :

  * `p95_20_300` en radians (linéaire vs circulaire)
  * reproductibilité de l’échantillonnage Sobol (`seed`, `n`, `scramble`)
  * `diag_phi_fpeak.py` / `add_phi_at_fpeak.py` si utilisés pour enrichir les CSV

---

## Phase 5 — Empaquetage (publication interne/externe)

### 5.1 Normaliser et geler les manifestes

* Mettre à jour le maître puis le sous-ensemble publication :

```
python assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_master.json --fix --report md
cp assets/zz-manifests/manifest_publication.json assets/zz-manifests/manifest_publication.json.bak
```

### 5.2 Archiver le livrable

* Exemple simple (depuis la racine du dépôt) :

```
mkdir -p dist
tar czf dist/MCGT_$(date +%Y%m%d)_release.tar.gz \
  manuscript/main.tex convention.md requirements.txt environment.yml Makefile \
  configuration assets/zz-data assets/zz-figures scripts assets/zz-schemas assets/zz-manifests
```

Vérifications :

* Archive créée dans `dist/`
* `manifest_publication.json` inclus et à jour

---

## Phase 6 — Finalisation

\[ ] Tag git et message de version (si applicable)
\[ ] Congruence des versions dans : `manifest_master.json`, `*.meta.json`, `mcgt-global-config.ini`
\[ ] Note de livraison : préciser **seed Sobol**, **fenêtre** `[20,300]` Hz, et versions de libs (numpy/pandas/lalsuite/CAMB)

---

## Annexes

### A. Arborescence minimale attendue (anglais)

```
MCGT/
├─ manuscript/main.tex
├─ convention.md
├─ requirements.txt
├─ environment.yml
├─ Makefile
├─ config/
│  ├─ mcgt-global-config.ini
│  ├─ camb_exact_plateau.ini
│  ├─ gw_phase.ini
│  └─ scalar_perturbations.ini
├─ assets/zz-schemas/
│  ├─ *.schema.json
│  ├─ consistency_rules.json
│  ├─ validate_json.py
│  └─ validate_csv_table.py
├─ assets/zz-data/
│  ├─ chapter01/ ...
│  ├─ chapter09/
│  │  ├─ 09_phases_imrphenom.csv
│  │  ├─ 09_phases_imrphenom.meta.json
│  │  ├─ 09_phases_mcgt.csv
│  │  ├─ 09_metrics_phase.json
│  │  ├─ 09_comparison_milestones.csv
│  │  └─ 09_comparison_milestones.meta.json
│  └─ chapter10/
│     ├─ 10_mc_config.json
│     ├─ 10_mc_results.csv
│     ├─ 10_mc_results.circ.csv
│     ├─ 10_mc_best.json
│     └─ 10_mc_best_bootstrap.json
├─ assets/zz-figures/
│  ├─ chapter09/ fig_*.png
│  └─ chapter10/ fig_*.png
├─ scripts/
│  ├─ chapter09/ generate_data_chapter09.py, 10_fig*.py, flag_jalons.py
│  └─ chapter10/ generate_data_chapter10.py, 10_fig*.py, *.py
└─ assets/zz-manifests/
   ├─ manifest_master.json
   ├─ manifest_publication.json
   ├─ manifest_report.md
   ├─ README_manifest.md
   └─ diag_consistency.py
```

### B. Commandes de validation express (à copier/coller)

```
make validate
make ch09
make ch10
python assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_master.json --report md --fail-on errors
```

### C. Pièges fréquents (à éviter)

* Chemins **FR** (`zz-donnees/chapitreXX`) utilisés par erreur → utiliser **anglais** : `assets/zz-data/chapterXX`
* Fichiers manquants parce que `chapter10` vs `chapitre10` → rester cohérent (anglais)
* `p95_*` mélangé (linéaire/circulaire) → vérifier les suffixes (`_circ`, `_recalc`) et l’unité (radian)
* `*.meta.json` incomplets (pas de `generated_at`/`git_hash`) → compléter avant remise
