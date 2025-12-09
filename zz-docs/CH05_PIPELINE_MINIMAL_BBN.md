# Chapitre 05 – Pipeline minimal BBN (nucléosynthèse primordiale)

Ce document décrit le **pipeline minimal canonique** permettant de régénérer les
données et figures officielles du Chapitre 05 (nucléosynthèse primordiale, BBN)
à partir du dépôt MCGT.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- générer les jeux de données BBN utilisés dans le manuscrit ;
- produire les figures officielles du chapitre 05 ;
- vérifier rapidement que la chaîne BBN est scientifiquement cohérente
  et techniquement exécutable.

Ce guide est pensé comme le pendant BBN de
`CH07_PIPELINE_MINIMAL_CANONIQUE.md` et
`CH09_PIPELINE_MINIMAL_CALIBRE.md` : mêmes sections, même style,
adapté au contexte physique de la nucléosynthèse primordiale.

---

## 1. Objet et périmètre

Le pipeline minimal CH05 couvre uniquement :

- la construction d’une **grille temporelle** `T_Gyr` (en milliards d’années) ;
- la génération de **prédictions BBN simplifiées** pour D/H et Yp sur cette grille ;
- le calcul de `χ²(T)` et de sa **dérivée lissée** ;
- la production des **figures 01 à 04** du chapitre ;
- l’écriture de **paramètres de contrôle** (tolérances, écarts maximaux) dans
  `05_bbn_params.json`.

Il ne traite pas :

- de la reconstruction détaillée des réseaux de réaction nucléaires complets ;
- de l’extraction brute des données d’observation (catalogues externes) ;
- de variantes avancées (explorations paramétriques, autres jeux de données).

Pour ces cas, se référer aux documents techniques CH05 plus complets et/ou
aux notebooks dédiés.

---

## 2. Pré‑requis

Depuis la **racine du dépôt** MCGT (par ex. `/home/jplal/MCGT`) :

- Environnement Python MCGT activé (par ex. : `mcgt-dev`) ;
- Dépendances installées (via l’environnement standard MCGT) :
  - `numpy`, `pandas`, `scipy`, `matplotlib`, etc. ;
- Fichiers d’entrée BBN déjà présents dans le dépôt :

  - `zz-data/chapter05/05_bbn_milestones.csv`
  - `zz-data/chapter05/05_bbn_invariants.csv`

Ces fichiers contiennent notamment :

- les **jalons observationnels** : D/H et Yp (valeurs observées et incertitudes) ;
- les **invariants / paramètres** nécessaires à la construction du modèle.

En pratique, vérifier :

```bash
cd /home/jplal/MCGT  # adapter au besoin
ls zz-data/chapter05/05_bbn_milestones.csv
ls zz-data/chapter05/05_bbn_invariants.csv
```

---

## 3. Pipeline minimal – commande unique

Depuis la racine du dépôt, la commande canonique est :

```bash
cd /home/jplal/MCGT  # adapter au besoin
bash step102_ch05_pipeline_minimal.sh
```

Ce script shell encapsule la séquence minimale suivante :

1. Exécution de `generate_data_chapter05.py` pour produire les tables BBN ;
2. Exécution des scripts de figures BBN (figures 01 à 04) ;
3. Affichage d’un inventaire final des fichiers de données et figures CH05.

Si tout se passe bien, tu dois voir dans les logs des lignes du type :

- `✓ Chapitre 05 : données générées avec succès.`
- `✓ Chapitre 05 : figures (01–04) générées avec succès.`
- un récapitulatif des fichiers dans `zz-data/chapter05/`
  et `zz-figures/chapter05/`.

---

## 4. Détails du pipeline

### 4.1 Répertoires et fichiers impliqués

**Scripts scientifiques (code Python)** :

- répertoire : `zz-scripts/chapter05/`
- scripts utilisés par le pipeline minimal :

  - `generate_data_chapter05.py`
  - `plot_fig01_bbn_reaction_network.py`
  - `plot_fig02_dh_model_vs_obs.py`
  - `plot_fig03_yp_model_vs_obs.py`
  - `plot_fig04_chi2_vs_T.py`

**Données CH05** :

- répertoire : `zz-data/chapter05/`

  - **Entrées / jalons** :
    - `05_bbn_milestones.csv`
    - `05_bbn_invariants.csv`
  - **Outputs générés par le pipeline** :
    - `05_bbn_grid.csv`
    - `05_bbn_data.csv`
    - `05_chi2_bbn_vs_T.csv`
    - `05_dchi2_vs_T.csv`
    - `05_bbn_params.json`

**Figures CH05** :

- répertoire : `zz-figures/chapter05/`

  - `05_fig_01_bbn_reaction_network.png`
  - `05_fig_02_dh_model_vs_obs.png`
  - `05_fig_03_yp_model_vs_obs.png`
  - `05_fig_04_chi2_vs_t.png`

Cette organisation est alignée avec celle de CH07 et CH09 :
`zz-scripts/` pour le code, `zz-data/` pour les tables, `zz-figures/`
pour les sorties graphiques.

---

### 4.2 Étape 1 – Génération des données BBN

Commande directe (utilisée par le pipeline minimal) :

```bash
python zz-scripts/chapter05/generate_data_chapter05.py
```

Ce script effectue, en résumé :

1. **Lecture des jalons observationnels**

   - charge `zz-data/chapter05/05_bbn_milestones.csv` ;
   - valide les en‑têtes, les types numériques et l’absence de doublons
     sur la colonne `label` (p. ex. `DH_obs`, `Yp_obs`, etc.).

2. **Construction de la grille temporelle**

   - construit une grille **log‑uniforme** en temps cosmologique `T_Gyr` ;
   - typiquement : `T_Gyr ∈ [1e-6, 14]` Gyr avec un pas `Δ log10 T ≈ 0.01` ;
   - sauvegarde cette grille dans :
     - `zz-data/chapter05/05_bbn_grid.csv`.

3. **Prédictions BBN simplifiées**

   - réalise des **interpolations PCHIP en log–log** pour stabiliser les variations ;
   - construit les prédictions simplifiées pour :
     - `DH_calc` : rapport D/H calculé ;
     - `Yp_calc` : abondance massique en hélium‐4 ;
   - enregistre le tout dans :
     - `zz-data/chapter05/05_bbn_data.csv`.

4. **Calcul de χ²(T)**

   - pour chaque point de la grille `T_Gyr`, calcule le `χ²` cumulé
     (combinant D/H et Yp) à partir des jalons et de leurs incertitudes `σ` ;
   - sauvegarde les résultats dans :
     - `zz-data/chapter05/05_chi2_bbn_vs_T.csv`.

5. **Dérivée lissée de χ²**

   - calcule la dérivée lissée `dχ²/dT` à l’aide d’un filtre **Savitzky–Golay** :
     - `window_length = 7` ;
     - `polyorder = 3` ;
   - écrit le résultat dans :
     - `zz-data/chapter05/05_dchi2_vs_T.csv`.

6. **Tolérances et diagnostics**

   - calcule des écarts relatifs
     `epsilon = |pred − obs| / obs`, et en extrait :
     - `max_epsilon_primary` (jalons primaires, cible ≤ 1 %) ;
     - `max_epsilon_order2` (jalons d’ordre 2, cible ≤ 10 %) ;
   - consigne ces métriques, ainsi que la configuration de la grille,
     dans le fichier :
     - `zz-data/chapter05/05_bbn_params.json`.

7. **Message de fin**

   - en cas de succès, affiche un message du type :
     - `✓ Chapitre 05 : données générées avec succès.`

---

### 4.3 Étape 2 – Figures BBN (01 à 04)

Les quatre figures officielles du chapitre 05 sont générées par
des scripts séparés, à lancer depuis la racine du dépôt.

1. **Réseau de réactions BBN** :

   ```bash
   python zz-scripts/chapter05/plot_fig01_bbn_reaction_network.py
   ```

   Produit / met à jour :

   - `zz-figures/chapter05/05_fig_01_bbn_reaction_network.png`

2. **D/H : modèle vs observations** :

   ```bash
   python zz-scripts/chapter05/plot_fig02_dh_model_vs_obs.py
   ```

   Produit / met à jour :

   - `zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png`

3. **Yp : modèle vs observations** :

   ```bash
   python zz-scripts/chapter05/plot_fig03_yp_model_vs_obs.py
   ```

   Produit / met à jour :

   - `zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png`

4. **χ² BBN vs T** :

   ```bash
   python zz-scripts/chapter05/plot_fig04_chi2_vs_T.py
   ```

   Produit / met à jour :

   - `zz-figures/chapter05/05_fig_04_chi2_vs_t.png`

Dans le pipeline minimal, ces quatre appels sont enchaînés
par `step102_ch05_pipeline_minimal.sh` afin d’obtenir en une seule commande
toutes les figures finales.

---

## 5. Produits finaux attendus (Chapitre 05)

Pour la relecture scientifique et la publication, les fichiers suivants
doivent être considérés comme **produits finaux** de CH05.

### 5.1 Données

- `zz-data/chapter05/05_bbn_grid.csv`  
  → Grille temporelle `T_Gyr` (log‑uniforme) utilisée pour les calculs.

- `zz-data/chapter05/05_bbn_data.csv`  
  → Prédictions BBN (D/H, Yp, etc.) sur la grille `T_Gyr`.

- `zz-data/chapter05/05_chi2_bbn_vs_T.csv`  
  → Valeurs de `χ²` BBN en fonction de `T_Gyr`.

- `zz-data/chapter05/05_dchi2_vs_T.csv`  
  → Dérivée lissée de `χ²` en fonction de `T_Gyr`.

- `zz-data/chapter05/05_bbn_params.json`  
  → Paramètres de grille, constantes de lissage, tolérances et écarts maximaux
    (`max_epsilon_primary`, `max_epsilon_order2`), utilisés comme diagnostics
    de cohérence (et pour l’homogénéisation inter‑chapitres).

### 5.2 Figures

- `zz-figures/chapter05/05_fig_01_bbn_reaction_network.png`
- `zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png`
- `zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png`
- `zz-figures/chapter05/05_fig_04_chi2_vs_t.png`

Ce sont ces fichiers qui doivent être référencés par les manuscrits LaTeX
et par les manifests de publication.

---

## 6. Contrôles d’intégrité et manifests

Après exécution du pipeline minimal, il est recommandé de lancer le diagnostic
des manifests, comme pour CH07 et CH09 :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre les fichiers présents dans le dépôt et :

- `zz-manifests/manifest_master.json`
- `zz-manifests/manifest_publication.json`

Points d’attention :

- toute erreur de type `SHA_MISMATCH` ou « fichier manquant »
  doit être résolue avant de considérer le chapitre comme stable ;
- des **warnings** de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS`
  sont fréquents lorsqu’on vient de régénérer des données ou des figures :
  ils ne bloquent pas la validité scientifique du pipeline minimal,
  mais doivent être nettoyés dans la phase de gel final (avant release).

Ce comportement est homogène à celui des pipelines minimaux de CH07 et CH09.

---

## 7. Conventions numériques et notes sur la CLI

Pour mémoire, les conventions CH05 sont les suivantes :

- **Grille `T_Gyr`** :
  - `T_Gyr ∈ [1e-6, 14]` Gyr (ou bornes proches) ;
  - grille **log‑uniforme** avec `Δ log10 T ≈ 0.01`.

- **Interpolation** :
  - PCHIP log–log pour stabiliser les variations de D/H et Yp
    aux petites échelles.

- **Lissage de la dérivée** :
  - filtre Savitzky–Golay avec
    `window_length = 7`, `polyorder = 3`.

- **Tolérances de classification des jalons** :
  - jalons **primaires** : erreur relative cible ≤ 1 % ;
  - jalons d’**ordre 2** : erreur relative cible ≤ 10 %.

Le script `generate_data_chapter05.py` embarque un bloc **CLI seed MCGT v2**,
comme les autres chapitres homogénéisés (CH07, CH09).  
Dans le cadre du pipeline minimal, l’usage recommandé reste simplement :

```bash
python zz-scripts/chapter05/generate_data_chapter05.py
```

Les options avancées du CLI seed sont réservées à :

- l’intégration dans une future CLI unifiée MCGT ;
- les scénarios d’automatisation (CI, profils `.ci-out`, etc.).

Elles ne modifient pas les conventions principales d’écriture des outputs :

- les données BBN restent dans `zz-data/chapter05/` ;
- les figures BBN restent dans `zz-figures/chapter05/`.

---

Fin du document.
