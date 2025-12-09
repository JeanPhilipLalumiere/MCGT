# Chapitre 01 – Pipeline minimal canonique (introduction & calibration)

Ce document décrit le **pipeline minimal canonique** permettant de régénérer, à partir du dépôt
MCGT, les données et figures essentielles du **chapitre 01 – introduction & applications
(calibration de P(T))**.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- générer les jeux de données optimisés du chapitre 01 ;
- produire l’ensemble des figures de calibration (Fig. 01 à 06) ;
- vérifier rapidement que le chapitre est scientifiquement cohérent et techniquement exécutable.

---

## 1. Objectif

Le pipeline minimal CH01 repose sur le script scientifique principal :

- `zz-scripts/chapter01/generate_data_chapter01.py`

complété par une petite famille de scripts de figures.  
Il est conçu pour :

- reconstruire la fonction propre calibrée \(P_{\rm calc}(T)\) à partir :
  - des jalons `01_timeline_milestones.csv` ;
  - de la grille initiale `01_initial_grid_data.dat` ;
- calculer les dérivées lissées, les erreurs relatives et les invariants de base ;
- régénérer les figures officielles du chapitre 01.

---

## 2. Pré‑requis

Depuis la racine du dépôt `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `scipy`, `matplotlib`, etc. ;
- Fichiers d’entrée CH01 présents dans `zz-data/chapter01/` :

  - `01_timeline_milestones.csv`
  - `01_initial_grid_data.dat`

Les chemins sont supposés suivre la hiérarchie standard du dépôt MCGT.

---

## 3. Résumé rapide – séquence minimale

Depuis la racine du dépôt :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire

# 1) Générer toutes les données CH01
python zz-scripts/chapter01/generate_data_chapter01.py

# 2) Produire toutes les figures CH01
python zz-scripts/chapter01/plot_fig01_early_plateau.py
python zz-scripts/chapter01/plot_fig02_logistic_calibration.py
python zz-scripts/chapter01/plot_fig03_relative_error_timeline.py
python zz-scripts/chapter01/plot_fig04_P_vs_T_evolution.py
python zz-scripts/chapter01/plot_fig05_I1_vs_T.py
python zz-scripts/chapter01/plot_fig06_P_derivative_comparison.py
```

Si tout se passe bien, les fichiers listés en §4 et §6 sont présents et cohérents.

---

## 4. Scripts, données et figures impliqués

### 4.1. Scripts Python (logique scientifique)

Répertoire CH01 :

- `zz-scripts/chapter01/`

Scripts utilisés par le pipeline minimal :

- `generate_data_chapter01.py`
- `plot_fig01_early_plateau.py`
- `plot_fig02_logistic_calibration.py`
- `plot_fig03_relative_error_timeline.py`
- `plot_fig04_P_vs_T_evolution.py`
- `plot_fig05_I1_vs_T.py`
- `plot_fig06_P_derivative_comparison.py`

### 4.2. Données CH01 (inputs + outputs)

Répertoire principal :

- `zz-data/chapter01/`

**Entrées :**

- `01_timeline_milestones.csv`  
  Jalons temporels et valeurs de référence \(P_{\rm ref}(T_i)\).

- `01_initial_grid_data.dat`  
  Grille initiale \(T, P_{\rm init}(T)\) sur un intervalle log‑uniforme.

**Sorties générées par le pipeline minimal :**

- `01_optimized_data.csv`
- `01_optimized_grid_data.dat`
- `01_P_derivative_initial.csv`
- `01_P_derivative_optimized.csv`
- `01_optimized_data_and_derivatives.csv`
- `01_relative_error_timeline.csv`
- `01_dimensionless_invariants.csv`

Les colonnes attendues sont rappelées en §5.2.

### 4.3. Figures CH01

Répertoire :

- `zz-figures/chapter01/`

Figures principales :

- `fig_01_early_plateau.png`
- `fig_02_logistic_calibration.png`
- `fig_03_relative_error_timeline.png`
- `fig_04_P_vs_T_evolution.png`
- `fig_05_I1_vs_T.png`
- `fig_06_P_derivative_comparison.png`

---

## 5. Pipeline détaillé – étape par étape

### 5.1. Génération des données CH01

Depuis la racine :

```bash
python zz-scripts/chapter01/generate_data_chapter01.py
```

Ce script :

1. **Charge les jalons de référence** dans :

   - `zz-data/chapter01/01_timeline_milestones.csv`

   Colonnes typiques :

   | Colonne | Description                               | Unité |
   |:-------:|:------------------------------------------|:-----:|
   | `T`     | Âge propre du système                     |  Gyr  |
   | `P_ref` | Valeur de référence pour la calibration   |  —    |

2. **Charge la grille initiale** dans :

   - `zz-data/chapter01/01_initial_grid_data.dat`

   Colonnes :

   | Colonne | Description                           | Unité |
   |:-------:|:--------------------------------------|:-----:|
   | `T`     | Grille temporelle (log‑uniforme)      |  Gyr  |
   | `P_init`| Valeur préliminaire de \(P(T)\)     |  —    |

3. **Optimise la courbe \(P(T)\)** (par ex. via une calibration logistique ou équivalente)
   pour obtenir une courbe \(P_{\rm calc}(T)\) lisse et compatible avec les jalons, et
   l’enregistre dans :

   - `zz-data/chapter01/01_optimized_data.csv`
   - `zz-data/chapter01/01_optimized_grid_data.dat`

   Schéma de colonnes :

   | Colonne | Description                             | Unité |
   |:-------:|:----------------------------------------|:-----:|
   | `T`     | Grille temporelle (log‑uniforme)        |  Gyr  |
   | `P_calc`| Valeur optimisée de la fonction propre  |  —    |

4. **Calcule les dérivées lissées** (avant et après optimisation), typiquement via
   un filtre de Savitzky–Golay, et les enregistre dans :

   - `zz-data/chapter01/01_P_derivative_initial.csv`
   - `zz-data/chapter01/01_P_derivative_optimized.csv`

   Colonnes :

   | Colonne | Description                     | Unité |
   |:-------:|:--------------------------------|:-----:|
   | `T`     | Grille temporelle              |  Gyr  |
   | `dP_dT` | Dérivée lissée de \(P(T)\)   | Gyr⁻¹ |

5. **Assemble les données optimisées + dérivées** dans un fichier synthétique :

   - `zz-data/chapter01/01_optimized_data_and_derivatives.csv`

   Colonnes :

   | Colonne | Description                             | Unité |
   |:-------:|:----------------------------------------|:-----:|
   | `T`     | Grille temporelle                       |  Gyr  |
   | `P_calc`| Valeur optimisée de \(P(T)\)          |  —    |
   | `dP_dT` | Dérivée optimisée de \(P(T)\)         | Gyr⁻¹ |

6. **Calcule les erreurs relatives aux jalons** et les enregistre dans :

   - `zz-data/chapter01/01_relative_error_timeline.csv`

   Colonnes :

   | Colonne | Description                                | Unité |
   |:-------:|:-------------------------------------------|:-----:|
   | `T`     | Jalons temporels (reprise de `T` jalons)   |  Gyr  |
   | `epsilon` | \(\epsilon = (P_{\rm calc}-P_{\rm ref})/P_{\rm ref}\) | — |

7. **Construit les invariants adimensionnels** et les écrit dans :

   - `zz-data/chapter01/01_dimensionless_invariants.csv`

   Colonnes :

   | Colonne | Description                  | Unité | Exemple de définition          |
   |:-------:|:-----------------------------|:-----:|:--------------------------------|
   | `T`     | Grille temporelle           |  Gyr  |                                 |
   | `I1`    | Invariant adimensionnel     |  —    | \(I_1 = P_{\rm calc}(T) / T\) |

En fin d’exécution, le script affiche un message de succès si toutes les sorties
ont été produites sans erreur.

### 5.2. Figures CH01

Une fois les données générées, les figures officielles sont produites par :

```bash
python zz-scripts/chapter01/plot_fig01_early_plateau.py
python zz-scripts/chapter01/plot_fig02_logistic_calibration.py
python zz-scripts/chapter01/plot_fig03_relative_error_timeline.py
python zz-scripts/chapter01/plot_fig04_P_vs_T_evolution.py
python zz-scripts/chapter01/plot_fig05_I1_vs_T.py
python zz-scripts/chapter01/plot_fig06_P_derivative_comparison.py
```

Produits attendus dans `zz-figures/chapter01/` :

- `fig_01_early_plateau.png`  
  → plateau quasi‑constant de \(P(T)\) sur la grille initiale.

- `fig_02_logistic_calibration.png`  
  → comparaison \(P_{\rm ref}\) vs \(P_{\rm calc}\) (régression + ligne d’identité).

- `fig_03_relative_error_timeline.png`  
  → \(\epsilon(T)\) en fonction de T, souvent en échelle symlog.

- `fig_04_P_vs_T_evolution.png`  
  → courbe \(P_{\rm init}\) vs \(P_{\rm calc}\) sur la grille.

- `fig_05_I1_vs_T.png`  
  → invariant \(I_1(T)\) en représentation adaptée (log–log possible).

- `fig_06_P_derivative_comparison.png`  
  → comparaison des dérivées dP/dT initiale et optimisée.

---

## 6. Produits finaux « officiels » pour le chapitre 01

Pour la relecture et la publication, les fichiers suivants sont considérés comme
**produits finaux** du chapitre 01.

### 6.1. Données

- `zz-data/chapter01/01_optimized_data.csv`
- `zz-data/chapter01/01_optimized_grid_data.dat`
- `zz-data/chapter01/01_P_derivative_initial.csv`
- `zz-data/chapter01/01_P_derivative_optimized.csv`
- `zz-data/chapter01/01_optimized_data_and_derivatives.csv`
- `zz-data/chapter01/01_relative_error_timeline.csv`
- `zz-data/chapter01/01_dimensionless_invariants.csv`

Les fichiers d’entrée suivants doivent rester stables et tracés dans les manifests :

- `zz-data/chapter01/01_timeline_milestones.csv`
- `zz-data/chapter01/01_initial_grid_data.dat`

### 6.2. Figures

- `zz-figures/chapter01/01_fig_01_early_plateau.png`
- `zz-figures/chapter01/01_fig_02_logistic_calibration.png`
- `zz-figures/chapter01/01_fig_03_relative_error_timeline.png`
- `zz-figures/chapter01/01_fig_04_p_vs_t_evolution.png`
- `zz-figures/chapter01/01_fig_05_i1_vs_t.png`
- `zz-figures/chapter01/01_fig_06_p_derivative_comparison.png`

---

## 7. Contrôle d’intégrité et manifests

Après exécution du pipeline minimal CH01, il est recommandé de lancer le diagnostic
des manifests :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre :

- les fichiers de données / figures CH01 ;
- `zz-manifests/manifest_master.json` ;
- `zz-manifests/manifest_publication.json`.

Objectifs pour le pipeline minimal :

- aucune erreur de type `SHA_MISMATCH` ou fichier manquant sur les produits
  listés en §6.1–6.2 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent exister
  pendant les phases d’édition active, mais doivent être réduits au minimum
  au moment de la publication.

---

## 8. Méthodes numériques et paramètres (rappel synthétique)

Les détails complets sont documentés dans les scripts CH01, mais les grandes lignes sont :

- **Grille temporelle** :
  - intervalle \([T_{\min}, T_{\max}] = [10^{-6}, 14]\) Gyr ;
  - grille log‑uniforme en \(\log_{10} T\) avec un pas typique \(\Delta \log_{10} T \approx 0{,}01\).

- **Interpolation** :
  - \(P_{\rm calc}(T)\) obtenu par calibration / optimisation, puis interpolation PCHIP
    en espace log–log pour garantir la monotonie et la stabilité.

- **Lissage des dérivées** :
  - dérivée \(dP/dT\) calculée numériquement puis lissée via filtrage de Savitzky–Golay
    (fenêtre et ordre cohérents avec les autres chapitres, typiquement
    `window_length` modéré, `polyorder=3`, `mode='interp'`).

- **Erreurs relatives** :
  - \(\epsilon(T_i) = (P_{\rm calc}(T_i) - P_{\rm ref}(T_i)) / P_{\rm ref}(T_i)\) aux jalons ;
  - utilisées pour contrôler la cohérence avec les tolérances inter‑chapitres
    (jalons « primaires » vs « ordre 2 » là où applicable).

- **Invariants** :
  - invariant de base \(I_1(T) = P_{\rm calc}(T) / T\) (adimensionnel) ;
  - les définitions peuvent être harmonisées avec les invariants utilisés en CH02 & CH05.

---

## 9. Notes LaTeX / versionnage & reproductibilité

- Les sources LaTeX du chapitre 01 se trouvent dans le répertoire :

  - `01-introduction-applications/01_introduction_conceptuel.tex`
  - `01-introduction-applications/01_applications_calibration_conceptuel.tex`

  Compilation (exemple) :

  ```bash
  pdflatex -interaction=nonstopmode 01-introduction-applications/01_introduction_conceptuel.tex
  pdflatex -interaction=nonstopmode 01-introduction-applications/01_applications_calibration_conceptuel.tex
  ```

- Pour la **reproductibilité**, toute modification affectant les résultats CH01
  (données ou figures) devrait idéalement :

  - être effectuée dans une branche dédiée ;
  - être accompagnée d’une exécution propre du pipeline minimal (cf. §3) ;
  - passer `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
  - mettre à jour `CHANGELOG.md` si les chiffres ou figures publiées changent.

Fin du document.
