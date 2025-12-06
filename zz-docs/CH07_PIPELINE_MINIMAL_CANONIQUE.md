# Chapitre 07 – Pipeline minimal canonique (scalar_perturbations.ini)

## Objectif

Fournir un pipeline **minimal mais complet** pour le Chapitre 07 (perturbations scalaires),
en utilisant le profil canonique `zz-configuration/scalar_perturbations.ini`, et en
documentant clairement :

- Les commandes à lancer.
- Les fichiers produits considérés comme **référence**.
- Les comportements attendus (y compris les gardes-fous comme c_s² hors-borne).

Le pipeline est encapsulé dans le script :

```bash
bash tools/ch07_minimal_pipeline.sh
```

## 1. Prérequis

- Environnement Python : `mcgt-dev` activé.
- Dépôt MCGT à jour sur `main` (HEAD validé par `tools/mcgt_step01_guard_diag_smoke.sh`).
- Fichiers de configuration présents :
  - `zz-configuration/scalar_perturbations.ini`
  - `zz-configuration/perturbations_07.ini` (profils alternatifs éventuels)

## 2. Smoke minimal (dry-run)

Vérification rapide que les scripts de génération/solveur s’initialisent correctement :

```bash
python zz-scripts/chapter07/generate_data_chapter07.py \
  -i zz-configuration/scalar_perturbations.ini \
  --export-raw zz-out/smoke/chapter07/generate_data_chapter07_manual.csv \
  --dry-run

python zz-scripts/chapter07/launch_scalar_perturbations_solver.py \
  -i zz-configuration/scalar_perturbations.ini \
  --export-raw zz-out/smoke/chapter07/launch_scalar_perturbations_solver_manual.csv \
  --dry-run
```

Résultat attendu :

- Messages `[INFO] Grilles : ...` suivis de `Dry-run uniquement : pas de calcul.`

## 3. Pipeline minimal (run complet)

Le pipeline minimal canonique est structuré en deux étapes :

### 3.1 generate_data_chapter07.py (run complet minimal)

```bash
python zz-scripts/chapter07/generate_data_chapter07.py \
  -i zz-configuration/scalar_perturbations.ini \
  --export-raw zz-data/chapter07/07_scan_raw_minimal.csv \
  --export-2d \
  --n-k 32 \
  --n-a 20 \
  --log-level INFO \
  --log-file zz-out/chapter07/generate_data_chapter07_minimal.log
```

**Important :**

- Avec l’INI canonique actuelle, cette étape peut lever :

  > `ValueError: c_s² hors-borne ou non-fini (attendu dans [0,1]).`

- Ce **garde-fou est volontairement conservé** : il signale un problème de stabilité/physique,
  pas un bug de code. Le pipeline minimal accepte ce comportement comme “expected failure”
  lorsqu’on utilise exactement le profil canonique actuel.

### 3.2 launch_scalar_perturbations_solver.py (run complet minimal)

```bash
python zz-scripts/chapter07/launch_scalar_perturbations_solver.py \
  -i zz-configuration/scalar_perturbations.ini \
  --export-raw zz-data/chapter07/07_phase_run.csv \
  --log-level INFO \
  --log-file zz-out/chapter07/launch_scalar_perturbations_solver_minimal.log
```

Résultat attendu :

- Fichiers de référence produits :

  - `zz-data/chapter07/07_phase_run.csv`
  - `zz-data/chapter07/07_meta_perturbations.json`

- Log canonique :

  - `zz-out/chapter07/launch_scalar_perturbations_solver_minimal.log`

Ces fichiers sont déclarés dans les manifests (`manifest_master.json` & `manifest_publication.json`)
avec leurs `size_bytes` et `sha256` actuels.

## 4. Figures principales (Fig. 01 à 07)

À partir des CSV de référence (matrices c_s², delta_phi, invariants, etc.), on génère les
figures publiables du chapitre :

```bash
# Heatmaps c_s² et delta_phi
python zz-scripts/chapter07/plot_fig01_cs2_heatmap.py
python zz-scripts/chapter07/plot_fig02_delta_phi_heatmap.py

# Invariants et dérivées
python zz-scripts/chapter07/plot_fig03_invariant_i1.py
python zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py
python zz-scripts/chapter07/plot_fig05_ddelta_phi_vs_k.py

# Comparaisons et invariant I2
python zz-scripts/chapter07/plot_fig06_comparison.py
python zz-scripts/chapter07/plot_fig07_invariant_i2.py
```

Points clés :

- `plot_fig03_invariant_i1.py` lit `zz-data/chapter07/07_scalar_invariants.csv`.
- `plot_fig04_dcs2_vs_k.py` lit `zz-data/chapter07/07_dcs2_vs_k.csv`.
- `plot_fig07_invariant_i2.py` gère robustement l’absence de certaines colonnes, avec repli
  possible sur `I1_cs2`.

Les PNG générés sont typiquement sous `zz-out/chapter07/` et/ou `zz-out/smoke/chapter07/`.

## 5. Utilitaires et tests locaux

Pour compléter le smoke local :

```bash
# Test de la grille en k
python zz-scripts/chapter07/utils/test_kgrid.py

# Toy model (figure de diagnostic rapide)
python zz-scripts/chapter07/utils/toy_model.py \
  --out zz-out/smoke/chapter07/utils/toy_model_manual.png \
  --dpi 96
```

Ces scripts servent à vérifier rapidement :

- la cohérence de la grille de k,
- le bon fonctionnement de la stack plotting/NumPy/Matplotlib.

## 6. Fichiers considérés comme “référence” pour CH07

Pour le Chapitre 07, les fichiers suivants sont considérés comme
**artefacts canoniques** :

- **Configuration**
  - `zz-configuration/scalar_perturbations.ini`
  - `zz-configuration/perturbations_07.ini` (profils alternatifs éventuels)

- **Données**
  - `zz-data/chapter07/07_phase_run.csv`
  - `zz-data/chapter07/07_meta_perturbations.json`
  - `zz-data/chapter07/07_scalar_invariants.csv`
  - `zz-data/chapter07/07_dcs2_vs_k.csv`
  - (autres CSV nécessaires aux figures finales, listés dans les scripts `plot_figXX`)

- **Figures**
  - Toutes les figures `zz-figures/chapter07/07_fig_0X_*.png` associées à ce pipeline.

Les sorties plus verbeuses (logs détaillés, anciennes runs `passXX_run`, etc.)
peuvent être considérées comme **candidates** pour un déplacement dans `attic/`
ou pour suppression, une fois qu’un inventaire global aura été validé.
