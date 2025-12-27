# Chapter 08 – Pipeline minimal canonique (couplage sombre BAO + SNe)

Ce document décrit le **pipeline minimal canonique** permettant de relancer, à partir du dépôt
MCGT, les calculs et figures essentiels du **chapitre 08 – couplage sombre (BAO + Pantheon+)**.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- générer un profil 1D de χ² total `χ²(q0⋆)` à partir des jeux BAO + SNe ;
- produire les courbes théoriques associées `D_V(z)` et `μ(z)` au meilleur `q0⋆` ;
- régénérer les figures principales (profil χ² et comparaisons données / modèle) ;
- vérifier rapidement la cohérence numérique et les manifests liés au chapitre 08.

---

## 1. Objectif

Le pipeline minimal CH08 s’appuie sur un script shell canonique :

- `tools/ch08_minimal_pipeline.sh`

qui orchestre, depuis la racine du dépôt :

1. l’exécution de `generate_data_chapter08.py` sur une **grille 1D en `q0⋆`** ;
2. la mise à jour des fichiers de contrôle dans `assets/zz-data/08_sound_horizon/` ;
3. la génération d’un **sous‑ensemble de figures principales** (χ² vs `q0⋆`, BAO, SNe) ;
4. un passage par le diagnostic de manifests.

Ce pipeline est volontairement limité au cas **1D (q0⋆ seul)** ; les scans 2D optionnels
(`08_chi2_scan2D.csv`, etc.) restent réservés aux runs scientifiques complets.

---

## 2. Pré‑requis

Depuis la racine du dépôt `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `scipy`, `matplotlib`, etc. ;
- Fichiers de données d’entrée déjà présents (ou extraits au préalable) dans :

  - `assets/zz-data/08_sound_horizon/08_coupling_milestones.csv`
  - `assets/zz-data/08_sound_horizon/08_bao_data.csv`
  - `assets/zz-data/08_sound_horizon/08_pantheon_data.csv`

- Fichier de paramètres (créé / mis à jour par le pipeline) :

  - `assets/zz-data/08_sound_horizon/08_coupling_params.json`

Les chemins sont supposés compatibles avec la hiérarchie standard MCGT.

---

## 3. Résumé rapide – commande unique

Depuis la racine du dépôt :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire
bash tools/ch08_minimal_pipeline.sh
```

Ce script exécute la séquence **canonique minimale** suivante :

1. **Génération du profil χ²(q0⋆)**  
   Appel de `generate_data_chapter08.py` sur une grille 1D de `q0⋆`, avec
   export des fichiers :

   - `08_chi2_total_vs_q0.csv`
   - `08_chi2_derivative.csv` (dérivée lissée, optionnelle)
   - `08_dv_theory_z.csv`
   - `08_mu_theory_z.csv`
   - `08_coupling_params.json` (seuils, maxima, bornes).

2. **Figures principales (profil χ² + comparaisons BAO/SNe)**  
   Appels des scripts :

   - `10_fig01_chi2_total_vs_q0.py`
   - `10_fig02_dv_vs_z.py`
   - `10_fig03_mu_vs_z.py`

3. **(Optionnel) Figures de résidus et distributions normalisées**  
   Si activé dans le script :

   - `10_fig05_residuals.py`
   - `10_fig06_normalized_residuals_distribution.py`
   - `10_fig07_chi2_profile.py`

4. **Diagnostic des manifests**  
   Appel final à :

   - `bash tools/run_diag_manifests.sh`

En fin d’exécution réussie, on s’attend à un résumé du type :

- `[INFO] CH08 : données couplage sombre régénérées (profil q0⋆).`
- `[INFO] Figures principales CH08 mises à jour (fig_01 à fig_03).`
- `[DONE] Pipeline minimal CH08 terminé.`

---

## 4. Scripts, données et figures impliqués

### 4.1. Scripts Python (logique scientifique)

Répertoire CH08 :

- `scripts/08_sound_horizon/generate_data_chapter08.py`
- `scripts/08_sound_horizon/10_fig01_chi2_total_vs_q0.py`
- `scripts/08_sound_horizon/10_fig02_dv_vs_z.py`
- `scripts/08_sound_horizon/10_fig03_mu_vs_z.py`

Scripts **optionnels** (au‑delà du pipeline minimal strict) :

- `scripts/08_sound_horizon/10_fig04_chi2_heatmap.py`
- `scripts/08_sound_horizon/10_fig05_residuals.py`
- `scripts/08_sound_horizon/10_fig06_normalized_residuals_distribution.py`
- `scripts/08_sound_horizon/10_fig07_chi2_profile.py`
- `` (extraction BAO, Pantheon+, modèles de test).

### 4.2. Données CH08 (inputs + outputs)

Répertoire principal :

- `assets/zz-data/08_sound_horizon/`

Fichiers d’entrée attendus :

- `08_coupling_milestones.csv`  
  → jalons combinés BAO + SNe (z, valeur observée, σ, classe).

- `08_bao_data.csv`  
  → données BAO agrégées `D_V(z)` et incertitudes.

- `08_pantheon_data.csv`  
  → données Pantheon+ (`μ(z)`, `σ_μ`).

Fichiers produits par le **pipeline minimal 1D** :

- `08_chi2_total_vs_q0.csv`  
  → profil `χ²_total(q0⋆)` pour la grille canonique de `q0⋆` (BAO + SNe).

- `08_chi2_derivative.csv` (optionnel)  
  → dérivée lissée `dχ²/dq0⋆` pour repérer plus finement les minima.

- `08_dv_theory_z.csv`  
  → courbe théorique `D_V(z)` au `q0⋆` sélectionné (minimisant χ²).

- `08_mu_theory_z.csv`  
  → courbe théorique `μ(z)` au même `q0⋆`.

- `08_coupling_params.json`  
  → paramètres et seuils de contrôle (tels que `thresholds.primary`, `thresholds.order2`,
    `max_epsilon_primary`, `max_epsilon_order2`, bornes de scan, etc.).

Les fichiers **optionnels** de scan 2D (`08_chi2_scan2D.csv`, `08_mu_theory_q0star.csv`, …)
ne sont pas requis par le pipeline minimal, mais restent compatibles avec le guide original.

### 4.3. Figures CH08

Répertoire :

- `assets/zz-figures/08_sound_horizon/`

Figures principales ciblées par le pipeline minimal :

- `fig_01_chi2_total_vs_q0.png`  
  → profil `χ²_total(q0⋆)` avec minimum mis en évidence.

- `fig_02_dv_vs_z.png`  
  → comparaison `D_V(z)` observé vs modèle MCGT au meilleur `q0⋆`.

- `fig_03_mu_vs_z.png`  
  → comparaison `μ(z)` Pantheon+ observé vs modèle MCGT au meilleur `q0⋆`.

Figures additionnelles (optionnelles) :

- `fig_05_residuals.png`  
  → résidus BAO + SNe (observé – théorique) vs z.

- `fig_06_normalized_residuals.png`  
  → distribution des résidus normalisés (≈ N(0,1) attendue).

- `fig_07_chi2_profile.png`  
  → Δχ²(q0⋆) = χ² − χ²_min, avec lignes 1σ/2σ/3σ.

(`fig_04_chi2_heatmap.png` ne concerne que les scans 2D et reste hors du périmètre minimal.)

---

## 5. Pipeline détaillé – étape par étape

### 5.1. Génération des données – scan 1D en q0⋆

Depuis la racine du dépôt :

```bash
python scripts/08_sound_horizon/generate_data_chapter08.py \
    --q0star_min -0.10 --q0star_max 0.10 --n_points 201 \
    --export-derivative
```

Ce script :

1. lit les jalons de couplage sombre dans :
   - `assets/zz-data/08_sound_horizon/08_coupling_milestones.csv` ;
   - `assets/zz-data/08_sound_horizon/08_bao_data.csv` ;
   - `assets/zz-data/08_sound_horizon/08_pantheon_data.csv` ;

2. construit une grille **log‑lin** ou linéaire en `q0⋆` (ici 201 points sur
   l’intervalle \[-0.10, 0.10\]) ;

3. pour chaque `q0⋆` de la grille :
   - calcule les observables théoriques `D_V(z)` et `μ(z)` ;
   - construit la contribution χ² BAO + χ² Pantheon+ ;
   - somme ces contributions pour obtenir `χ²_total(q0⋆)` ;

4. sauvegarde le profil dans :

   - `assets/zz-data/08_sound_horizon/08_chi2_total_vs_q0.csv`

5. calcule une dérivée lissée `dχ²/dq0⋆` (filtre Savitzky–Golay, fenêtre 7,
   ordre 3, `mode="interp"`) et l’écrit dans :

   - `assets/zz-data/08_sound_horizon/08_chi2_derivative.csv`

6. identifie le minimum global de χ² et, au `q0⋆` correspondant, calcule :

   - `D_V(z)` théorique → `assets/zz-data/08_sound_horizon/08_dv_theory_z.csv` ;
   - `μ(z)` théorique → `assets/zz-data/08_sound_horizon/08_mu_theory_z.csv` ;

7. met à jour `assets/zz-data/08_sound_horizon/08_coupling_params.json` avec :

   - les seuils `thresholds.primary`, `thresholds.order2` ;
   - les maxima d’écarts relatifs (`max_epsilon_primary`, `max_epsilon_order2`) ;
   - les bornes de scan `q0star_min`, `q0star_max`, `n_points` utilisés.

En cas de succès, le script conclut typiquement par un message :

- `✓ Chapter 08 : profil χ²(q0⋆) généré avec succès.`

### 5.2. Figures principales – BAO + SNe

Une fois les données générées, on relance les figures principales :

```bash
python scripts/08_sound_horizon/10_fig01_chi2_total_vs_q0.py
python scripts/08_sound_horizon/10_fig02_dv_vs_z.py
python scripts/08_sound_horizon/10_fig03_mu_vs_z.py
```

Ces scripts mettent à jour, respectivement :

- `assets/zz-figures/08_sound_horizon/08_fig_01_chi2_total_vs_q0.png`
- `assets/zz-figures/08_sound_horizon/08_fig_02_dv_vs_z.png`
- `assets/zz-figures/08_sound_horizon/08_fig_03_mu_vs_z.png`

Pour une analyse plus poussée (hors périmètre minimal), il est possible de
compléter par :

```bash
python scripts/08_sound_horizon/10_fig05_residuals.py
python scripts/08_sound_horizon/10_fig06_normalized_residuals_distribution.py
python scripts/08_sound_horizon/10_fig07_chi2_profile.py
```

### 5.3. Vérifications rapides (sanity‑checks)

Après exécution de `generate_data_chapter08.py`, quelques contrôles simples :

- `08_chi2_total_vs_q0.csv` :
  - χ² ≥ 0 sur toute la grille ;
  - présence d’un minimum bien marqué.

- `08_coupling_params.json` :
  - `max_epsilon_primary ≤ thresholds.primary` (≈ 1 %) ;
  - `max_epsilon_order2 ≤ thresholds.order2` (≈ 10 %).

- `08_dv_theory_z.csv` & `08_mu_theory_z.csv` :
  - aucune valeur NaN/Inf ;
  - recouvrement complet des z BAO/SNe d’entrée.

---

## 6. Produits finaux « officiels » pour le chapitre 08

Dans le cadre du pipeline minimal canonique, les **produits principaux** de CH08 sont :

### 6.1. Données

- `assets/zz-data/08_sound_horizon/08_chi2_total_vs_q0.csv`  
  → profil 1D `χ²_total(q0⋆)` pour le couplage sombre.

- `assets/zz-data/08_sound_horizon/08_chi2_derivative.csv`  
  → dérivée lissée `dχ²/dq0⋆` (diagnostic du minimum).

- `assets/zz-data/08_sound_horizon/08_dv_theory_z.csv`  
  → `D_V(z)` théorique au `q0⋆` sélectionné.

- `assets/zz-data/08_sound_horizon/08_mu_theory_z.csv`  
  → `μ(z)` théorique au même `q0⋆`.

- `assets/zz-data/08_sound_horizon/08_coupling_params.json`  
  → paramètres, seuils et maxima d’écarts relatifs pour CH08.

Les fichiers **d’entrée** (`08_coupling_milestones.csv`, `08_bao_data.csv`, `08_pantheon_data.csv`)
sont également considérés comme structurants pour la publication.

### 6.2. Figures

- `assets/zz-figures/08_sound_horizon/08_fig_01_chi2_total_vs_q0.png`
- `assets/zz-figures/08_sound_horizon/08_fig_02_dv_vs_z.png`
- `assets/zz-figures/08_sound_horizon/08_fig_03_mu_vs_z.png`

En complément (analyse étendue) :

- `assets/zz-figures/08_sound_horizon/08_fig_05_residuals.png`
- `assets/zz-figures/08_sound_horizon/08_fig_06_normalized_residuals_distribution.png`
- `assets/zz-figures/08_sound_horizon/08_fig_07_chi2_profile.png`

---

## 7. Contrôle d’intégrité et manifests

Après exécution de `tools/ch08_minimal_pipeline.sh`, il est recommandé de lancer
le diagnostic des manifests :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre :

- les fichiers de données / figures CH08 ;
- `assets/zz-manifests/manifest_master.json` ;
- `assets/zz-manifests/manifest_publication.json`.

Objectifs pour le pipeline minimal :

- aucune erreur de type `SHA_MISMATCH` ou fichier manquant sur les produits
  listés en §6.1–6.2 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent exister
  pendant les phases d’édition active, mais doivent être réduits au minimum
  au moment de la publication.

---

## 8. Notes LaTeX / versionnage & reproductibilité

- Les sources LaTeX du chapitre 08 se trouvent dans le répertoire :

  - `08-couplage-sombre/08_couplage_sombre_conceptuel.tex`
  - `08-couplage-sombre/08_couplage_sombre_details.tex`

  Compilation (exemple) :

  ```bash
  cd 08-couplage-sombre
  pdflatex -interaction=nonstopmode 08_couplage_sombre_conceptuel.tex
  pdflatex -interaction=nonstopmode 08_couplage_sombre_details.tex
  ```

- Pour la **reproductibilité**, toute modification affectant les résultats CH08
  (données ou figures) devrait idéalement :

  - être effectuée dans une branche dédiée ;
  - être accompagnée d’une exécution propre du pipeline minimal
    (`tools/ch08_minimal_pipeline.sh`) ;
  - passer `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
  - mettre à jour `CHANGELOG.md` si les chiffres ou figures publiées changent.

Fin du document.
