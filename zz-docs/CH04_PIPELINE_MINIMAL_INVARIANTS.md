# Chapitre 04 – Pipeline minimal canonique (invariants adimensionnels)

Ce document décrit le **pipeline minimal canonique** permettant de relancer, à partir du dépôt
MCGT, les calculs et figures essentiels du **chapitre 04 – invariants adimensionnels**.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- recalculer les invariants adimensionnels I₁, I₂, I₃ sur une grille temporelle harmonisée ;
- vérifier la cohérence numérique de ces invariants avec les chapitres 01–03 ;
- régénérer les figures principales associées aux invariants du chapitre 04.

---

## 1. Objectif

Le pipeline minimal CH04 s’appuie sur un script shell canonique :

- `tools/ch04_minimal_pipeline.sh`  *(à créer / maintenir dans la hiérarchie `tools/`)*

qui orchestre le calcul des invariants et la génération des figures à partir des fichiers
d’entrée déjà présents dans le dépôt.

Ce pipeline est conçu pour :

- tester rapidement la santé du chapitre 04 (scripts + données) ;
- produire un petit ensemble de produits « référence » stables pour les invariants ;
- rester compatible avec les manifests (`manifest_master` et `manifest_publication`).

---

## 2. Pré‑requis

Depuis la racine du dépôt `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `scipy`, `matplotlib`, etc. ;
- Fichiers d’entrée disponibles :

  - `zz-data/chapter04/04_P_vs_T.dat`
    – grille temporelle harmonisée `T_Gyr` + profil P(T) issu des chapitres 01–02 ;
  - (optionnel mais recommandé) fichiers f(R) du chapitre 03 si `generate_data_chapter04.py`
    importe `f_R` / `f_RR` pour construire I₃ ; typiquement :
    `zz-data/chapter03/03_fR_stability_data.csv` ou équivalent.

Le pipeline minimal **ne régénère pas** `04_P_vs_T.dat` : ce fichier est considéré comme un
input stable obtenu en amont (CH01–02).

---

## 3. Résumé rapide – commande unique

Depuis la racine du dépôt :

```bash
cd ~/MCGT  # adapter si nécessaire
bash tools/ch04_minimal_pipeline.sh
```

Ce script exécute la séquence **canonique minimale** suivante :

1. **Génération des invariants**  
   `python zz-scripts/chapter04/generate_data_chapter04.py`

2. **Figures principales (Fig. 01 à 04)**  
   `python zz-scripts/chapter04/plot_fig01_invariants_schematic.py`  
   `python zz-scripts/chapter04/plot_fig02_invariants_histogram.py`  
   `python zz-scripts/chapter04/plot_fig03_invariants_vs_T.py`  
   `python zz-scripts/chapter04/plot_fig04_relative_deviations.py`

3. **Résumé final** (optionnel dans le script shell) : inventaire des fichiers
   de `zz-data/chapter04/` et `zz-figures/chapter04/`.

En fin d’exécution, on s’attend à voir un message du type :

- `[INFO] 04_dimensionless_invariants.csv écrit avec succès.`  
- `[DONE] Pipeline minimal CH04 terminé.`

---

## 4. Scripts, données et figures impliqués

### 4.1. Scripts Python (logique scientifique)

Répertoire CH04 :

- `zz-scripts/chapter04/`

Scripts utilisés par le pipeline minimal :

- `generate_data_chapter04.py`
- `plot_fig01_invariants_schematic.py`
- `plot_fig02_invariants_histogram.py`
- `plot_fig03_invariants_vs_T.py`
- `plot_fig04_relative_deviations.py`

### 4.2. Données CH04 (inputs + outputs)

Répertoire principal :

- `zz-data/chapter04/`

Fichiers importants pour le pipeline minimal :

- `04_P_vs_T.dat`  
  → grille temporelle harmonisée et profil P(T) partagé avec les chapitres 01–02.  
  Colonnes attendues :

  | Colonne | Description                          | Unité |
  |:--------|:-------------------------------------|:------|
  | T_Gyr   | Âge propre (log‑uniforme)            | Gyr   |
  | P       | Quantité P(T) (profil harmonisé)     | —     |

- `04_dimensionless_invariants.csv`  
  → sortie principale du chapitre 04, contenant les invariants adimensionnels :

  | Colonne | Définition (exemple canonique)                   | Dimension    |
  |:--------|:-------------------------------------------------|:-------------|
  | T_Gyr   | Grille temporelle                               | Gyr          |
  | I1      | I₁ = P / T_Gyr                                  | (unité P)/Gyr|
  | I2      | I₂ = κ · T_Gyr² (κ défini dans le code)         | adimensionnel|
  | I3      | I₃ = f_R − 1 (issu du chapitre 03, si activé)   | adimensionnel|

Les définitions exactes de I₁, I₂, I₃ sont celles implémentées dans `generate_data_chapter04.py`
et documentées dans le manuscrit du chapitre 04.

### 4.3. Figures CH04

Répertoire :

- `zz-figures/chapter04/`

Figures principales :

- `fig_01_invariants_schematic.png`      – schéma conceptuel (I₁, I₂, I₃) ;
- `fig_02_invariants_histogram.png`      – histogrammes (par exemple log|I₂|, log|I₃|) ;
- `fig_03_invariants_vs_T.png`           – I₁, I₂, I₃ en fonction de T_Gyr ;
- `fig_04_relative_deviations.png`       – écarts relatifs / contrôles de cohérence.

---

## 5. Pipeline détaillé – étape par étape

### 5.1. Vérification de la donnée d’entrée 04_P_vs_T.dat

Depuis la racine du dépôt :

```bash
ls zz-data/chapter04/04_P_vs_T.dat
```

Optionnellement, un petit contrôle rapide en Python :

```bash
python - << 'PY'
import numpy as np
T, P = np.loadtxt("zz-data/chapter04/04_P_vs_T.dat", unpack=True)
print("n_points =", T.size, "T_min =", T.min(), "T_max =", T.max())
PY
```

On vérifie en particulier que :

- `T_Gyr` est strictement croissant et couvre `[1e-6, 14]` Gyr (ou l’intervalle harmonisé
  retenu pour le projet) ;
- P(T) ne contient pas de NaN/Inf.

### 5.2. Run complet minimal – generate_data_chapter04.py

Commande canonique :

```bash
python zz-scripts/chapter04/generate_data_chapter04.py
```

Ce script effectue typiquement les opérations suivantes (schéma) :

1. Charge `zz-data/chapter04/04_P_vs_T.dat` ;
2. Applique l’interpolation/lissage nécessaire sur P(T)  
   (souvent PCHIP en `log10(T_Gyr)` / `log10(P)` pour homogénéité multi‑chapitres) ;
3. Si activé, importe un profil `f_R` provenant du chapitre 03 (par ex. via
   `zz-data/chapter03/03_fR_stability_data.csv`) et l’interpole sur la même grille `T_Gyr` ;
4. Construit les invariants I₁, I₂, I₃ selon les définitions du modèle ;
5. Écrit le tableau final dans :

   - `zz-data/chapter04/04_dimensionless_invariants.csv`

6. Journalise un résumé (min/max, présence éventuelle de valeurs aberrantes) et retourne
   avec un code de sortie `0` en cas de succès.

En fin de run, on attend un message du type :

- `[INFO] 04_dimensionless_invariants.csv écrit (N points).`
- `[INFO] Terminé avec succès.`

### 5.3. Figures principales (Fig. 01 à 04)

Une fois `04_dimensionless_invariants.csv` disponible, les figures se régénèrent via :

```bash
python zz-scripts/chapter04/plot_fig01_invariants_schematic.py
python zz-scripts/chapter04/plot_fig02_invariants_histogram.py
python zz-scripts/chapter04/plot_fig03_invariants_vs_T.py
python zz-scripts/chapter04/plot_fig04_relative_deviations.py
```

Chaque script met à jour la figure correspondante dans `zz-figures/chapter04/`.

---

## 6. Produits finaux « officiels » pour le chapitre 04

Dans le cadre du pipeline minimal canonique, les **produits principaux** de CH04 sont :

### 6.1. Données

- `zz-data/chapter04/04_P_vs_T.dat`  
  → profil P(T) harmonisé sur la grille temporelle standard MCGT.

- `zz-data/chapter04/04_dimensionless_invariants.csv`  
  → invariants adimensionnels I₁, I₂, I₃ sur cette même grille.

### 6.2. Figures

- `zz-figures/chapter04/04_fig_01_invariants_schematic.png`
- `zz-figures/chapter04/04_fig_02_invariants_histogram.png`
- `zz-figures/chapter04/04_fig_03_invariants_vs_t.png`
- `zz-figures/chapter04/04_fig_04_relative_deviations.png`

Ces fichiers devraient apparaître (et être à jour) dans les manifests du projet.

---

## 7. Contrôle d’intégrité et manifests

Après exécution de `tools/ch04_minimal_pipeline.sh`, il est recommandé de lancer
le diagnostic des manifests :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre :

- les fichiers de données / figures CH04 ;
- `zz-manifests/manifest_master.json` ;
- `zz-manifests/manifest_publication.json`.

Objectifs pour le pipeline minimal :

- aucune erreur de type `SHA_MISMATCH` ou fichier manquant sur les produits listés
  en §6.1–6.2 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent exister
  pendant les phases d’édition active, mais doivent être réduits au minimum
  au moment de la publication.

---

## 8. Paramètres numériques et conventions (rappel synthétique)

Les détails complets sont documentés dans les scripts et le manuscrit, mais les grandes lignes
sont :

- **Grille en temps** :
  - log‑uniforme sur `[1e-6, 14]` Gyr (ou plage mise à jour globalement) ;
  - pas typique `Δlog10 T ≈ 0.01`.

- **Interpolation / lissage** :
  - P(T) : PCHIP sur `log10(T_Gyr)` / `log10(P)` pour garantir la monotonie et la stabilité ;
  - éventuel lissage des dérivées via Savitzky–Golay (fenêtre, ordre alignés sur les chapitres 01–02).

- **Invariants** (exemple canonique) :
  - I₁ = P / T_Gyr ;
  - I₂ = κ · T_Gyr², avec κ constant de modèle (par ex. `1e-35`, configurable) ;
  - I₃ = f_R − 1 (doit rester proche de 0 sur le domaine de validité, cf. Chapitre 03).

- **Seuils de contrôle** (indicatifs) :
  - I₂ : variations relatives ≲ 10 % sur le domaine utile ;
  - I₃ : |I₃| ≲ 1 % sur la majorité du domaine (tout dépassement systématique
    doit être documenté).

---

## 9. Notes LaTeX / versionnage & reproductibilité

- Les sources LaTeX du chapitre 04 se trouvent dans :

  - `04-invariants-adimensionnels/04_invariants_adimensionnels_conceptuel.tex`
  - `04-invariants-adimensionnels/04_invariants_adimensionnels_details.tex`

  Compilation (exemple) :

  ```bash
  pdflatex -interaction=nonstopmode 04-invariants-adimensionnels/04_invariants_adimensionnels_conceptuel.tex
  pdflatex -interaction=nonstopmode 04-invariants-adimensionnels/04_invariants_adimensionnels_details.tex
  ```

- Pour la **reproductibilité**, toute modification affectant les résultats CH04
  (données ou figures) devrait idéalement :

  - être effectuée dans une branche dédiée ;
  - être accompagnée d’une exécution propre du pipeline minimal
    (`bash tools/ch04_minimal_pipeline.sh`) ;
  - passer `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
  - mettre à jour `CHANGELOG.md` si les chiffres ou figures publiées changent.

Fin du document.
