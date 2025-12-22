# Chapter 07 – Pipeline minimal canonique (perturbations scalaires)

Ce document décrit le **pipeline minimal canonique** permettant de relancer, à partir du dépôt
MCGT, les calculs et figures essentiels du **chapitre 07 – perturbations scalaires**.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- exécuter les dry‑runs de sécurité sur le pipeline CH07 ;
- lancer le solveur de perturbations scalaires sur une grille minimale ;
- mettre à jour les fichiers de contrôle `07_phase_run.csv` et `07_meta_perturbations.json` ;
- régénérer les figures principales (Fig. 01 à 07) lorsque nécessaire.

---

## 1. Objectif

Le pipeline minimal CH07 s’appuie sur un script shell canonique :

- `tools/ch07_minimal_pipeline.sh`

qui orchestre les **dry‑runs**, un **run complet minimal** et la génération des
figures, de façon cohérente avec le reste de MCGT.

Ce pipeline est conçu pour :

- tester rapidement la santé du solveur de perturbations scalaires MCGT ;
- produire un petit nombre de produits « référence » pour CH07 ;
- rester compatible avec les manifests (`manifest_master` et `manifest_publication`).

---

## 2. Pré‑requis

Depuis la racine du dépôt `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `scipy`, `matplotlib`, etc. ;
- Fichiers de configuration accessibles :

  - `config/scalar_perturbations.ini`

Les chemins sont supposés être ceux de la hiérarchie standard du dépôt MCGT.

---

## 3. Résumé rapide – commande unique

Depuis la racine du dépôt :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire
bash tools/ch07_minimal_pipeline.sh
```

Ce script exécute la séquence **canonique minimale** suivante :

1. **Smoke – `generate_data_chapter07.py --dry-run`**  
   Vérifie que la configuration CH07 est cohérente sans lancer de calcul lourd.

2. **Smoke – `launch_scalar_perturbations_solver.py --dry-run`**  
   Vérifie la construction des grilles `(k, a)` et le dispatch vers le solveur.

3. **Run complet minimal – `generate_data_chapter07.py`**  
   – actuel : ce run peut **échouer avec une exception attendue**  
   `ValueError: c_s² hors-borne ou non-fini (attendu dans [0,1]).`  
   Cet échec reflète la sévérité du profil canonique utilisé et n’est pas,
   à ce stade, un blocage pour la pipeline minimal (voir §5.2).

4. **Run complet minimal – `launch_scalar_perturbations_solver.py`**  
   Produit les fichiers de référence CH07 (voir §4.2) ;

5. **Figures principales (Fig. 01 à 07)**, invoquées séquentiellement.

En fin d’exécution, le script affiche un résumé du type :

- `[WARN] generate_data_chapter07.py a terminé avec un code 1 (c_s² hors-borne… – échec attendu)`  
- `[INFO] Raw unifié écrit → assets/zz-data/chapter07/07_phase_run.csv`  
- `[INFO] Méta écrit → assets/zz-data/chapter07/07_meta_perturbations.json`  
- `[DONE] Pipeline minimal CH07 terminé.`

---

## 4. Scripts, données et figures impliqués

### 4.1. Scripts Python (logique scientifique)

Répertoire CH07 :

- `scripts/07_bao_geometry/`

Scripts utilisés par le pipeline minimal :

- `generate_data_chapter07.py`
- `launch_scalar_perturbations_solver.py`
- `10_fig01_cs2_heatmap.py`
- `10_fig02_delta_phi_heatmap.py`
- `tracer_fig03_invariant_I1.py`
- `tracer_fig04_dcs2_vs_k.py`
- `tracer_fig05_ddelta_phi_vs_k.py`
- `10_fig06_comparison.py`
- `tracer_fig07_invariant_I2.py`

Utilitaires :

- `scripts/07_bao_geometry/utils/test_kgrid.py`
- `scripts/07_bao_geometry/utils/toy_model.py`

### 4.2. Données CH07 (inputs + outputs)

Répertoire principal :

- `assets/zz-data/chapter07/`

Fichiers importants pour le pipeline minimal :

- `07_phase_run.csv`  
  → échantillon unifié (k, a, variables brutes) de contrôle du solveur ;

- `07_meta_perturbations.json`  
  → métadonnées du run minimal : version, nombre de points, liste de fichiers, etc.

Dans une exécution « pleine » de CH07 (au‑delà du minimal), on attend également :

- `07_cs2_matrix.csv`               – matrice c_s²(k, a) sur la grille ;
- `07_delta_phi_matrix.csv`         – matrice δφ/φ(k, a) ;
- `07_dcs2_dk.csv`                  – dérivée lissée ∂(c_s²)/∂k ;
- `07_ddelta_phi_dk.csv`           – dérivée lissée ∂(δφ/φ)/∂k ;
- `07_perturbations_main_data.csv` (ou `07_scalar_perturbations_results.csv`) ;
- `07_scalar_invariants.csv`       – invariants I₁, I₂ ;
- `07_perturbations_domain.csv`    – domaine d’évaluation ;
- `07_perturbations_boundary.csv`  – frontières / enveloppes de validité ;
- `07_perturbations_params.json`   – paramètres effectifs du run (grilles, seuils, etc.).

### 4.3. Figures CH07

Répertoire :

- `assets/zz-figures/chapter07/`

Figures principales :

- `fig_01_cs2_heatmap_k_a.png`          – carte c_s²(k, a) ;
- `fig_02_delta_phi_heatmap_k_a.png`    – carte δφ/φ(k, a) ;
- `fig_03_invariant_I1.png`             – invariant I₁ vs k ;
- `fig_04_dcs2_dk_vs_k.png`             – dérivée ∂(c_s²)/∂k vs k ;
- `fig_05_ddelta_phi_dk_vs_k.png`       – dérivée ∂(δφ/φ)/∂k vs k ;
- `fig_06_comparison.png`               – comparaison cs²/δφ/φ ou modèles ;
- `fig_07_invariant_I2.png`             – invariant I₂ vs k.

Une figure supplémentaire de test de sampling peut exister :

- `fig_00_loglog_sampling_test.png`     – diagnostic de la grille en k.

---

## 5. Pipeline détaillé – étape par étape

### 5.1. Smoke minimal (dry‑runs)

Depuis la racine du dépôt :

```bash
python scripts/07_bao_geometry/generate_data_chapter07.py        --ini config/scalar_perturbations.ini        --dry-run
```

- Vérifie la lecture de l’INI et la construction logique des grilles ;
- Journalise les dimensions prévues (k‑points, a‑points) ;
- Ne produit aucun fichier : il s’agit d’un test de configuration uniquement.

```bash
python scripts/07_bao_geometry/launch_scalar_perturbations_solver.py        --ini config/scalar_perturbations.ini        --dry-run
```

- Vérifie la construction des grilles `(k, a)` et le passage au solveur ;
- Confirme la capacité du code à itérer sur un petit nombre de points sans erreur ;
- Ne produit aucun fichier (dry‑run).

Ces deux dry‑runs constituent le **smoke minimal** de sécurité pour CH07.

### 5.2. Run complet minimal – generate_data_chapter07.py

Toujours depuis la racine :

```bash
python scripts/07_bao_geometry/generate_data_chapter07.py        --ini config/scalar_perturbations.ini
```

Dans l’état canonique actuel, ce script peut échouer avec :

```text
ValueError: c_s² hors-borne ou non-fini (attendu dans [0,1]).
```

Ce comportement signifie que, pour le profil choisi, certaines valeurs de c_s²(k, a)
sortent de l’intervalle [0, 1] ou deviennent non finies. Cet échec est **attendu**
et sert de garde‑fou physique :

- il signale qu’on a atteint une région de paramètres physiquement douteuse ;
- il n’empêche pas le pipeline minimal CH07 de remplir son rôle actuel
  (qui repose essentiellement sur le solveur CH07 et les fichiers `07_phase_run.csv`
  et `07_meta_perturbations.json`).

Lorsque ce comportement sera stabilisé ou assoupli, le même pipeline continuera
de fonctionner sans modification structurelle.

### 5.3. Run complet minimal – launch_scalar_perturbations_solver.py

```bash
python scripts/07_bao_geometry/launch_scalar_perturbations_solver.py        --ini config/scalar_perturbations.ini
```

Ce script :

1. construit les grilles `(k, a)` sur un sous‑ensemble minimal (par ex. 32 points en k,
   20 points en a) ;
2. appelle les fonctions de solveur MCGT `compute_cs2` et `compute_delta_phi` ;
3. agrège les résultats bruts dans un tableau de contrôle et les écrit dans :

   - `assets/zz-data/chapter07/07_phase_run.csv`

4. assemble un jeu de **métadonnées de run** et les écrit dans :

   - `assets/zz-data/chapter07/07_meta_perturbations.json`.

En cas de succès, on observe des messages du type :

- `[INFO] Raw unifié écrit → assets/zz-data/chapter07/07_phase_run.csv (640 lignes)`  
- `[INFO] Méta écrit → assets/zz-data/chapter07/07_meta_perturbations.json`  
- `[INFO] Terminé avec succès.`

### 5.4. Figures principales (Fig. 01 à 07)

Les figures peuvent être régénérées une fois les données complètes disponibles
(typiquement au‑delà du pipeline minimal strict) :

```bash
python scripts/07_bao_geometry/10_fig01_cs2_heatmap.py
python scripts/07_bao_geometry/10_fig02_delta_phi_heatmap.py
python scripts/07_bao_geometry/10_fig03_invariant_i1.py
python scripts/07_bao_geometry/10_fig04_dcs2_vs_k.py
python scripts/07_bao_geometry/10_fig05_ddelta_phi_vs_k.py
python scripts/07_bao_geometry/10_fig06_comparison.py
python scripts/07_bao_geometry/10_fig07_invariant_i2.py
```

Chaque script met à jour la figure correspondante dans `assets/zz-figures/chapter07/`.

---

## 6. Produits finaux « officiels » pour le chapitre 07

Dans le cadre du pipeline minimal canonique, les **produits principaux** de CH07 sont :

### 6.1. Données

- `assets/zz-data/chapter07/07_phase_run.csv`  
  → échantillon de contrôle contenant les valeurs brutes c_s²(k, a) et δφ/φ(k, a)
    sur une petite grille canonique.

- `assets/zz-data/chapter07/07_meta_perturbations.json`  
  → métadonnées du run minimal (version, n_points, liste des fichiers attendus, etc.).

En exécution complète, on considère également comme produits structurants :

- `assets/zz-data/chapter07/07_cs2_matrix.csv`
- `assets/zz-data/chapter07/07_delta_phi_matrix.csv`
- `assets/zz-data/chapter07/07_dcs2_vs_k.csv`
- `assets/zz-data/chapter07/07_ddelta_phi_vs_k.csv`
- `assets/zz-data/chapter07/07_perturbations_main_data.csv` (ou `07_scalar_perturbations_results.csv`)
- `assets/zz-data/chapter07/07_scalar_invariants.csv`
- `assets/zz-data/chapter07/07_perturbations_domain.csv`
- `assets/zz-data/chapter07/07_perturbations_boundary.csv`
- `assets/zz-data/chapter07/07_perturbations_params.json`

### 6.2. Figures

- `assets/zz-figures/chapter07/07_fig_01_cs2_heatmap.png`
- `assets/zz-figures/chapter07/07_fig_02_delta_phi_heatmap.png`
- `assets/zz-figures/chapter07/07_fig_03_invariant_i1.png`
- `assets/zz-figures/chapter07/07_fig_04_dcs2_vs_k.png`
- `assets/zz-figures/chapter07/07_fig_05_ddelta_phi_vs_k.png`
- `assets/zz-figures/chapter07/07_fig_06_comparison.png`
- `assets/zz-figures/chapter07/07_fig_07_invariant_i2.png`
- (optionnel) ``

---

## 7. Contrôle d’intégrité et manifests

Après exécution de `tools/ch07_minimal_pipeline.sh`, il est recommandé de lancer
le diagnostic des manifests :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre :

- les fichiers de données / figures CH07 ;
- `assets/zz-manifests/manifest_master.json` ;
- `assets/zz-manifests/manifest_publication.json`.

Objectifs pour le pipeline minimal :

- aucune erreur de type `SHA_MISMATCH` ou fichier manquant sur les produits
  listés en §6.1–6.2 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent exister
  pendant les phases d’édition active, mais doivent être réduits au minimum
  au moment de la publication.

---

## 8. Méthodes numériques et paramètres (rappel synthétique)

Les détails complets sont documentés dans les scripts CH07, mais les grandes lignes sont :

- **Grille en k** :
  - log‑uniforme entre `k_min` et `k_max` (p. ex. `[1e-4, 10]`) ;
  - nombre de points contrôlé via un pas constant en `log10(k)`.

- **Grille en a** :
  - facteur d’échelle linéaire entre `a_min` et `a_max` (p. ex. `[0.05, 1.0]`) ;
  - nombre de points typique : `n_a ≈ 20`.

- **Interpolation** :
  - c_s²(k, a) : interpolation PCHIP en `(log10 k, log10 c_s²)` (extrapolation contrôlée) ;
  - δφ/φ(k, a) : interpolation PCHIP linéaire en `(k, δφ/φ)`.

- **Dérivées lissées** :
  - calcul des dérivées par rapport à k, puis lissage via Savitzky–Golay
    (fenêtre typique 7, ordre 3, `mode='interp'`).

- **Invariants** :
  - I₁ ≡ c_s²(k) ou variante normalisée `c_s² / k^α` (α configurable) ;
  - I₂ = fonction de δφ/φ et/ou de k (ex. `k·|δφ/φ|`), définie dans le code.

- **Segmentation en k** (optionnelle) :
  - paramètre `x_split` permettant de séparer la grille en sous‑domaines `low`/`high`
    pour améliorer la stabilité des dérivées et invariants.

- **Seuils de contrôle** :
  - différents seuils (par ex. `thresholds.primary`, `thresholds.order2`) sont
    enregistrés dans `07_perturbations_params.json` pour suivre la cohérence
    des profils et des dérivées.

---

## 9. Notes LaTeX / versionnage & reproductibilité

- Les sources LaTeX du chapitre 07 se trouvent dans le répertoire :

  - `07-perturbations-scalaires/07_perturbations_scalaires_conceptuel.tex`
  - `07-perturbations-scalaires/07_perturbations_scalaires_details.tex`

  Compilation (exemple) :

  ```bash
  pdflatex -interaction=nonstopmode 07-perturbations-scalaires/07_perturbations_scalaires_conceptuel.tex
  pdflatex -interaction=nonstopmode 07-perturbations-scalaires/07_perturbations_scalaires_details.tex
  ```

- Pour la **reproductibilité**, toute modification affectant les résultats CH07
  (données ou figures) devrait idéalement :

  - être effectuée dans une branche dédiée ;
  - être accompagnée d’une exécution propre du pipeline minimal (`tools/ch07_minimal_pipeline.sh`) ;
  - passer `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
  - mettre à jour `CHANGELOG.md` si les chiffres ou figures publiées changent.

Fin du document.
