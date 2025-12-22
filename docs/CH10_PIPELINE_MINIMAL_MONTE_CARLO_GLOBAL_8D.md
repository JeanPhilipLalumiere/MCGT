
# Chapter 10 – Pipeline minimal canonique (Monte‑Carlo global 8D)

Ce document décrit le **pipeline minimal canonique** permettant de relancer,
à partir du dépôt MCGT, les calculs essentiels du **chapitre 10 – Monte‑Carlo global 8D**
(métriques p95 circulaires, sélection top‑k, figures principales).

L’objectif est de fournir un **chemin court, reproductible et stable** pour :

- évaluer ou ré‑évaluer les métriques p95 sur la fenêtre `[20, 300]` Hz ;
- produire la version **circulaire** de la métrique (`p95_20_300_recalc`) sur l’ensemble des échantillons 8D ;
- générer les jeux de données agrégés et les fichiers `best` / bootstrap ;
- régénérer les figures principales CH10 basées sur les métriques circulaires.

---

## 1. Pré‑requis

Depuis la **racine du dépôt** `MCGT` :

- Environnement Python MCGT activé (par ex. `mcgt-dev`) ;
- Dépendances installées via l’environnement standard MCGT :
  `numpy`, `pandas`, `matplotlib` (et `scipy` si utilisé par certains scripts) ;
- OS : Linux / macOS / WSL (hors Windows natif pur).

Les fichiers d’entrée CH10 doivent déjà être présents :

- `assets/zz-data/chapter10/10_mc_config.json`  
  → configuration de l’expérience (grille 8D, fenêtrage fréquentiel, paramètres bootstrap, etc.) ;
- `assets/zz-data/chapter10/10_mc_samples.csv`  
  → échantillons / grille dans l’espace 8D (`m1…m8`).

Les scripts CH10 vivent dans :

- `scripts/10_global_scan/`

Les figures CH10 sont écrites dans :

- `assets/zz-figures/chapter10/`

---

## 2. Résumé rapide – séquence minimale

Depuis la racine du dépôt :

```bash
cd ~/MCGT  # adapter si nécessaire

# 1) Résultats Monte‑Carlo 8D (métriques "historiques" linéaires)
python scripts/10_global_scan/generate_data_chapter10.py \
  --config  assets/zz-data/chapter10/10_mc_config.json \
  --samples assets/zz-data/chapter10/10_mc_samples.csv \
  --out     assets/zz-data/chapter10/10_mc_results.csv

# 2) Recalcul circulaire de p95_20_300 → colonne de référence
python scripts/10_global_scan/recompute_p95_circular.py \
  --in  assets/zz-data/chapter10/10_mc_results.csv \
  --out assets/zz-data/chapter10/10_mc_results.circ.csv

# 3) Ajout des jalons f_peak (optionnel mais recommandé)
python scripts/10_global_scan/add_phi_at_fpeak.py \
  --in  assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out assets/zz-data/chapter10/10_mc_results.circ.with_fpeak.csv

# 4) Agrégats principaux sur [20, 300] Hz
python scripts/10_global_scan/eval_primary_metrics_20_300.py \
  --in  assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out assets/zz-data/chapter10/10_mc_results.circ.agg.csv

# 5) Bootstrap top‑k sur p95_20_300_recalc
python scripts/10_global_scan/bootstrap_topk_p95.py \
  --in  assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out assets/zz-data/chapter10/10_mc_best_bootstrap.json \
  --k 20 --outer 400 --inner 2000 --alpha 0.05 --seed 12345

# 6) Figures principales basées sur la métrique circulaire
python scripts/10_global_scan/10_fig_01_iso_p95_maps.py \
  --results assets/zz-data/chapter10/10_mc_results.circ.csv \
  --p95-col p95_20_300_recalc \
  --m1-col m1 --m2-col m2 \
  --out assets/zz-figures/chapter10/10_fig_01_iso_p95_maps.png \
  --levels 16 --dpi 300

python scripts/10_global_scan/10_fig_04_p95_comparison.py \
  --results assets/zz-data/chapter10/10_mc_results.circ.csv \
  --orig-col p95_20_300 --recalc-col p95_20_300_recalc \
  --out assets/zz-figures/chapter10/10_fig_04_p95_comparison.png \
  --dpi 300 --bins 50

python scripts/10_global_scan/10_fig_05_hist_cdf_metrics.py \
  --results assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out assets/zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png \
  --ref-p95 0.7104087123286049 --bins 50 --dpi 150
```

Si tout se passe bien, tu dois notamment vérifier que :

- `assets/zz-data/chapter10/10_mc_results.circ.csv` contient la colonne
  `p95_20_300_recalc` ;
- les figures `fig_01_iso_p95_maps.png`, `fig_04_scatter_p95_recalc_vs_orig.png`
  et `fig_05_hist_cdf_metrics.png` sont créées / mises à jour dans
  `assets/zz-figures/chapter10/`.

---

## 3. Scripts, données et figures impliqués

### 3.1. Scripts Python (logique scientifique)

Répertoire :

- `scripts/10_global_scan/`

Scripts utilisés dans le **pipeline minimal canonique** :

- `generate_data_chapter10.py`  
  → calcule les métriques linéaires historiques, écrit `10_mc_results.csv`.
- `recompute_p95_circular.py`  
  → ajoute `p95_20_300_recalc` et écrit `10_mc_results.circ.csv`.
- `add_phi_at_fpeak.py` *(optionnel recommandé)*  
  → ajoute `f_peak_Hz`, `phi_ref_at_fpeak`, `phi_mcgt_at_fpeak` dans
  `10_mc_results.circ.with_fpeak.csv`.
- `eval_primary_metrics_20_300.py`  
  → construit les agrégats sur `[20, 300]` Hz, écrit `10_mc_results.circ.agg.csv`.
- `bootstrap_topk_p95.py`  
  → sélection top‑k + bootstrap sur `p95_20_300_recalc`, écrit
  `10_mc_best_bootstrap.json` (et éventuellement `10_mc_best.json`).

Scripts de figures au cœur du pipeline minimal :

- `10_fig01_iso_p95_maps.py`
- `10_fig04_scatter_p95_recalc_vs_orig.py`
- `10_fig05_hist_cdf_metrics.py`

Scripts de diagnostics / figures avancées (hors pipeline minimal strict, mais
compatibles avec cette structure) :

- `10_fig02_scatter_phi_at_fpeak.py`
- `10_fig03_convergence_p95_vs_n.py`
- `10_fig03b_bootstrap_coverage_vs_n_hires.py`
- `10_fig06_residual_map.py`
- `10_fig07_synthesis.py`
- scripts de QC : `check_metrics_consistency.py`, `qc_wrapped_vs_unwrapped.py`,
  `inspect_topk_residuals.py`, etc.

---

### 3.2. Données CH10

Répertoire principal :

- `assets/zz-data/chapter10/`

**Entrées principales** :

- `10_mc_config.json`  
  → configuration de l’expérience (fenêtre fréquentielle, paramètres bootstrap,
  grilles `m1…m8`, drapeau `outputs.with_fpeak`, etc.).
- `10_mc_samples.csv`  
  → échantillons / grille 8D (colonnes `m1,…,m8`, éventuellement `seed`).

**Sorties produites par le pipeline minimal** :

- `10_mc_results.csv`  
  → résultats Monte‑Carlo avec `p95_20_300` (historique linéaire) et métriques associées.
- `10_mc_results.circ.csv`  
  → même contenu, mais avec la colonne **référence** `p95_20_300_recalc` (définition circulaire).

  Colonnes typiques :
  - `m1,…,m8` ;
  - `p95_20_300` (si présent) ;
  - `p95_20_300_recalc` (métrique canonique).

- `10_mc_results.circ.with_fpeak.csv` *(optionnel)*  
  → ajoute les colonnes liées au jalon fréquentiel :
  - `f_peak_Hz` ;
  - `phi_ref_at_fpeak` ;
  - `phi_mcgt_at_fpeak`.

- `10_mc_results.circ.agg.csv`  
  → agrégats sur `[20, 300]` Hz (par cellule ou global, selon config) :

  Colonnes typiques :
  - clés de groupement (par ex. `m1`, `m2`, …) ;
  - `count` ;
  - `mean_p95_recalc`, `median_p95_recalc` ;
  - autres stats éventuelles (quantiles, écart‑type, etc.).

- `10_mc_best_bootstrap.json`  
  → statistiques bootstrap sur les meilleurs points (top‑k) selon `p95_20_300_recalc`.

- `10_mc_best.json` *(si généré dans le dépôt)*  
  → meilleur point (ou ensemble restreint) avec :
  - `best.m1…m8` ;
  - `best.p95_recalc` ;
  - `meta.criteria` (critère exact utilisé).

Autres fichiers utiles mais non strictement nécessaires au pipeline minimal :

- `10_mc_results.agg.csv` (agrégats « linéaires » historiques) ;
- `10_mc_milestones_eval.csv` (sélection de points pour validations ciblées).

---

### 3.3. Figures CH10

Répertoire :

- `assets/zz-figures/chapter10/`

Figures **principales** générées par le pipeline minimal :

- `fig_01_iso_p95_maps.png`  
  → cartes iso / heatmaps de `p95_20_300_recalc` dans un plan (m1, m2)
  avec nuage d’échantillons.
- `fig_04_scatter_p95_recalc_vs_orig.png`  
  → nuage de points `p95_20_300` (historique) vs `p95_20_300_recalc` (circulaire).  
- `fig_05_hist_cdf_metrics.png`  
  → histogrammes + CDF des métriques globales basées sur `p95_20_300_recalc`.

Figures **complémentaires** (hors pipeline minimal strict mais cohérentes) :

- `fig_02_scatter_phi_at_fpeak.png`  
- `fig_03_convergence_p95_vs_n.png`  
- `fig_03b_coverage_bootstrap_vs_n_hires.png`  
- `fig_06_heatmap_absdp95_m1m2.png`  
- `fig_07_summary_comparison.png`.

---

## 4. Pipeline détaillé – étape par étape

### 4.1. Génération des résultats Monte‑Carlo 8D (linéaires)

Depuis la racine du dépôt :

```bash
python scripts/10_global_scan/generate_data_chapter10.py \
  --config  assets/zz-data/chapter10/10_mc_config.json \
  --samples assets/zz-data/chapter10/10_mc_samples.csv \
  --out     assets/zz-data/chapter10/10_mc_results.csv
```

Ce script :

1. lit `10_mc_config.json` pour récupérer :
   - la fenêtre fréquentielle `[f_min, f_max]` (typiquement `[20, 300]` Hz) ;
   - les paramètres bootstrap (non encore utilisés à cette étape) ;
   - la description de la grille 8D (`grid.m1…grid.m8`) ;
2. lit `10_mc_samples.csv` (colonnes `m1…m8`, éventuellement `seed`) ;
3. exécute les calculs Monte‑Carlo pour chaque point de l’espace 8D ;
4. écrit les métriques **linéaires historiques** (dont `p95_20_300`) dans :  
   - `assets/zz-data/chapter10/10_mc_results.csv`.

À ce stade, **`p95_20_300` n’est pas encore la métrique canonique** : elle le devient
après recalcul circulaire en §4.2.

---

### 4.2. Recalcul circulaire de p95 (colonne de référence)

```bash
python scripts/10_global_scan/recompute_p95_circular.py \
  --in  assets/zz-data/chapter10/10_mc_results.csv \
  --out assets/zz-data/chapter10/10_mc_results.circ.csv
```

Ce script :

1. lit `10_mc_results.csv` ;
2. interprète les résidus de phase comme **angles** (réduction modulo `2π`) ;
3. calcule une métrique p95 **circulaire**, définie de façon cohérente avec le
   chapitre 09 (moyenne directionnelle, quantile sur les résidus circulaires) ;
4. écrit une nouvelle colonne :

   - `p95_20_300_recalc`

   dans `assets/zz-data/chapter10/10_mc_results.circ.csv`.

À partir de cette étape, **toutes les figures et analyses CH10 doivent utiliser
`p95_20_300_recalc`** comme métrique de référence.

Vérification rapide (optionnelle) :

```bash
python - << 'PY'
import pandas as pd
df = pd.read_csv("assets/zz-data/chapter10/10_mc_results.circ.csv")
print("Colonnes p95 présentes:", [c for c in df.columns if "p95" in c])
PY
```

---

### 4.3. Ajout des jalons `f_peak` (optionnel mais recommandé)

Si la config active `outputs.with_fpeak` ou si tu veux exploiter les diagnostics
en fonction d’une fréquence jalon :

```bash
python scripts/10_global_scan/add_phi_at_fpeak.py \
  --in  assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out assets/zz-data/chapter10/10_mc_results.circ.with_fpeak.csv
```

Ce script ajoute, typiquement :

- `f_peak_Hz` ;
- `phi_ref_at_fpeak` ;
- `phi_mcgt_at_fpeak`.

Ce fichier est utilisé notamment par `10_fig02_scatter_phi_at_fpeak.py`
(hors pipeline minimal strict).

---

### 4.4. Agrégats principaux sur `[20, 300]` Hz

```bash
python scripts/10_global_scan/eval_primary_metrics_20_300.py \
  --in  assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out assets/zz-data/chapter10/10_mc_results.circ.agg.csv
```

Ce script :

1. lit `10_mc_results.circ.csv` ;
2. évalue les métriques primaires (moyenne/médiane, etc.) sur la fenêtre
   fréquentielle `[20, 300]` Hz en utilisant `p95_20_300_recalc` ;
3. agrège les résultats (globalement ou par cellule, selon la configuration) ;
4. écrit les agrégats dans :

   - `assets/zz-data/chapter10/10_mc_results.circ.agg.csv`.

Ce fichier sert de base pour les synthèses globales et les tableaux de résultats.

---

### 4.5. Bootstrap top‑k et fichiers « best »

```bash
python scripts/10_global_scan/bootstrap_topk_p95.py \
  --in  assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out assets/zz-data/chapter10/10_mc_best_bootstrap.json \
  --k 20 --outer 400 --inner 2000 --alpha 0.05 --seed 12345
```

Ce script :

1. identifie les **top‑k** points (par ex. `k = 20`) dans l’espace 8D selon la
   métrique `p95_20_300_recalc` ;
2. effectue un **bootstrap imbriqué** (paramètres `outer`, `inner`, `alpha`) pour
   estimer la distribution de `p95_20_300_recalc` sur ces meilleurs points ;
3. écrit un résumé dans :

   - `assets/zz-data/chapter10/10_mc_best_bootstrap.json`

   (et, selon l’implémentation actuelle, un fichier `10_mc_best.json` décrivant
   un « meilleur point » ou un sous‑ensemble restreint).

Ce bloc fournit les nombres résumés utilisés dans les textes et tableaux de CH10.

---

### 4.6. Figures principales (Fig. 01, 04, 05)

Une fois `10_mc_results.circ.csv` disponible, tu peux régénérer les figures
principales du chapitre 10.

#### 4.6.1. Cartes iso `p95_20_300_recalc` (Fig. 01)

```bash
python scripts/10_global_scan/10_fig_01_iso_p95_maps.py \
  --results assets/zz-data/chapter10/10_mc_results.circ.csv \
  --p95-col p95_20_300_recalc \
  --m1-col m1 --m2-col m2 \
  --out assets/zz-figures/chapter10/10_fig_01_iso_p95_maps.png \
  --levels 16 --dpi 300
```

Cette figure montre la structure de `p95_20_300_recalc` dans un sous‑espace
(m1, m2), avec éventuellement un nuage d’échantillons par cellule.

#### 4.6.2. Comparaison linéaire vs circulaire (Fig. 04)

```bash
python scripts/10_global_scan/10_fig_04_p95_comparison.py \
  --results assets/zz-data/chapter10/10_mc_results.circ.csv \
  --orig-col p95_20_300 --recalc-col p95_20_300_recalc \
  --out assets/zz-figures/chapter10/10_fig_04_p95_comparison.png \
  --dpi 300 --bins 50
```

Cette figure compare la métrique historique linéaire à la métrique circulaire,
et illustre les écarts potentiels (biais de linéarisation).

#### 4.6.3. Histogrammes / CDF des métriques (Fig. 05)

```bash
python scripts/10_global_scan/10_fig_05_hist_cdf_metrics.py \
  --results assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out assets/zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png \
  --ref-p95 0.7104087123286049 --bins 50 --dpi 150
```

Cette figure présente la distribution globale des métriques (histogrammes +
CDF), avec une valeur de référence `ref-p95` utilisée pour l’annotation.

---

## 5. Produits finaux « officiels » pour le chapitre 10

Dans le cadre du pipeline minimal canonique, les **produits principaux** de CH10 sont :

### 5.1. Données

- `assets/zz-data/chapter10/10_mc_config.json`  
  → configuration complète de l’expérience Monte‑Carlo 8D.

- `assets/zz-data/chapter10/10_mc_samples.csv`  
  → échantillons / grille dans l’espace 8D (`m1…m8`).

- `assets/zz-data/chapter10/10_mc_results.circ.csv`  
  → jeu de données central avec la métrique de référence
  `p95_20_300_recalc` sur `[20, 300]` Hz.

- `assets/zz-data/chapter10/10_mc_results.circ.agg.csv`  
  → agrégats principaux des métriques basés sur `p95_20_300_recalc`.

- `assets/zz-data/chapter10/10_mc_results.circ.with_fpeak.csv` *(si utilisé)*  
  → diagnostics supplémentaires en fonction de `f_peak_Hz`.

- `assets/zz-data/chapter10/10_mc_best_bootstrap.json`  
  → résumé bootstrap top‑k sur `p95_20_300_recalc`.

- `assets/zz-data/chapter10/10_mc_best.json` *(si présent dans le dépôt)*  
  → meilleur point (coordonnées `m1…m8`, métrique associée, métadonnées).

- `assets/zz-data/chapter10/10_mc_milestones_eval.csv` *(optionnel)*  
  → sous‑ensemble de points choisis pour des validations ciblées ou des figures.

### 5.2. Figures

Produits graphiques principaux :

- `assets/zz-figures/chapter10/10_fig_01_iso_p95_maps.png`
- `assets/zz-figures/chapter10/10_fig_04_p95_comparison.png`
- `assets/zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png`

Figures complémentaires, générables à partir des mêmes données :

- `assets/zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png`
- `assets/zz-figures/chapter10/10_fig_03_convergence.png`
- `assets/zz-figures/chapter10/10_fig_03_convergence.png`
- `assets/zz-figures/chapter10/10_fig_06_residual_map.png`
- `assets/zz-figures/chapter10/10_fig_07_synthesis.png`.

---

## 6. Contrôle d’intégrité et manifests

Une fois le pipeline minimal exécuté (données + figures), il est recommandé de
lancer le diagnostic des manifests (comme pour les autres chapitres) :

```bash
bash tools/run_diag_manifests.sh
```

Ce script vérifie notamment :

- la présence et la cohérence des fichiers CH10 dans :
  - `assets/zz-data/chapter10/`
  - `assets/zz-figures/chapter10/`  
- la concordance avec :
  - `assets/zz-manifests/manifest_master.json`
  - `assets/zz-manifests/manifest_publication.json`

Objectifs :

- aucune erreur bloquante de type `SHA_MISMATCH` ou fichier manquant sur les
  produits listés en §5.1–5.2 ;
- des warnings de type `GIT_HASH_DIFFERS` ou `MTIME_DIFFERS` peuvent subsister
  pendant les phases d’édition active, mais doivent être minimisés au moment de
  la publication.

---

## 7. Notes LaTeX / reproductibilité

Les sources LaTeX du chapitre 10 se trouvent dans :

- `10-monte-carlo-global-8d/10_monte_carlo_global_conceptuel.tex`
- `10-monte-carlo-global-8d/10_monte_carlo_global_details.tex`

Compilation (exemple) :

```bash
cd 10-monte-carlo-global-8d
pdflatex -interaction=nonstopmode 10_monte_carlo_global_conceptuel.tex
pdflatex -interaction=nonstopmode 10_monte_carlo_global_details.tex
```

Pour la **reproductibilité** de CH10, il est recommandé que toute modification
affectant les résultats ou figures :

- soit effectuée dans une branche Git dédiée ;
- soit accompagnée d’une exécution propre du pipeline minimal (section 2) ;
- passe `bash tools/run_diag_manifests.sh` sans erreur bloquante ;
- mette à jour `CHANGELOG.md` et, si nécessaire, les entrées CH10 dans les
  manifests (`manifest_master.json`, `manifest_publication.json`).

---

Fin du document.
