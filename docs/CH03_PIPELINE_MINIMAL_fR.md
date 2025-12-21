# Chapitre 03 – Pipeline minimal f(R) (stabilité)

Ce document décrit le **pipeline minimal** permettant de régénérer, à partir du dépôt
MCGT, les données et figures essentielles du **chapitre 03 – stabilité de f(R)**.

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- générer les jeux de données de stabilité f(R) utilisés dans le manuscrit ;
- produire les figures principales du chapitre 03 ;
- vérifier rapidement que le chapitre est scientifiquement cohérent et techniquement exécutable.

---

## 1. Objectif

Le pipeline minimal CH03 repose sur le script scientifique principal :

- `scripts/chapter03/generate_data_chapter03.py`

complété par une famille de scripts de figures.  
Il est conçu pour :

- reconstruire les quantités de stabilité (\(f_R, f_{RR}, m_s^2/R_0\)) sur une grille contrôlée ;
- produire les domaines de stabilité \((\beta, \gamma)\) et les courbes associées ;
- rester compatible avec les manifests (`manifest_master` et `manifest_publication`).

---

## 2. Pré‑requis

Depuis la racine du dépôt `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `scipy`, `matplotlib`, etc. ;
- Fichiers de configuration accessibles :

  - `config/gw_phase.ini`  (section `[scan]` pour la grille) ;
  - `config/mcgt-global-config.ini` (paramètres globaux, si utilisés par CH03).

Les chemins sont supposés respecter la hiérarchie standard du dépôt MCGT.

---

## 3. Résumé rapide – exécution canonique

Depuis la racine du dépôt :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire

# 1) Générer les données de stabilité f(R)
python scripts/chapter03/generate_data_chapter03.py   --config config/gw_phase.ini   --npts 700

# 2) Régénérer les figures principales (Fig. 01 à 08)
python scripts/chapter03/10_fig01_fR_stability_domain.py
python scripts/chapter03/10_fig02_fR_fRR_vs_f.py
python scripts/chapter03/10_fig03_ms2_R0_vs_f.py
python scripts/chapter03/10_fig04_fR_fRR_vs_f.py
python scripts/chapter03/10_fig05_interpolated_milestones.py
python scripts/chapter03/10_fig06_grid_quality.py
python scripts/chapter03/10_fig07_ricci_fR_vs_z.py
python scripts/chapter03/10_fig08_ricci_fR_vs_T.py
```

En fin d’exécution, toutes les données f(R) de référence et les figures CH03
doivent être présentes dans `assets/zz-data/chapter03/` et `assets/zz-figures/chapter03/`.

---

## 4. Scripts, données et figures impliqués

### 4.1. Scripts Python (logique scientifique)

Répertoire :

- `scripts/chapter03/`

Scripts utilisés par le pipeline minimal :

- `generate_data_chapter03.py`
- `10_fig01_fR_stability_domain.py`
- `10_fig02_fR_fRR_vs_f.py`
- `10_fig03_ms2_R0_vs_f.py`
- `10_fig04_fR_fRR_vs_f.py`
- `10_fig05_interpolated_milestones.py`
- `10_fig06_grid_quality.py`
- `10_fig07_ricci_fR_vs_z.py`
- `10_fig08_ricci_fR_vs_T.py`

Ces scripts consomment et produisent uniquement des fichiers dans `assets/zz-data/chapter03/`
et `assets/zz-figures/chapter03/`, en cohérence avec le reste du projet.

### 4.2. Données CH03 (inputs + outputs)

Répertoire principal :

- `assets/zz-data/chapter03/`

Fichiers d’entrée principaux :

- `03_ricci_fR_milestones.csv`  
  → jalons \(R/R_0\) + valeurs de référence \(f_R, f_{RR}\).

Fichiers produits par le pipeline minimal :

- `03_fR_stability_data.csv`  
  → table principale de stabilité f(R) sur la grille densifiée ;

- `03_fR_stability_domain.csv`  
  → domaine de stabilité en \((\beta, \gamma_{\min}, \gamma_{\max})\) ;

- `03_fR_stability_boundary.csv`  
  → frontière de stabilité \(\gamma_{\text{limit}}(\beta)\) sur le domaine valide ;

- `03_ricci_fR_vs_z.csv`  
  → profil \((R/R_0, f_R, f_{RR}, z)\) en fonction du décalage spectral \(z\) ;

- `03_ricci_fR_vs_T.csv`  
  → profil \((R/R_0, f_R, f_{RR}, T_{\rm Gyr})\) en fonction du temps cosmologique ;

- `03_fR_stability_meta.json`  
  → métadonnées résumant le run (nombre de points, fichiers exportés, etc.).

### 4.3. Figures CH03

Répertoire :

- `assets/zz-figures/chapter03/`

Figures principales attendues :

- `fig_01_fR_stability_domain.png`  
  → domaine de stabilité en \((\beta, \gamma)\) ;

- `fig_02_fR_fRR_vs_R.png`  
  → diagnostics \(f_R\) et \(f_{RR}\) vs \(R/R_0\) ;

- `fig_03_ms2_R0_vs_R.png`  
  → masse scalaire normalisée \(m_s^2/R_0\) vs \(R/R_0\) ;

- `fig_04_fR_fRR_vs_R.png`  
  → vue alternative de \(f_R\) et \(f_{RR}\) vs \(R/R_0\) (zoom / mise en forme différente) ;

- `fig_05_interpolated_milestones.png`  
  → jalons vs courbes interpolées (contrôle de cohérence) ;

- `fig_06_grid_quality.png`  
  → qualité de la grille (log-uniformité, pas en \(\log_{10} R/R_0\)) ;

- `fig_07_ricci_fR_vs_z.png`  
  → \(f_R, f_{RR}\) vs \(z\) ;

- `fig_08_ricci_fR_vs_T.png`  
  → \(f_R, f_{RR}\) vs \(T_{\rm Gyr}\).

---

## 5. Pipeline détaillé – étape par étape

### 5.1. Génération des données de stabilité f(R)

Depuis la racine du dépôt :

```bash
python scripts/chapter03/generate_data_chapter03.py   --config config/gw_phase.ini   --npts 700
```

Ce script :

1. lit la configuration `[scan]` dans `config/gw_phase.ini`  
   (paramètres contrôlant la grille en fréquence ou en \(R/R_0\)) ;
2. charge les jalons `03_ricci_fR_milestones.csv` ;
3. construit une grille densifiée en `R_over_R0` (log‑uniforme) ;
4. interpole \(f_R\) et \(f_{RR}\) sur cette grille via PCHIP (log10) ;
5. calcule la quantité de stabilité principale :

   \[
   m_s^2/R_0 = \frac{f_R - (R/R_0)\,f_{RR}}{3\,f_{RR}} \,,
   \]

   et l’exporte dans `03_fR_stability_data.csv` ;
6. construit les tables de domaine / frontière de stabilité :
   - `03_fR_stability_domain.csv` ;
   - `03_fR_stability_boundary.csv` ;
7. projette \((R/R_0, f_R, f_{RR})\) vers les espaces \(z\) et \(T_{\rm Gyr}\) :
   - `03_ricci_fR_vs_z.csv` ;
   - `03_ricci_fR_vs_T.csv` ;
8. rassemble des métadonnées de run dans :
   - `03_fR_stability_meta.json` ;
9. affiche un message de succès si toutes les étapes se déroulent correctement.

### 5.2. Régénération des figures

Une fois les données mises à jour, les figures officielles sont générées par :

```bash
python scripts/chapter03/10_fig01_fR_stability_domain.py
python scripts/chapter03/10_fig02_fR_fRR_vs_f.py
python scripts/chapter03/10_fig03_ms2_R0_vs_f.py
python scripts/chapter03/10_fig04_fR_fRR_vs_f.py
python scripts/chapter03/10_fig05_interpolated_milestones.py
python scripts/chapter03/10_fig06_grid_quality.py
python scripts/chapter03/10_fig07_ricci_fR_vs_z.py
python scripts/chapter03/10_fig08_ricci_fR_vs_T.py
```

Chaque script met à jour la figure correspondante dans `assets/zz-figures/chapter03/`.  
Les figures sont généralement produites en PNG (300 dpi) avec un style harmonisé
avec les autres chapitres.

---

## 6. Produits finaux « officiels » pour le chapitre 03

Pour la relecture et la publication, les fichiers suivants sont considérés comme
**produits principaux** du chapitre 03 :

### 6.1. Données

- `assets/zz-data/chapter03/03_fR_stability_data.csv`  
  → grille densifiée en \(R/R_0\), avec \(f_R, f_{RR}, m_s^2/R_0\).

- `assets/zz-data/chapter03/03_fR_stability_domain.csv`  
  → domaine de stabilité \((\beta, \gamma_{\min}, \gamma_{\max})\).

- `assets/zz-data/chapter03/03_fR_stability_boundary.csv`  
  → frontière de stabilité \(\gamma_{\text{limit}}(\beta)\).

- `assets/zz-data/chapter03/03_ricci_fR_vs_z.csv`  
  → interpolation de \(f_R, f_{RR}\) vs \(z\).

- `assets/zz-data/chapter03/03_ricci_fR_vs_T.csv`  
  → interpolation de \(f_R, f_{RR}\) vs \(T_{\rm Gyr}\).

- `assets/zz-data/chapter03/03_fR_stability_meta.json`  
  → méta‑informations de run (nombre de points, fichiers, versions, etc.).

### 6.2. Figures

- `assets/zz-figures/chapter03/03_fig_01_fR_stability_domain.png`
- `assets/zz-figures/chapter03/03_fig_02_fR_fRR_vs_R.png`
- `assets/zz-figures/chapter03/03_fig_03_ms2_R0_vs_R.png`
- `assets/zz-figures/chapter03/03_fig_04_fR_fRR_vs_R.png`
- `assets/zz-figures/chapter03/03_fig_05_interpolated_milestones.png`
- `assets/zz-figures/chapter03/03_fig_06_grid_quality.png`
- `assets/zz-figures/chapter03/03_fig_07_ricci_fR_vs_z.png`
- `assets/zz-figures/chapter03/03_fig_08_ricci_fR_vs_T.png`

---

## 7. Contrôle d’intégrité et manifests

Après exécution du pipeline minimal CH03, il est recommandé de lancer
le diagnostic des manifests :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie la cohérence entre :

- les fichiers de données / figures CH03 ;
- `assets/zz-manifests/manifest_master.json` ;
- `assets/zz-manifests/manifest_publication.json`.

Objectifs pour le pipeline minimal :

- aucune erreur de type `SHA_MISMATCH` ou fichier manquant sur les produits
  listés en §6.1–6.2 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent exister
  pendant les phases d’édition active, mais doivent être réduits au minimum
  au moment de la publication.

---

## 8. Méthodes numériques & paramètres (rappel synthétique)

Les détails complets sont documentés dans les scripts CH03, mais les grandes lignes sont :

- **Grille en \(R/R_0\)** :  
  - jalons issus de `03_ricci_fR_milestones.csv` ;  
  - densification contrôlée par les paramètres `[scan]` dans `gw_phase.ini`
    (pas log‑uniforme en général).

- **Interpolation** :  
  - PCHIP appliqué sur \(\log_{10} f_R\) et \(\log_{10} f_{RR}\) pour limiter
    les oscillations et préserver la monotonie ;  
  - conversions éventuelles vers d’autres variables (\(z, T_{\rm Gyr}\)) via
    des interpolations monotones supplémentaires.

- **Masse scalaire et stabilité** :  
  - calcul de \(m_s^2/R_0\) via  
    \(m_s^2/R_0 = (f_R - (R/R_0) f_{RR}) / (3 f_{RR})\) ;  
  - domaine de stabilité défini par des conditions du type \(\gamma_{\min} \ge 0\),
    \(\gamma_{\max}\) dérivé de \(m_s^2/R_0\).

- **Qualité de la grille** :  
  - contrôle de l’uniformité du pas en \(\log_{10} R/R_0\) ;  
  - vérification de l’absence de discontinuités ou de points isolés.

Ces conventions sont choisies pour rester compatibles avec la calibration globale
et les autres chapitres (en particulier les chapitres 1, 2 et 6).

---

## 9. Notes LaTeX / versionnage & reproductibilité

- Les sources LaTeX du chapitre 03 se trouvent dans :

  - `03-stabilite-fR/03_stabilite_fR_conceptuel.tex`  
  - `03-stabilite-fR/03_stabilite_fR_details.tex`

  Compilation (exemple) :

  ```bash
  pdflatex -interaction=nonstopmode 03-stabilite-fR/03_stabilite_fR_conceptuel.tex
  pdflatex -interaction=nonstopmode 03-stabilite-fR/03_stabilite_fR_details.tex
  ```

- Pour la **reproductibilité**, toute modification affectant les résultats CH03
  (données ou figures) devrait idéalement :

  - être effectuée dans une branche dédiée ;
  - être accompagnée d’une exécution propre du pipeline minimal (cf. §3–5) ;
  - passer `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
  - mettre à jour `CHANGELOG.md` si les chiffres ou figures publiées changent.

Fin du document.
