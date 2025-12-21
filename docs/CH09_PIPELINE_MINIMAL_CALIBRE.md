# Chapitre 09 – Pipeline minimal calibré (phase gravitationnelle)

Ce document décrit le **pipeline minimal calibré** permettant de relancer, à partir du dépôt
MCGT, les calculs et figures essentiels du **chapitre 09 – phase gravitationnelle
(IMRPhenom vs MCGT)**.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- recalculer `09_metrics_phase.json` sur la bande de référence (20–300 Hz) ;
- régénérer les deux figures de phase principales ;
- vérifier rapidement que la chaîne de calcul CH09 reste cohérente numériquement.

Ce pipeline repose sur :

- un script shell canonique (quand il est présent/configuré) :  
  `tools/smoke_ch09_fast.sh` ;
- et, en parallèle, une **séquence minimale manuelle** que tu as effectivement testée.

---

## 1. Objectif

Le pipeline minimal CH09 est conçu pour :

- tester rapidement la **cohérence de phase** entre MCGT et IMRPhenom ;
- vérifier que la **fenêtre de calibration** (fit sur [30, 250] Hz, métriques sur [20, 300] Hz)
  donne des résultats stables ;
- actualiser les **métriques de contrôle** dans `09_metrics_phase.json` ;
- régénérer les **figures principales** utilisées dans le chapitre (superposition de phase,
  résidu de phase).

Il ne vise pas à reconstruire toute la chaîne GWTC-3 (multi-événements), mais à
assurer la stabilité du cœur de l’analyse de phase sur **un cas représentatif**.

---

## 2. Pré-requis

Depuis la racine du dépôt `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `matplotlib`, (optionnel : `scipy`, `h5py`, `lalsuite`) ;
- Fichiers de configuration et de données déjà présents (suivis par les manifests) :

  - `config/GWTC-3-confident-events.json`
  - `assets/zz-data/chapter09/gwtc3_confident_parameters.json`
  - `assets/zz-data/chapter09/09_phases_imrphenom.csv`  (phase IMRPhenom de référence)
  - `assets/zz-data/chapter09/09_phases_mcgt.csv`       (phase MCGT finale, déjà construite)

Les chemins supposent la hiérarchie standard du dépôt MCGT.

---

## 3. Résumé rapide – deux façons de lancer

### 3.1. Version “boîte noire” (script smoke, si disponible)

Depuis la racine du dépôt :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire
bash tools/smoke_ch09_fast.sh
```

Ce script effectue automatiquement, de manière compacte, les opérations suivantes
(résumé basé sur les logs historiques) :

1. Chargement de la référence IMRPhenom (`09_phases_imrphenom.csv`)
   et des phases MCGT (`09_phases_mcgt.csv`) ;
2. Calage de la phase (`φ₀`, `t_c`) par ajustement pondéré
   (poids typiques en `1/f²`) sur une fenêtre de fit (par ex. [30, 250] Hz) ;
3. Contrôle de la dispersion `p95(|Δφ|)` sur la bande [20, 300] Hz ;
4. Resserrement éventuel de la fenêtre de fit, puis nouveau calage ;
5. Mise à jour des métriques dans :

   - `assets/zz-data/chapter09/09_metrics_phase.json` ;

6. Génération des figures de phase :

   - `assets/zz-figures/chapter09/09_fig_01_phase_overlay.png`
   - `assets/zz-figures/chapter09/09_fig_02_residual_phase.png`.

---

### 3.2. Version **manuelle minimale** (celle que tu viens d’exécuter)

Cette séquence est **testée sur ton dépôt** (logs du 2025-12-10) et ne dépend que
des chemins par défaut codés dans les scripts :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire

# 1) Recalcul des métriques de phase (en utilisant la référence existante)
python scripts/chapter09/generate_data_chapter09.py

# 2) Superposition de phase IMRPhenom vs MCGT
python scripts/chapter09/10_fig01_phase_overlay.py

# 3) Résidu de phase par bandes (20–300 Hz, etc.)
python scripts/chapter09/10_fig02_residual_phase.py
```

Dans les logs fournis, on observe typiquement :

- calcul avec paramètres MCGT par défaut (`PhaseParams(...)`) ;
- réutilisation de la référence existante (`09_phases_mcgt.csv`) sauf si `--overwrite` ;
- écriture / mise à jour de `assets/zz-data/chapter09/09_metrics_phase.json` ;
- génération / mise à jour de :

  - `assets/zz-figures/chapter09/09_fig_01_phase_overlay.png`
  - `assets/zz-figures/chapter09/09_fig_02_residual_phase.png`.

C’est **cette séquence** qui constitue, en pratique, ton **pipeline minimal CH09**.

---

## 4. Scripts, données et figures impliqués

### 4.1. Scripts Python CH09 (logique scientifique)

Tous les scripts CH09 résident dans :

- `scripts/chapter09/`

Scripts principaux (utilisés directement ou via le smoke script) :

- `generate_data_chapter09.py`  
  → reconstruit la phase MCGT sur la grille fréquentielle, met à jour
  `09_metrics_phase.json` et, selon la configuration, peut (ré)écrire
  certains CSV de support.

- `10_fig01_phase_overlay.py`  
  → figure de superposition `φ_ref` / `φ_mcgt` avec encart résidu.

- `10_fig02_residual_phase.py`  
  → figure du résidu de phase par bandes de fréquence (20–300, 300–1000, etc.) ;
  recalcule les métriques 20–300 Hz et peut les refléter dans `09_metrics_phase.json`.

Scripts **plus avancés / optionnels** (selon l’état de ton dépôt) :

- `extract_phenom_phase.py`  
  → extrait la phase IMRPhenomD sur une grille `f_Hz` ;

- `opt_poly_rebranch.py`  
  → recherche la combinaison optimale (base, degré, rebranch `k`) pour minimiser
    `p95(|Δφ|)` sur 20–300 Hz ;

- `check_p95_methods.py`  
  → contrôle méthodologique (raw/unwrap/principal), génère un diagnostic
    `p95_check_control.png` et peut ajuster la section `metrics_active` de
    `09_metrics_phase.json`.

Ces scripts avancés ne sont **pas** strictement nécessaires pour le pipeline minimal,
mais représentent l’architecture complète de CH09.

---

### 4.2. Données CH09 (inputs + outputs)

Répertoire principal :

- `assets/zz-data/chapter09/`

Fichiers centraux pour le pipeline minimal calibré :

- `09_phases_imrphenom.csv`  
  → phase GR de référence (IMRPhenomD) sur une grille `f_Hz` ;

- `09_phases_mcgt.csv`  
  → phase MCGT **finale** après fit polynomial, unwrap et rebranch ;

- `09_phase_diff.csv`  
  → résidu de phase principal `|Δφ|` sur la même grille ;

- `09_metrics_phase.json`  
  → métriques calculées sur la bande 20–300 Hz (mean, median, p95, max, `rebranch_k`, etc.) ;

- `09_best_params.json` (si présent)  
  → description de la configuration de fit retenue (base, degré, fenêtre, `k`, scores).

D’autres fichiers peuvent exister (jalons GWTC-3, diagnostics détaillés), mais ils
ne sont pas requis pour le pipeline minimal pur.

---

### 4.3. Figures CH09

Répertoire des figures :

- `assets/zz-figures/chapter09/`

Figures principalement concernées par le pipeline minimal :

- `09_fig_01_phase_overlay.png`  
  → superposition `φ_ref` vs `φ_mcgt` (log-x), avec encart `|Δφ|` ;

- `09_fig_02_residual_phase.png`  
  → résidu principal `|Δφ|` par bandes (20–300, 300–1000, 1000–2000 Hz).

Autres figures CH09 (hors strict pipeline minimal, mais structurantes pour le chapitre) :

- `09_fig_03_hist_absdphi_20_300.png`
- `09_fig_04_absdphi_milestones_vs_f.png`
- `09_fig_05_scatter_phi_at_fpeak.png`
- `p95_check_control.png`

---

### 4.4. Données intermédiaires (zz-out)

Répertoire :

- `zz-out/chapter09/`

Fichiers utilisés pour la fig. 02 et les diagnostics :

- `fig02_input.csv`  
  → colonnes typiques `(f_Hz, phi_ref, phi_mcgt, dphi_principal, ... )`.

---

## 5. Pipeline détaillé – étape par étape

Les détails exacts dépendent de l’implémentation courante de
`tools/smoke_ch09_fast.sh`, mais le schéma minimal canonique est :

### 5.1. (Optionnel) Régénérer la référence GR

Si nécessaire (p. ex. après mise à jour de LALSuite), on peut reconstruire
la phase IMRPhenom de référence :

```bash
python scripts/chapter09/extract_phenom_phase.py   --out assets/zz-data/chapter09/09_phases_imrphenom.csv
```

Cette étape n’est pas requise pour un simple contrôle de cohérence si la
référence existante est jugée fiable.

---

### 5.2. Recalcul des données de phase et métriques (version réelle minimaliste)

En pratique, tel que tu l’as lancé, un simple :

```bash
python scripts/chapter09/generate_data_chapter09.py
```

suffit.  
Le script lit les fichiers de configuration / données par défaut (dont
`09_phases_imrphenom.csv` et les paramètres GWTC-3), puis :

1. recalcule la phase MCGT (ou la valide si déjà présente) ;
2. met à jour `09_metrics_phase.json` avec les métriques de contrôle
   sur [20, 300] Hz ;
3. conserve `09_phases_mcgt.csv` existant sauf si l’option `--overwrite`
   est explicitement demandée.

Version plus détaillée (à adapter en fonction de `--help` si tu réintroduis des
options explicites) :

```bash
python scripts/chapter09/generate_data_chapter09.py   --log-level INFO
```

---

### 5.3. Optimisation du fit polynomial et rebranch (bloc avancé)

Si tu souhaites explorer / documenter la logique interne de fit (base, degré,
rebranch `k`) de façon explicite, ce bloc décrit le principe (à adapter selon
l’API réelle de `opt_poly_rebranch.py`) :

```bash
python scripts/chapter09/opt_poly_rebranch.py   --csv assets/zz-data/chapter09/09_phases_mcgt_prepoly.csv   --meta assets/zz-data/chapter09/09_metrics_phase.json   --fit-window 30 250 --metrics-window 20 300   --degrees 3 4 5 --bases log10 hz --k-range -10 10   --out-csv  assets/zz-data/chapter09/09_phases_mcgt.csv   --out-best assets/zz-data/chapter09/09_best_params.json   --backup --log-level INFO
```

Idée générale :

- tester plusieurs `(base, degré, k)` ;
- minimiser `p95(|Δφ|)` sur 20–300 Hz ;
- écrire la série finale dans `09_phases_mcgt.csv` et la configuration
  dans `09_best_params.json` ;
- synchroniser `09_metrics_phase.json` avec cette configuration.

Si, à un moment, cette API diverge de ton dépôt, la séquence minimale de §3.2
reste la **référence opérationnelle**.

---

### 5.4. Contrôle méthodologique p95 (bloc avancé)

Bloc optionnel, orienté QC / méthodo :

```bash
python scripts/chapter09/check_p95_methods.py   --csv assets/zz-data/chapter09/09_phases_mcgt.csv   --window 20 300   --update-metrics-json assets/zz-data/chapter09/09_metrics_phase.json
```

Ce script :

- recalcule le résidu principal `|Δφ|` sur 20–300 Hz ;
- compare éventuellement plusieurs méthodes (raw, unwrap, principal) ;
- met à jour la section `metrics_active` de `09_metrics_phase.json` ;
- peut générer un diagnostic `p95_check_control.png`.

---

### 5.5. Figures principales de phase

Une fois `09_metrics_phase.json` à jour et les CSV cohérents, tu peux
générer (ou regénérer) les figures principales.

#### 5.5.1. Superposition de phase (Fig. 01)

Version minimale (par défaut, le script cherche les bons fichiers) :

```bash
python scripts/chapter09/10_fig01_phase_overlay.py
```

Version avec arguments explicites (à utiliser si tu veux documenter les paths) :

```bash
python scripts/chapter09/10_fig01_phase_overlay.py   --csv  assets/zz-data/chapter09/09_phases_mcgt.csv   --meta assets/zz-data/chapter09/09_metrics_phase.json   --out  assets/zz-figures/chapter09/09_fig_01_phase_overlay.png   --shade 20 300 --show-residual   --display-variant auto --anchor-policy if-not-calibrated   --dpi 300 --save-pdf --log-level INFO
```

#### 5.5.2. Résidu de phase par bandes (Fig. 02)

Version minimale (celle que tu as exécutée) :

```bash
python scripts/chapter09/10_fig02_residual_phase.py
```

Version avec arguments explicites :

```bash
python scripts/chapter09/10_fig02_residual_phase.py   --csv  assets/zz-data/chapter09/09_phases_mcgt.csv   --meta assets/zz-data/chapter09/09_metrics_phase.json   --out  assets/zz-figures/chapter09/09_fig_02_residual_phase.png   --bands 20 300 300 1000 1000 2000   --dpi 300 --marker-size 3 --line-width 0.9   --gap-thresh-log10 0.12 --log-level INFO
```

Dans tes derniers logs, ce script affiche notamment :

- un avertissement bénin sur la lecture d’un JSON méta (`'float' object has no attribute 'get'`) ;
- les métriques **finales** sur 20–300 Hz après rebranch :
  `mean`, `p95`, `max`, etc. ;
- l’écriture de `09_fig_01_phase_overlay.png` et `09_fig_02_residual_phase.png`.

---

## 6. Produits finaux « officiels » pour le chapitre 09

Dans le cadre du pipeline minimal calibré, les **produits principaux** de CH09 sont :

### 6.1. Données

- `assets/zz-data/chapter09/09_phases_mcgt.csv`  
  → phase MCGT finale (après fit, unwrap, rebranch) sur la grille `f_Hz` ;

- `assets/zz-data/chapter09/09_phase_diff.csv`  
  → résidu principal `|Δφ|` correspondant à cette phase ;

- `assets/zz-data/chapter09/09_metrics_phase.json`  
  → métriques de contrôle de phase sur la bande 20–300 Hz ;

- `assets/zz-data/chapter09/09_best_params.json` (si utilisé)  
  → description compacte de la configuration de fit retenue.

### 6.2. Figures

- `assets/zz-figures/chapter09/09_fig_01_phase_overlay.png`
- `assets/zz-figures/chapter09/09_fig_02_residual_phase.png`
- (diagnostic recommandé) `` (si généré).

Les autres figures CH09 (`fig_03`, `fig_04`, `fig_05`) relèvent d’une analyse plus complète
et ne sont pas strictement nécessaires pour le pipeline minimal calibré, même si elles sont
importantes pour le manuscrit global.

---

## 7. Contrôle d’intégrité et manifests

Après exécution de la séquence minimale (§3.2) ou du smoke script, il est recommandé
de lancer le diagnostic des manifests :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre :

- les fichiers de données / figures CH09 ;
- `assets/zz-manifests/manifest_master.json` ;
- `assets/zz-manifests/manifest_publication.json`.

Objectifs pour le pipeline minimal :

- aucune erreur de type `SHA_MISMATCH` ou fichier manquant sur les produits
  listés en §6 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent exister
  pendant les phases d’édition active, mais doivent être réduits au minimum
  au moment de la publication.

---

## 8. Méthodes numériques et calibration (rappel synthétique)

Les détails complets sont documentés dans les scripts CH09, mais les grandes lignes sont :

- **Résidu principal** :  
  on définit un résidu de phase principal `|Δφ|` après unwrap + rebranch d’un nombre
  entier de cycles `k`, choisi de manière à minimiser `p95(|Δφ|)` sur 20–300 Hz.

- **Fenêtre de fit vs fenêtre de métriques** :  
  le fit polynomial (`φ₀`, `t_c`, etc.) est généralement réalisé sur une fenêtre
  plus resserrée (par ex. [30, 250] Hz), tandis que les métriques sont calculées sur
  [20, 300] Hz.

- **Optimisation (opt_poly_rebranch)** :  
  on explore plusieurs bases (`log10(f)` ou `f`) et degrés polynomiaux, ainsi qu’une
  plage de `k` (rebranch), puis on retient la configuration offrant la meilleure
  stabilité (`p95` minimal, comportement régulier du résidu).

- **Métriques stockées** dans `09_metrics_phase.json` :

  - `metrics_active.rebranch_k`          → `k` retenu ;
  - `metrics_active.metrics_window_Hz`   → bande de référence (20–300 Hz) ;
  - `metrics_active.mean_abs_20_300`     → moyenne de `|Δφ|` ;
  - `metrics_active.median_abs_20_300`   → médiane de `|Δφ|` ;
  - `metrics_active.p95_abs_20_300`      → `p95(|Δφ|)` ;
  - `metrics_active.max_abs_20_300`      → max de `|Δφ|`.

Ces champs servent de **garde-fou numérique** : toute modification du pipeline CH09
devrait maintenir des valeurs de `p95(|Δφ|)` dans une plage physiquement acceptable.

---

## 9. Notes LaTeX / versionnage & reproductibilité

- Les sources LaTeX du chapitre 09 se trouvent dans :

  - `09-phase-ondes-gravitationnelles/09_phase_ondes_grav_conceptuel.tex`
  - `09-phase-ondes-gravitationnelles/09_phase_ondes_grav_details.tex`

  Compilation (exemple) :

  ```bash
  pdflatex -interaction=nonstopmode 09-phase-ondes-gravitationnelles/09_phase_ondes_grav_conceptuel.tex
  pdflatex -interaction=nonstopmode 09-phase-ondes-gravitationnelles/09_phase_ondes_grav_details.tex
  ```

- Pour la **reproductibilité**, toute modification affectant les résultats CH09
  (données ou figures) devrait idéalement :

  - être effectuée dans une branche dédiée ;
  - être accompagnée d’une exécution propre de la séquence minimale (§3.2) ou du
    smoke script ;
  - passer `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
  - mettre à jour `CHANGELOG.md` si les chiffres ou figures publiées changent.

Fin du document.
