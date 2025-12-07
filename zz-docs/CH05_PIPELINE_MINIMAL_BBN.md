# Chapitre 05 – Pipeline minimal BBN (nucléosynthèse primordiale)

Ce document décrit le **pipeline minimal** permettant de régénérer les données et les figures
officielles du chapitre 05 (nucléosynthèse primordiale, BBN) à partir du dépôt MCGT.

L’objectif est de fournir un **chemin reproductible, court et stable** pour :
- générer les jeux de données BBN utilisés dans le manuscrit ;
- produire les figures officielles du chapitre 05 ;
- vérifier rapidement que le chapitre est scientifiquement cohérent et techniquement exécutable.

---

## 1. Pré-requis

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépôt MCGT cloné et à jour, positionné à la racine (par ex. `/home/.../MCGT`) ;
- Dépendances installées (SciPy, NumPy, pandas, matplotlib, etc.) via l’environnement standard de MCGT.

Les fichiers d’entrée BBN doivent déjà être présents dans le dépôt :

- `zz-data/chapter05/05_bbn_milestones.csv`
- `zz-data/chapter05/05_bbn_invariants.csv`

Ces fichiers contiennent :
- les jalons observationnels (DH_obs, Yp_obs, incertitudes, etc.) ;
- les invariants ou paramètres nécessaires à la construction du modèle.

---

## 2. Résumé des scripts et fichiers impliqués

### 2.1. Scripts Python (code scientifique)

Tous les scripts CH05 vivent dans :

- `zz-scripts/chapter05/`

Scripts utilisés dans le pipeline minimal :

- `generate_data_chapter05.py`
- `plot_fig01_bbn_reaction_network.py`
- `plot_fig02_dh_model_vs_obs.py`
- `plot_fig03_yp_model_vs_obs.py`
- `plot_fig04_chi2_vs_T.py`

### 2.2. Données CH05

Répertoire :

- `zz-data/chapter05/`

Fichiers principaux (inputs + outputs) :

- **Entrées / jalons** :
  - `05_bbn_milestones.csv`
  - `05_bbn_invariants.csv`

- **Outputs générés par le pipeline** :
  - `05_bbn_data.csv`
  - `05_bbn_grid.csv`
  - `05_chi2_bbn_vs_T.csv`
  - `05_dchi2_vs_T.csv`
  - `05_bbn_params.json`

### 2.3. Figures CH05

Répertoire :

- `zz-figures/chapter05/`

Figures de référence pour le chapitre :

- `05_fig_01_bbn_reaction_network.png`
- `05_fig_02_dh_model_vs_obs.png`
- `05_fig_03_yp_model_vs_obs.png`
- `05_fig_04_chi2_vs_t.png`

---

## 3. TL;DR – Exécution rapide du pipeline minimal

Depuis la racine du dépôt MCGT :

```bash
bash step102_ch05_pipeline_minimal.sh
```

Ce script :

1. exécute `generate_data_chapter05.py` ;
2. exécute les scripts de figures BBN (figures 01 à 04) ;
3. affiche un inventaire final des fichiers de données et des figures CH05.

Si tout se passe bien, tu dois voir un message du type :

- `✓ Chapitre 05 : données générées avec succès.`
- puis la liste des fichiers dans `zz-data/chapter05/` et `zz-figures/chapter05/`.

---

## 4. Pipeline détaillé – étape par étape

### 4.1. Génération des données BBN

Depuis la racine du dépôt :

```bash
python zz-scripts/chapter05/generate_data_chapter05.py
```

Ce script :

1. Charge les jalons observationnels BBN dans  
   `zz-data/chapter05/05_bbn_milestones.csv`.
2. Construit une grille logarithmique en temps cosmologique `T_Gyr`, et l’enregistre dans :  
   - `zz-data/chapter05/05_bbn_grid.csv`
3. Réalise des interpolations monotones (PCHIP) en log–log pour :
   - le deutérium `DH` (jalons avec `DH_obs`) ;
   - l’hélium-4 `Yp` (jalons avec `Yp_obs`).
4. Construit et sauvegarde les prédictions BBN dans :  
   - `zz-data/chapter05/05_bbn_data.csv`
5. Calcule le `χ²` total (DH + Yp) le long de la grille en `T_Gyr`, et sauvegarde dans :  
   - `zz-data/chapter05/05_chi2_bbn_vs_T.csv`
6. Calcule la dérivée lissée de `χ²` en fonction de `T_Gyr` (gradient + Savitzky–Golay) et la sauvegarde dans :  
   - `zz-data/chapter05/05_dchi2_vs_T.csv`
7. Calcule des tolérances relatives `epsilon = |pred - obs| / obs` dans différentes bandes d’incertitude relative, et en extrait :
   - `max_epsilon_primary`
   - `max_epsilon_order2`
   que le script écrit dans :  
   - `zz-data/chapter05/05_bbn_params.json`
8. Affiche un message de succès :  
   - `✓ Chapitre 05 : données générées avec succès.`

### 4.2. Figures BBN

Les figures officielles sont générées par quatre scripts séparés, tous à exécuter depuis la racine du dépôt.

1. **Réseau de réactions BBN** :

   ```bash
   python zz-scripts/chapter05/plot_fig01_bbn_reaction_network.py
   ```

   Produit / rafraîchit :

   - `zz-figures/chapter05/05_fig_01_bbn_reaction_network.png`

2. **DH : modèle vs observations** :

   ```bash
   python zz-scripts/chapter05/plot_fig02_dh_model_vs_obs.py
   ```

   Produit / rafraîchit :

   - `zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png`

3. **Yp : modèle vs observations** :

   ```bash
   python zz-scripts/chapter05/plot_fig03_yp_model_vs_obs.py
   ```

   Produit / rafraîchit :

   - `zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png`

4. **χ² BBN vs T** :

   ```bash
   python zz-scripts/chapter05/plot_fig04_chi2_vs_T.py
   ```

   Produit / rafraîchit :

   - `zz-figures/chapter05/05_fig_04_chi2_vs_t.png`

---

## 5. Fichiers de sortie “officiels” du chapitre 05

Pour la relecture et la publication, les fichiers suivants doivent être considérés comme
**produits finaux** du chapitre 05 :

### 5.1. Données

- `zz-data/chapter05/05_bbn_data.csv`  
  → prédictions BBN (DH, Yp, etc.) sur la grille en `T_Gyr`.

- `zz-data/chapter05/05_bbn_grid.csv`  
  → grille temporelle `T_Gyr` utilisée par les calculs.

- `zz-data/chapter05/05_chi2_bbn_vs_T.csv`  
  → valeurs de `χ²` BBN en fonction de `T_Gyr`.

- `zz-data/chapter05/05_dchi2_vs_T.csv`  
  → dérivée lissée de `χ²` en fonction de `T_Gyr`.

- `zz-data/chapter05/05_bbn_params.json`  
  → paramètres de contrôle (maxima d’epsilon) utilisés comme diagnostics de cohérence.

### 5.2. Figures

- `zz-figures/chapter05/05_fig_01_bbn_reaction_network.png`
- `zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png`
- `zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png`
- `zz-figures/chapter05/05_fig_04_chi2_vs_t.png`

---

## 6. Contrôle d’intégrité et manifests

Une fois le pipeline exécuté, il est recommandé de lancer le diagnostic des manifests :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie :

- la cohérence entre les fichiers de données / figures et
  - `zz-manifests/manifest_master.json`
  - `zz-manifests/manifest_publication.json`
- l’absence d’erreurs de type :
  - `SHA_MISMATCH`
  - fichiers manquants

Des **warnings** de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent subsister, en particulier
lorsque des scripts ou des données ont été modifiés récemment. Ils ne bloquent pas
l’exécution du pipeline minimal, mais doivent être surveillés dans la phase de nettoyage final.

---

## 7. Notes sur le CLI seed MCGT (generate_data_chapter05.py)

Le script `generate_data_chapter05.py` inclut un bloc de **CLI seed MCGT v2**.  
Dans le pipeline scientifique standard, l’usage recommandé est simplement :

```bash
python zz-scripts/chapter05/generate_data_chapter05.py
```

Le bloc CLI seed est principalement destiné à l’intégration future dans une CLI unifiée MCGT
et à des scénarios d’automatisation (CI, profils `.ci-out`, etc.).  
Il ne modifie pas les conventions principales d’écriture des outputs CH05 :

- les données restent dans `zz-data/chapter05/` ;
- les figures restent dans `zz-figures/chapter05/`.

---

Fin du document.
