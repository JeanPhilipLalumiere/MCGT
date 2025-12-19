# Chapitre 06 – Pipeline minimal canonique (rayonnement CMB)

Ce document décrit le **pipeline minimal canonique** permettant de relancer, à partir du dépôt
MCGT, les calculs et figures essentiels du **chapitre 06 – rayonnement CMB**.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- générer ou mettre à jour les fichiers CMB de base (spectres ΛCDM et MCGT) ;
- construire les différences ΔCℓ et diagnostics associés ;
- régénérer les figures principales du chapitre 06 ;
- vérifier rapidement que le chapitre est scientifiquement cohérent et techniquement exécutable.

---

## 1. Objectif

Le pipeline minimal CH06 s’appuie sur un petit nombre de scripts Python :

- `zz-scripts/chapter06/generate_pdot_plateau_vs_z.py`  
- `zz-scripts/chapter06/generate_data_chapter06.py`  
- les scripts de figures `10_fig0x_*.py` du chapitre 06.

Contrairement au guide complet (injection détaillée dans CAMB, scans étendus, etc.),
ce document se concentre sur :

- un **profil canonique** `alpha, q0star` (par exemple `alpha = 0.20`, `q0star = -0.10`) ;
- une **chaîne courte** de commandes reproductibles ;
- les **produits finaux** à considérer comme « officiels » pour CH06.

---

## 2. Pré‑requis

Depuis la racine du dépôt `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `scipy`, `matplotlib`, etc. ;
- Installation fonctionnelle de **CAMB (API Python)**, compilée et accessible
  dans l’environnement ;
- Fichiers et configurations accessibles :

  - `zz-configuration/camb_exact_plateau.ini` (ou équivalent) ;
  - `zz-scripts/chapter06/generate_pdot_plateau_vs_z.py`  
  - `zz-scripts/chapter06/generate_data_chapter06.py`.

Dans le pipeline minimal, on suppose que les éléments suivants sont soit
déjà présents, soit générés par les étapes ci‑dessous :

- `zz-data/chapter06/06_hubble_mcgt.dat`  
- `zz-data/chapter06/06_cls_spectrum_lcdm.dat`  
- `zz-data/chapter06/06_cls_spectrum.dat`.

---

## 3. Résumé rapide – séquence minimale

Depuis la racine du dépôt :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire

# 1) Expansion MCGT → fichier H(z)/H0
python zz-scripts/chapter06/generate_pdot_plateau_vs_z.py

# 2) Pipeline CMB canonique (spectres + ΔCℓ + JSON)
python zz-scripts/chapter06/generate_data_chapter06.py        --alpha 0.20        --q0star -0.10        --export-derivative

# 3) Figures principales (Fig. 01 à 05)
python zz-scripts/chapter06/10_fig01_cmb_dataflow_diagram.py
python zz-scripts/chapter06/10_fig02_cls_lcdm_vs_mcgt.py
python zz-scripts/chapter06/10_fig03_delta_cls_relative.py
python zz-scripts/chapter06/10_fig04_delta_rs_vs_params.py
python zz-scripts/chapter06/10_fig05_delta_chi2_heatmap.py
```

En fin d’exécution, on doit trouver :

- les spectres **ΛCDM** et **MCGT** dans `zz-data/chapter06/` ;
- les fichiers ΔCℓ et scans principaux (Δr_s, χ²) ;
- les figures CMB mises à jour dans `zz-figures/chapter06/` ;
- les paramètres et métadonnées dans `zz-data/chapter06/06_params_cmb.json`.

---

## 4. Scripts, données et figures impliqués

### 4.1. Scripts Python (logique scientifique)

Répertoire CH06 :

- `zz-scripts/chapter06/generate_pdot_plateau_vs_z.py`  
  → génère la loi d’expansion MCGT (plateau) en fonction de z, utilisée par CAMB.

- `zz-scripts/chapter06/generate_data_chapter06.py`  
  → script principal du chapitre 06. Il orchestre l’appel à CAMB (via l’API Python)
    et/ou lit les spectres déjà présents, puis construit tous les fichiers CMB
    de travail (ΔCℓ, scans, JSON).

Scripts de figures :

- `zz-scripts/chapter06/10_fig01_cmb_dataflow_diagram.py`
- `zz-scripts/chapter06/10_fig02_cls_lcdm_vs_mcgt.py`
- `zz-scripts/chapter06/10_fig03_delta_cls_relative.py`
- `zz-scripts/chapter06/10_fig04_delta_rs_vs_params.py`
- `zz-scripts/chapter06/10_fig05_delta_chi2_heatmap.py`

Éventuels utilitaires et wrappers :

- `zz-scripts/chapter06/run_camb_chapter06.bat` (optionnel, environnement local).

### 4.2. Données CH06 (inputs + outputs)

Répertoire principal :

- `zz-data/chapter06/`

Fichiers clefs de spectre :

- `06_cls_spectrum_lcdm.dat`  
  → spectre **ΛCDM** de référence :  
  colonnes `ell`, `Cl_LCDM` (µK²), en‑tête `# ell   Cl_LCDM`.

- `06_cls_spectrum.dat`  
  → spectre **MCGT** :  
  colonnes `ell`, `Cl_MCGT` (µK²), en‑tête `# ell   Cl_MCGT`.

Différences de spectres :

- `06_delta_cls.csv`  
  → `ell`, `delta_Cl` avec  
  \(\Delta C_\ell = C_\ell^{\rm MCGT} - C_\ell^{\Lambda\rm CDM}\).

- `06_delta_cls_relative.csv`  
  → `ell`, `delta_Cl_rel` avec  
  \(\Delta C_\ell^{\rm rel} = (C_\ell^{\rm MCGT}-C_\ell^{\Lambda\rm CDM}) / C_\ell^{\Lambda\rm CDM}\).

Diagnostics sur l’horizon sonore et χ² :

- `06_delta_rs_scan.csv`  
  → profil 1D \(q_0^\* \mapsto \Delta r_s / r_s\).

- `06_delta_rs_scan2D.csv`  
  → carte 2D `(alpha, q0star) → (r_s, delta_rs_rel)`.

- `06_cmb_chi2_scan2D.csv`  
  → carte 2D `(alpha, q0star) → chi2`.

Expansion MCGT :

- `06_hubble_mcgt.dat`  
  → `z`, `H_over_H0` (ou ratio vs ΛCDM) utilisé par CAMB.

Autres sorties optionnelles :

- `06_delta_Tm_scan.csv`  
  → `k`, `delta_Tm` (transfert de matière).

- `06_alpha_evolution.csv`  
  → `alpha, A_s, n_s` si l’export de l’évolution spectrale est activé.

Paramètres et métadonnées :

- `06_params_cmb.json`  
  → valeurs effectives de `alpha`, `q0star`, bornes multipolaires, paramètres cosmologiques
    et tolérances (voir §8).

### 4.3. Figures CH06

Répertoire :

- `zz-figures/chapter06/`

Figures principales :

- `fig_01_cmb_dataflow_diagram.png`  
  → schéma du flux de données (expansion → CAMB → Cℓ/ΔCℓ).

- `fig_02_cls_lcdm_vs_mcgt.png`  
  → spectres Cℓ ΛCDM vs MCGT (échelles adaptées).

- `fig_03_delta_cls_relative.png`  
  → ΔCℓ/Cℓ en fonction de ℓ.

- `fig_04_delta_rs_vs_params.png`  
  → Δr_s / r_s en fonction des paramètres (par ex. q0star, alpha).

- `fig_05_delta_chi2_heatmap.png`  
  → carte 2D χ²(α, q0star).

---

## 5. Pipeline détaillé – étape par étape

### 5.1. Expansion plateau vs z

Depuis la racine :

```bash
python zz-scripts/chapter06/generate_pdot_plateau_vs_z.py
```

Ce script :

1. lit les paramètres d’expansion MCGT (plateau) ;
2. construit une grille en redshift `z` ;
3. calcule `H(z)/H0` (ou un ratio vs ΛCDM) ;
4. écrit le résultat dans :

   - `zz-data/chapter06/06_hubble_mcgt.dat`

et, selon la configuration, dans un fichier auxiliaire `zz-configuration/pdot_plateau_vs_z.dat`
utilisé par CAMB.

### 5.2. Pipeline CMB principal – generate_data_chapter06.py

```bash
python zz-scripts/chapter06/generate_data_chapter06.py        --alpha 0.20        --q0star -0.10        --export-derivative
```

Rôle du script :

1. Configure l’API CAMB avec les paramètres cosmologiques de référence
   (Planck 2018 ou équivalent) et les valeurs `(alpha, q0star)` fournies ;
2. Injecte l’expansion MCGT (via `06_hubble_mcgt.dat` ou `pdot_plateau_vs_z.dat`) ;
3. Appelle CAMB pour produire les spectres Cℓ :
   - spectre ΛCDM → `06_cls_spectrum_lcdm.dat`  
   - spectre MCGT → `06_cls_spectrum.dat`
4. Construit les fichiers dérivés :
   - `06_delta_cls.csv`  
   - `06_delta_cls_relative.csv`
5. Si l’option `--export-derivative` est activée, calcule également :
   - scans Δr_s : `06_delta_rs_scan.csv`, `06_delta_rs_scan2D.csv` ;
   - carte χ² : `06_cmb_chi2_scan2D.csv` ;
   - éventuellement `06_delta_Tm_scan.csv`.
6. Rassemble les paramètres et tolérances numériques dans :
   - `06_params_cmb.json`
7. Affiche un message de succès si tous les fichiers clés ont été produits.

### 5.3. Figures CMB

Les figures officielles se régénèrent ensuite via :

```bash
python zz-scripts/chapter06/10_fig01_cmb_dataflow_diagram.py
python zz-scripts/chapter06/10_fig02_cls_lcdm_vs_mcgt.py
python zz-scripts/chapter06/10_fig03_delta_cls_relative.py
python zz-scripts/chapter06/10_fig04_delta_rs_vs_params.py
python zz-scripts/chapter06/10_fig05_delta_chi2_heatmap.py
```

Chaque script lit les fichiers correspondants dans `zz-data/chapter06/` et met à jour
la figure associée dans `zz-figures/chapter06/`.

---

## 6. Produits finaux « officiels » pour le chapitre 06

### 6.1. Données

Pour la relecture scientifique et la publication, les fichiers suivants doivent être
considérés comme **produits finaux** du chapitre 06 :

- `zz-data/chapter06/06_cls_spectrum_lcdm.dat`  
  → spectre Cℓ de référence ΛCDM.

- `zz-data/chapter06/06_cls_spectrum.dat`  
  → spectre Cℓ MCGT (profil canonique).

- `zz-data/chapter06/06_delta_cls.csv`  
  → ΔCℓ en µK².

- `zz-data/chapter06/06_delta_cls_relative.csv`  
  → ΔCℓ / Cℓ (adimensionnel).

- `zz-data/chapter06/06_delta_rs_scan.csv`  
- `zz-data/chapter06/06_delta_rs_scan2D.csv`  
- `zz-data/chapter06/06_cmb_chi2_scan2D.csv`  

- `zz-data/chapter06/06_hubble_mcgt.dat`  
  → loi d’expansion MCGT utilisée pour les calculs CMB.

- `zz-data/chapter06/06_params_cmb.json`  
  → paramètres, tolérances et métriques de contrôle.

Les autres fichiers (par ex. `06_delta_Tm_scan.csv`, `06_alpha_evolution.csv`) peuvent
être considérés comme des diagnostics complémentaires.

### 6.2. Figures

- `zz-figures/chapter06/06_fig_01_cmb_dataflow_diagram.png`
- `zz-figures/chapter06/06_fig_02_cls_lcdm_vs_mcgt.png`
- `zz-figures/chapter06/06_fig_03_delta_cls_relative.png`
- `zz-figures/chapter06/06_fig_04_delta_rs_vs_params.png`
- `zz-figures/chapter06/06_fig_05_delta_chi2_heatmap.png`

Ces figures constituent la base de la narration scientifique du chapitre 06.

---

## 7. Contrôle d’intégrité et manifests

Après exécution du pipeline minimal CH06, il est recommandé de lancer :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre :

- les fichiers de données / figures CH06 ;
- `zz-manifests/manifest_master.json` ;
- `zz-manifests/manifest_publication.json`.

Objectifs pour le pipeline minimal :

- aucune erreur de type `SHA_MISMATCH` ou fichier manquant sur les produits
  listés en §6 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent exister
  pendant les phases d’édition active, mais doivent être réduits au minimum
  au moment de la publication.

---

## 8. Méthodes numériques et paramètres (rappel synthétique)

Les détails complets sont documentés dans les scripts CH06, mais les grandes lignes sont :

- **Grille en multipôles ℓ** :
  - typiquement log‑uniforme sur `[ell_min, ell_max]` (ex. `[2, 3000]`) ;
  - contrôlée par `n_points` ou un pas constant en `log10(ell)`.

- **Interpolation des spectres Cℓ** :
  - interpolation PCHIP en espace `(log10 ℓ, log10 Cℓ)` ;
  - extrapolation contrôlée (`extrapolate=True`) puis `clip` aux bornes physiques.

- **Lissage et dérivées** :
  - filtre Savitzky–Golay pour d’éventuelles dérivées ou lissages de χ² :
    fenêtre typique `7`, ordre `3`, `mode='interp'`.

- **Tolérances** (stockées dans `06_params_cmb.json`) :
  - `thresholds.primary ≈ 0.01` (1 %) ;
  - `thresholds.order2 ≈ 0.10` (10 %) ;
  - `max_delta_Cl_rel` consigne la variation relative maximale ΔCℓ/Cℓ
    sur le domaine étudié.

- **Paramétrisation du spectre primordial** :
  - références Planck 2018 : `As0 ≈ 2.10e-9`, `ns0 ≈ 0.9649` ;
  - modèle linéaire en `alpha` :  
    \(A_s(\alpha) = A_s^0 (1 + c_1 \alpha)\),  
    \(n_s(\alpha) = n_s^0 + c_2 \alpha\) ;
  - les coefficients `c1`, `c2` ainsi que la valeur retenue de `alpha`
    sont consignés dans `06_params_cmb.json`.

---

## 9. Notes LaTeX / versionnage & reproductibilité

- Les sources LaTeX du chapitre 06 se trouvent dans :

  - `06-rayonnement-cmb/06_cmb_conceptuel.tex`  
  - `06-rayonnement-cmb/06_cmb_details.tex`

  Compilation (exemple) :

  ```bash
  pdflatex -interaction=nonstopmode 06-rayonnement-cmb/06_cmb_conceptuel.tex
  pdflatex -interaction=nonstopmode 06-rayonnement-cmb/06_cmb_details.tex
  ```

- Pour la **reproductibilité**, toute modification affectant les résultats CH06
  (données ou figures) devrait idéalement :

  - être effectuée dans une branche dédiée ;
  - être accompagnée d’une exécution propre du pipeline minimal (§3) ;
  - passer `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
  - mettre à jour `CHANGELOG.md` si les chiffres ou figures publiées changent.

Fin du document.
