# Chapitre 02 – Pipeline minimal canonique (validation chronologique & spectre primordial)

Ce document décrit le **pipeline minimal canonique** permettant de relancer, à partir du dépôt
MCGT, les calculs et figures essentiels du **chapitre 02 – validation chronologique & spectre primordial**.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- recalculer la chronologie \(P(T)\) et les écarts relatifs aux jalons d’âge cosmologique ;
- régénérer le spectre primordial MCGT et ses dérivés (séries F/G, As, n_s) ;
- produire les figures officielles du chapitre 02 ;
- vérifier rapidement que le chapitre est scientifiquement cohérent et techniquement exécutable.

---

## 1. Objectif

Le pipeline minimal CH02 s’appuie directement sur les scripts Python du chapitre 02 :

- `zz-scripts/chapter02/generate_data_chapter02.py`
- ``

Il est conçu pour :

- **reconstruire toutes les tables de données** listées en §4.2 ;
- **rafraîchir les figures principales** listées en §4.3 ;
- rester compatible avec les manifests (`manifest_master` et `manifest_publication`).

Ce pipeline ne dépend pas d’un wrapper shell spécifique : la séquence canonique est la
combinaison des commandes Python décrites en §3 et §5.

---

## 2. Pré‑requis

Depuis la racine du dépôt `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `scipy`, `matplotlib`, etc. ;
- Fichiers de configuration et d’entrée accessibles :

  - `zz-data/chapter02/02_milestones_meta.csv`
  - `zz-data/chapter02/02_primordial_spectrum_spec.json`

Les autres fichiers de données de CH02 (cf. §4.2) seront **recréés** ou mis à jour par
`generate_data_chapter02.py`.

---

## 3. Résumé rapide – séquence minimale recommandée

Depuis la racine du dépôt :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire

# 1) Générer / rafraîchir toutes les données du chapitre 02
python zz-scripts/chapter02/generate_data_chapter02.py --all

# 2) Régénérer les figures principales (fig. 00 à 06)
python zz-scripts/chapter02/plot_fig00_spectrum.py
python zz-scripts/chapter02/plot_fig01_P_vs_T_evolution.py
python zz-scripts/chapter02/plot_fig02_calibration.py
python zz-scripts/chapter02/plot_fig03_relative_errors.py
python zz-scripts/chapter02/plot_fig04_pipeline_diagram.py
python zz-scripts/chapter02/plot_fig05_FG_series.py
python zz-scripts/chapter02/plot_fig06_alpha_fit.py
```

Si tout se passe bien, `generate_data_chapter02.py` affiche un message de succès et les
figures sont (re)créées dans `zz-figures/chapter02/`.

---

## 4. Scripts, données et figures impliqués

### 4.1. Scripts Python (logique scientifique)

Répertoire CH02 :

- `zz-scripts/chapter02/`

Scripts utilisés par le pipeline minimal :

- `generate_data_chapter02.py`
- `plot_fig00_spectrum.py`
- `plot_fig01_P_vs_T_evolution.py`
- `plot_fig02_calibration.py`
- `plot_fig03_relative_errors.py`
- `plot_fig04_pipeline_diagram.py`
- `plot_fig05_FG_series.py`
- `plot_fig06_alpha_fit.py`

Un fichier `requirements.txt` peut documenter les dépendances spécifiques :
``.

### 4.2. Données CH02 (inputs + outputs)

Répertoire principal :

- `zz-data/chapter02/`

Fichiers typiques pour le pipeline minimal :

- **Entrées / méta & spécifications** :
  - `02_milestones_meta.csv`  
    → métadonnées des jalons temporels (T_Gyr, P_ref, classe primaire/ordre2).
  - `02_primordial_spectrum_spec.json`  
    → spécification du spectre primordial (formule, constantes, coefficients).

- **Chronologie & écarts** :
  - `02_timeline_milestones.csv`  
    → jalons triés en temps, P_ref, P_opt, epsilon_i, classe.
  - `02_relative_error_timeline.csv`  
    → écarts relatifs \(\epsilon_i\) aux jalons.

- **Courbe dense & dérivée** :
  - `02_P_vs_T_grid_data.dat`  
    → courbe dense \(P_{
m calc}(T)\) sur une grille log-uniforme en `T_Gyr`.
  - `02_P_derivative_data.dat`  
    → dérivée lissée \(\dot P(T)\) sur la même grille.

- **Spectre primordial & paramètres** :
  - `02_P_R_sampling.csv`  
    → échantillonnage \(P_R(k; lpha)\) pour différentes valeurs de \( lpha\).
  - `02_As_ns_vs_alpha.csv`  
    → paramètres spectraux \((A_s, n_s)\) en fonction de \( lpha\).
  - `02_FG_series.csv`  
    → coefficients de séries F/G liés au spectre primordial.
  - `02_optimal_parameters.json`  
    → paramètres optimaux de calibration chronologique (T_split, segments, seuils, maxima d’epsilon).

### 4.3. Figures CH02

Répertoire :

- `zz-figures/chapter02/`

Figures principales :

- `fig_00_spectrum.png`                – spectre primordial MCGT (log–log).  
- `fig_01_P_vs_T_evolution.png`        – \(P_{
m calc}(T)\) vs jalons \(P_{
m ref}(T_i)\).  
- `fig_02_calibration.png`             – nuage \(P_{
m ref}\) vs \(P_{
m calc}\) + ligne d’identité.  
- `fig_03_relative_errors.png`         – \(\epsilon_i\) vs \(T\) (primaires vs ordre2).  
- `fig_04_pipeline_diagram.png`        – schéma du pipeline de calcul.  
- `fig_05_FG_series.png`               – séries \(F( lpha)-1\) et \(G( lpha)\).  
- `fig_06_fit_alpha.png`               – ajustements \(A_s( lpha)\) et \(n_s( lpha)\).  

---

## 5. Pipeline détaillé – étape par étape

### 5.1. Génération des données (pipeline chronologie + spectre)

Depuis la racine du dépôt :

```bash
python zz-scripts/chapter02/generate_data_chapter02.py --all
```

Comportement canonique (schéma logique) :

1. **Lecture des jalons et de la spécification du spectre** :
   - lit `02_milestones_meta.csv` (T_Gyr, P_ref, classe) ;
   - lit `02_primordial_spectrum_spec.json` (formule, constantes, coefficients).

2. **Construction de la chronologie dense \(P(T)\)** :
   - construit une grille log-uniforme en `T_Gyr` (typ. [1e-6, 14] Gyr) ;
   - évalue \(P_{
m calc}(T)\) sur cette grille ;
   - enregistre la courbe dense dans `02_P_vs_T_grid_data.dat`.

3. **Dérivée lissée \(\dot P(T)\)** :
   - calcule \(\dot P(T)\) (différences finies ou équivalent) ;
   - applique un filtre de lissage (type Savitzky–Golay) avec fenêtre & ordre
     cohérents avec CH01/CH05 ;
   - stocke les résultats dans `02_P_derivative_data.dat`.

4. **Chronologie des jalons** :
   - assemble `02_timeline_milestones.csv` avec :
     - `T_Gyr` (jalons) ;
     - `P_ref` (valeur de référence) ;
     - `P_opt` (valeur optimisée/calculée) ;
     - `epsilon_i` (écart relatif) ;
     - `classe` (primary / order2).
   - extrait les écarts dans `02_relative_error_timeline.csv` pour inspection rapide.

5. **Spectre primordial \(P_R(k; lpha)\)** :
   - évalue \(P_R(k; lpha)\) pour une grille en \( lpha\) et en k ;
   - écrit `02_P_R_sampling.csv` (colonnes typiques : alpha, k, P_R).

6. **Paramètres spectraux (As, n_s)** :
   - ajuste/évalue \((A_s, n_s)\) en fonction de \( lpha\) ;
   - écrit `02_As_ns_vs_alpha.csv`.

7. **Séries F/G** :
   - calcule les coefficients des séries F et G (ordre 0,1,2,…) ;
   - stocke dans `02_FG_series.csv` (colonnes typiques : func, order, coeff).

8. **Paramètres optimaux** :
   - estime les paramètres optimaux de la chronologie (par ex. `T_split_Gyr`, segments
     `low/high` avec `alpha0`, `alpha_inf`, `Tc`, `Delta`, `Tp`) ;
   - calcule les maxima d’écarts : `max_epsilon_primary`, `max_epsilon_order2` ;
   - enregistre le tout dans `02_optimal_parameters.json`.

En cas de succès, le script termine avec un code 0 et laisse tous les fichiers de §4.2
dans un état cohérent.

### 5.2. Figures CH02

Une fois les données générées, les figures sont (re)calculées avec :

```bash
python zz-scripts/chapter02/plot_fig00_spectrum.py
python zz-scripts/chapter02/plot_fig01_P_vs_T_evolution.py
python zz-scripts/chapter02/plot_fig02_calibration.py
python zz-scripts/chapter02/plot_fig03_relative_errors.py
python zz-scripts/chapter02/plot_fig04_pipeline_diagram.py
python zz-scripts/chapter02/plot_fig05_FG_series.py
python zz-scripts/chapter02/plot_fig06_alpha_fit.py
```

Chaque script lit les tables correspondantes dans `zz-data/chapter02/` et écrit la
figure finale dans `zz-figures/chapter02/` (cf. §4.3).

---

## 6. Produits finaux « officiels » pour le chapitre 02

Dans le cadre du pipeline minimal canonique, les **produits principaux** de CH02 sont :

### 6.1. Données

- `zz-data/chapter02/02_timeline_milestones.csv`  
  → chronologie des jalons, avec P_ref, P_opt, epsilon_i, classe.

- `zz-data/chapter02/02_P_vs_T_grid_data.dat`  
  → courbe dense \(P_{
m calc}(T)\) sur la grille en `T_Gyr`.

- `zz-data/chapter02/02_P_derivative_data.dat`  
  → dérivée lissée \(\dot P(T)\) sur la même grille.

- `zz-data/chapter02/02_relative_error_timeline.csv`  
  → écarts relatifs aux jalons, exploitables pour le contrôle qualité.

- `zz-data/chapter02/02_optimal_parameters.json`  
  → paramètres optimaux de calibration chronologique (T_split, segments, seuils).

- `zz-data/chapter02/02_P_R_sampling.csv`  
  → échantillonnage du spectre primordial \(P_R(k; lpha)\).

- `zz-data/chapter02/02_As_ns_vs_alpha.csv`  
  → relation \((A_s, n_s)\) vs \( lpha\).

- `zz-data/chapter02/02_FG_series.csv`  
  → coefficients des séries F/G associées au spectre primordial.

### 6.2. Figures

- `zz-figures/chapter02/02_fig_00_spectrum.png`  
- `zz-figures/chapter02/02_fig_01_p_vs_t_evolution.png`  
- `zz-figures/chapter02/02_fig_02_calibration.png`  
- `zz-figures/chapter02/02_fig_03_relative_errors.png`  
- `zz-figures/chapter02/02_fig_04_pipeline_diagram.png`  
- `zz-figures/chapter02/02_fig_05_fg_series.png`  
- `zz-figures/chapter02/02_fig_06_alpha_fit.png`  

Ces fichiers constituent la **référence** pour la relecture et la publication du chapitre 02.

---

## 7. Contrôle d’intégrité et manifests

Après exécution du pipeline minimal, il est recommandé de lancer le diagnostic des manifests :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre :

- les fichiers de données / figures CH02 ;
- `zz-manifests/manifest_master.json` ;
- `zz-manifests/manifest_publication.json`.

Objectifs pour le pipeline minimal :

- aucune erreur de type `SHA_MISMATCH` ou fichier manquant sur les produits
  listés en §6.1–6.2 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent exister
  pendant les phases d’édition active, mais doivent être réduits au minimum
  au moment de la publication.

---

## 8. Paramètres & méthodes numériques (rappel synthétique)

Les détails complets sont documentés dans les scripts CH02, mais les grandes lignes sont :

- **Grille temporelle `T_Gyr`** :
  - log-uniforme sur un intervalle typique `[1e-6, 14]` Gyr ;
  - densité contrôlée par un pas quasi constant en `log10(T_Gyr)`.

- **Chronologie \(P(T)\)** :
  - \(P_{
m calc}(T)\) construit sur la grille dense ;
  - jalons extraits/interpolés pour comparaison à `P_ref`.

- **Dérivée lissée \(\dot P(T)\)** :
  - dérivée numérique puis lissage (type Savitzky–Golay, fenêtre & ordre
    harmonisés avec CH01/CH05) ;
  - objectif : courbe \(\dot P(T)\) sans oscillations parasites.

- **Spectre primordial \(P_R(k; lpha)\)** :
  - défini via `02_primordial_spectrum_spec.json` (formule, constantes, coefficients) ;
  - notation harmonisée avec les chapitres 01 et 06 (paramètres globaux MCGT).

- **Paramètres spectraux (As, n_s)** :
  - calculés/ajustés pour chaque \( lpha\) étudié ;
  - exploitables dans CH06 (Cℓ) et dans les discussions globales.

- **Séries F/G** :
  - séries développées en fonction de \( lpha\) ;
  - coefficients stockés dans `02_FG_series.csv` pour réutilisation ultérieure.

- **Seuils de contrôle** :
  - `thresholds.primary`, `thresholds.order2` et les maxima
    `max_epsilon_primary`, `max_epsilon_order2` sont consignés dans
    `02_optimal_parameters.json` pour assurer la cohérence avec les autres chapitres.

---

## 9. Notes LaTeX / versionnage & reproductibilité

- Les sources LaTeX du chapitre 02 se trouvent dans :

  - `02-validation-chronologique/02_validation_chronologique_conceptuel.tex`
  - `02-validation-chronologique/02_validation_chronologique_details.tex`

  Compilation (exemple) :

  ```bash
  pdflatex -interaction=nonstopmode 02-validation-chronologique/02_validation_chronologique_conceptuel.tex
  pdflatex -interaction=nonstopmode 02-validation-chronologique/02_validation_chronologique_details.tex
  ```

- Pour la **reproductibilité**, toute modification affectant les résultats CH02
  (données ou figures) devrait idéalement :

  - être effectuée dans une branche dédiée ;
  - être accompagnée d’une exécution propre du pipeline minimal (commande §3) ;
  - passer `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
  - mettre à jour `CHANGELOG.md` si les chiffres ou figures publiées changent.

Fin du document.
