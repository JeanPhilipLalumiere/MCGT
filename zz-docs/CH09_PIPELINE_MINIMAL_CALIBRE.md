# Chapitre 09 – Pipeline minimal calibré (phase gravitationnelle)

Ce document décrit le **pipeline minimal calibré** permettant de relancer, à partir du dépôt
MCGT, les calculs et figures essentiels du **chapitre 09 – phase gravitationnelle
(IMRPhenom vs MCGT)**.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- recalculer `09_metrics_phase.json` sur la bande de référence (20–300 Hz) ;
- régénérer les deux figures de phase principales ;
- vérifier rapidement que la chaîne de calcul CH09 reste cohérente numériquement.

Ce pipeline repose sur un script shell canonique :

- `zz-tools/smoke_ch09_fast.sh`

qui orchestre les appels aux scripts Python de CH09.

---

## 1. Objectif

Le pipeline minimal CH09 est conçu pour :

- tester rapidement la **cohérence de phase** entre MCGT et IMRPhenom ;
- vérifier que la **fenêtre de calibration** (fit sur [30, 250] Hz, métriques sur [20, 300] Hz)
  donne des résultats stables ;
- actualiser les **métriques de contrôle** dans `09_metrics_phase.json` ;
- régénérer les **figures principales** utilisées dans le chapitre (superposition de phase,
  résidu de phase).

Il ne vise pas à reconstruire toute la chaîne GWTC-3 (multi‑événements), mais à
assurer la stabilité du cœur de l’analyse de phase.

---

## 2. Pré‑requis

Depuis la racine du dépôt `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `matplotlib`, (optionnel : `scipy`, `h5py`, `lalsuite`) ;
- Fichiers de configuration et de données déjà présents (suivis par les manifests) :

  - `zz-configuration/GWTC-3-confident-events.json`
  - `zz-data/chapter09/gwtc3_confident_parameters.json`
  - `zz-data/chapter09/09_phases_imrphenom.csv`  (phase IMRPhenom de référence)
  - `zz-data/chapter09/09_phases_mcgt.csv`       (phase MCGT finale, déjà construite)

Les chemins supposent la hiérarchie standard du dépôt MCGT.

---

## 3. Résumé rapide – commande unique

Depuis la racine du dépôt :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire
bash zz-tools/smoke_ch09_fast.sh
```

Ce script effectue automatiquement, de manière compacte, les opérations suivantes
(résumé basé sur les logs actuels) :

1. **Chargement de la référence IMRPhenom** (`09_phases_imrphenom.csv`)
   et des phases MCGT (`09_phases_mcgt.csv`) ;
2. **Calage de la phase** (`φ₀`, `t_c`) par ajustement pondéré
   (poids typiques en `1/f²`) sur une fenêtre de fit (par ex. [30, 250] Hz) ;
3. **Contrôle de la dispersion** `p95(|Δφ|)` sur la bande [20, 300] Hz ;
4. Si nécessaire, **resserrage automatique** de la fenêtre de fit, puis nouveau calage ;
5. **Écriture / mise à jour des métriques** dans :

   ```text
   zz-data/chapter09/09_metrics_phase.json
   ```

6. **Génération des figures de phase** :

   - `zz-figures/chapter09/09_fig_01_phase_overlay.png`
   - `zz-figures/chapter09/09_fig_02_residual_phase.png`

7. **Préparation des données intermédiaires** pour la figure 02 :

   - `zz-out/chapter09/fig02_input.csv`
   - (éventuelles variantes normalisées associées).

En cas de succès, les logs se terminent par un message du type :

- `[INFO] 09_metrics_phase.json mis à jour (variant=..., p95=... rad sur 20–300 Hz)`  
- `[INFO] Figure enregistrée → zz-figures/chapter09/09_fig_01_phase_overlay.png`  
- `[INFO] Figure enregistrée → zz-figures/chapter09/09_fig_02_residual_phase.png`

---

## 4. Scripts, données et figures impliqués

### 4.1. Scripts Python CH09 (logique scientifique)

Tous les scripts CH09 résident dans :

- `zz-scripts/chapter09/`

Scripts typiquement utilisés (directement ou via `smoke_ch09_fast.sh`) :

- `extract_phenom_phase.py`  
  → extrait la phase IMRPhenomD sur une grille `f_Hz` ;
- `generate_data_chapter09.py`  
  → construit la phase MCGT brute, le résidu standardisé et les premières métriques ;
- `opt_poly_rebranch.py`  
  → recherche la combinaison optimale (base, degré, rebranch `k`) pour minimiser
    `p95(|Δφ|)` sur 20–300 Hz ;
- `check_p95_methods.py`  
  → contrôle méthodologique (raw/unwrap/principal) et, si demandé,
    met à jour `metrics_active` dans `09_metrics_phase.json` ;
- `plot_fig01_phase_overlay.py`  
  → figure de superposition `φ_ref` / `φ_mcgt` avec encart résidu ;
- `plot_fig02_residual_phase.py`  
  → figure du résidu de phase par bandes de fréquence.

### 4.2. Données CH09 (inputs + outputs)

Répertoire principal :

- `zz-data/chapter09/`

Fichiers centraux pour le pipeline minimal calibré :

- `09_phases_imrphenom.csv`  
  → phase GR de référence (IMRPhenomD) sur une grille `f_Hz` ;

- `09_phases_mcgt.csv`  
  → phase MCGT **finale** après fit polynomial, unwrap et rebranch ;

- `09_phase_diff.csv`  
  → résidu de phase principal `|Δφ|` sur la même grille ;

- `09_metrics_phase.json`  
  → métriques calculées sur la bande 20–300 Hz (mean, median, p95, max, `rebranch_k`, etc.) ;

- `09_best_params.json`  
  → description de la configuration de fit retenue (base, degré, fenêtre, `k`, scores).

D’autres fichiers peuvent exister (jalons GWTC-3, diagnostics détaillés), mais ils
ne sont pas requis pour le pipeline minimal pur.

### 4.3. Figures CH09

Répertoire des figures :

- `zz-figures/chapter09/`

Figures principalement concernées par le pipeline minimal :

- `fig_01_phase_overlay.png`  
  → superposition `φ_ref` vs `φ_mcgt` (log‑x), avec encart `|Δφ|` ;

- `fig_02_residual_phase.png`  
  → résidu principal `|Δφ|` par bandes (20–300, 300–1000, 1000–2000 Hz).

Autres figures CH09 (hors strict pipeline minimal, mais structurantes pour le chapitre) :

- `fig_03_hist_absdphi_20_300.png`  
- `fig_04_absdphi_milestones_vs_f.png`  
- `fig_05_scatter_phi_at_fpeak.png`  
- `p95_check_control.png`

### 4.4. Données intermédiaires (zz-out)

Répertoire :

- `zz-out/chapter09/`

Fichiers utilisés pour la fig. 02 et les diagnostics :

- `fig02_input.csv`  
  → colonnes typiques `(f_Hz, phi_ref, phi_mcgt, dphi_principal, ... )`.

---

## 5. Pipeline détaillé – étape par étape

Les détails exacts dépendent de l’implémentation courante de
`zz-tools/smoke_ch09_fast.sh`, mais le schéma minimal canonique est :

### 5.1. (Optionnel) Régénérer la référence GR

Si nécessaire (p. ex. après mise à jour de LALSuite), on peut reconstruire
la phase IMRPhenom de référence :

```bash
python zz-scripts/chapter09/extract_phenom_phase.py \
  --out zz-data/chapter09/09_phases_imrphenom.csv
```

### 5.2. Pré‑traitement : phase MCGT brute et résidu

```bash
python zz-scripts/chapter09/generate_data_chapter09.py \
  --ref zz-data/chapter09/09_phases_imrphenom.csv \
  --out-prepoly zz-data/chapter09/09_phases_mcgt_prepoly.csv \
  --out-diff    zz-data/chapter09/09_phase_diff.csv \
  --log-level INFO
```

Ce script :

1. lit la phase de référence `09_phases_imrphenom.csv` ;
2. reconstruit la phase MCGT brute (avant correction polynomial + unwrap) ;
3. écrit `09_phases_mcgt_prepoly.csv` et un résidu principal brut dans `09_phase_diff.csv`.

### 5.3. Optimisation du fit polynomial et rebranch

```bash
python zz-scripts/chapter09/opt_poly_rebranch.py \
  --csv zz-data/chapter09/09_phases_mcgt_prepoly.csv \
  --meta zz-data/chapter09/09_metrics_phase.json \
  --fit-window 30 250 --metrics-window 20 300 \
  --degrees 3 4 5 --bases log10 hz --k-range -10 10 \
  --out-csv  zz-data/chapter09/09_phases_mcgt.csv \
  --out-best zz-data/chapter09/09_best_params.json \
  --backup --log-level INFO
```

Ce script :

1. teste plusieurs paires (base, degré) et valeurs de `k` dans la plage indiquée ;
2. retient la configuration minimisant `p95(|Δφ|)` sur 20–300 Hz ;
3. écrit la série finale `09_phases_mcgt.csv` et les paramètres associés
   dans `09_best_params.json` ;
4. initialise ou met à jour `09_metrics_phase.json` avec les métriques correspondantes.

### 5.4. Contrôle et mise à jour des métriques de phase

```bash
python zz-scripts/chapter09/check_p95_methods.py \
  --csv zz-data/chapter09/09_phases_mcgt.csv \
  --window 20 300 \
  --out  \
  --update-metrics-json zz-data/chapter09/09_metrics_phase.json
```

Ce script :

- recalcule le résidu principal `|Δφ|` sur 20–300 Hz ;
- produit une figure de diagnostic (`p95_check_control.png`) ;
- met à jour la section `metrics_active` de `09_metrics_phase.json` pour l’aligner
  sur le résidu principal effectivement utilisé.

### 5.5. Figures principales de phase

Une fois `09_phases_mcgt.csv` et `09_metrics_phase.json` à jour, on peut générer
les figures principales :

```bash
python zz-scripts/chapter09/plot_fig01_phase_overlay.py \
  --csv  zz-data/chapter09/09_phases_mcgt.csv \
  --meta zz-data/chapter09/09_metrics_phase.json \
  --out  zz-figures/chapter09/09_fig_01_phase_overlay.png \
  --shade 20 300 --show-residual \
  --display-variant auto --anchor-policy if-not-calibrated \
  --dpi 300 --save-pdf --log-level INFO

python zz-scripts/chapter09/plot_fig02_residual_phase.py \
  --csv  zz-data/chapter09/09_phases_mcgt.csv \
  --meta zz-data/chapter09/09_metrics_phase.json \
  --out  zz-figures/chapter09/09_fig_02_residual_phase.png \
  --bands 20 300 300 1000 1000 2000 \
  --dpi 300 --marker-size 3 --line-width 0.9 \
  --gap-thresh-log10 0.12 --log-level INFO
```

Ces deux scripts sont précisément ceux que `zz-tools/smoke_ch09_fast.sh`
est censé invoquer dans sa version canonique.

---

## 6. Produits finaux « officiels » pour le chapitre 09

Dans le cadre du pipeline minimal calibré, les **produits principaux** de CH09 sont :

### 6.1. Données

- `zz-data/chapter09/09_phases_mcgt.csv`  
  → phase MCGT finale (après fit, unwrap, rebranch) sur la grille `f_Hz` ;

- `zz-data/chapter09/09_phase_diff.csv`  
  → résidu principal `|Δφ|` correspondant à cette phase ;

- `zz-data/chapter09/09_metrics_phase.json`  
  → métriques de contrôle de phase sur la bande 20–300 Hz ;

- `zz-data/chapter09/09_best_params.json`  
  → description compacte de la configuration de fit retenue.

### 6.2. Figures

- `zz-figures/chapter09/09_fig_01_phase_overlay.png`  
- `zz-figures/chapter09/09_fig_02_residual_phase.png`  
- (diagnostic) `` (recommandé).

Les autres figures CH09 (`fig_03`, `fig_04`, `fig_05`) relèvent d’une analyse plus complète
et ne sont pas strictement nécessaires pour le pipeline minimal calibré, même si elles sont
importantes pour le manuscrit global.

---

## 7. Contrôle d’intégrité et manifests

Après exécution de `zz-tools/smoke_ch09_fast.sh` (ou des commandes détaillées ci‑dessus),
il est recommandé de lancer le diagnostic des manifests :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre :

- les fichiers de données / figures CH09 ;
- `zz-manifests/manifest_master.json` ;
- `zz-manifests/manifest_publication.json`.

Objectifs pour le pipeline minimal :

- aucune erreur de type `SHA_MISMATCH` ou fichier manquant sur les produits
  listés en §6 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent exister
  pendant les phases d’édition active, mais doivent être réduits au minimum
  au moment de la publication.

---

## 8. Méthodes numériques et calibration (rappel synthétique)

Les détails complets sont documentés dans les scripts CH09, mais les grandes lignes sont :

- **Résidu principal** :  
  on définit un résidu de phase principal `|Δφ|` après unwrap + rebranch d’un nombre
  entier de cycles `k`, choisi de manière à minimiser `p95(|Δφ|)` sur 20–300 Hz.

- **Fenêtre de fit vs fenêtre de métriques** :  
  le fit polynomial (`φ₀`, `t_c`, etc.) est généralement réalisé sur une fenêtre
  plus resserrée (par ex. [30, 250] Hz), tandis que les métriques sont calculées sur
  [20, 300] Hz.

- **Optimisation (opt_poly_rebranch)** :  
  on explore plusieurs bases (`log10(f)` ou `f`) et degrés polynomiaux, ainsi qu’une
  plage de `k` (rebranch), puis on retient la configuration offrant la meilleure
  stabilité (`p95` minimal, comportement régulier du résidu).

- **Métriques stockées** dans `09_metrics_phase.json` :

  - `metrics_active.rebranch_k`          → `k` retenu ;
  - `metrics_active.metrics_window_Hz`   → bande de référence (20–300 Hz) ;
  - `metrics_active.mean_abs_20_300`     → moyenne de `|Δφ|` ;
  - `metrics_active.median_abs_20_300`   → médiane de `|Δφ|` ;
  - `metrics_active.p95_abs_20_300`      → `p95(|Δφ|)` ;
  - `metrics_active.max_abs_20_300`      → max de `|Δφ|`.

Ces champs servent de **garde‑fou numérique** : toute modification du pipeline CH09
devrait maintenir des valeurs de `p95(|Δφ|)` dans une plage physiquement acceptable.

---

## 9. Notes LaTeX / versionnage & reproductibilité

- Les sources LaTeX du chapitre 09 se trouvent dans :

  - `09-phase-ondes-gravitationnelles/09_phase_ondes_grav_conceptuel.tex`
  - `09-phase-ondes-gravitationnelles/09_phase_ondes_grav_details.tex`

  Compilation (exemple) :

  ```bash
  pdflatex -interaction=nonstopmode 09-phase-ondes-gravitationnelles/09_phase_ondes_grav_conceptuel.tex
  pdflatex -interaction=nonstopmode 09-phase-ondes-gravitationnelles/09_phase_ondes_grav_details.tex
  ```

- Pour la **reproductibilité**, toute modification affectant les résultats CH09
  (données ou figures) devrait idéalement :

  - être effectuée dans une branche dédiée ;
  - être accompagnée d’une exécution propre de `bash zz-tools/smoke_ch09_fast.sh` ;
  - passer `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
  - mettre à jour `CHANGELOG.md` si les chiffres ou figures publiées changent.

Fin du document.
