# MCGT: Model of Gravitational Time Curvature

[![Zenodo](https://zenodo.org/badge/DOI/10.5281/zenodo.18002118.svg)](https://doi.org/10.5281/zenodo.18002118)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

Official repository for the MCGT research project, focused on Gravitational Wave Phase Analysis and Cosmological Invariants.

## ⚙️ Central Configuration
This project is now fully driven by a single central configuration file:
`config/mcgt-global-config.ini`. All chapter scripts read their cosmological
parameters from this source of truth, and the `check_coherence.py` sentinel verifies
that no script diverges from the declared best-fit values.

## 🚀 Key Features
- **Sobol 8D Sampling**: Production-grade parameter space exploration.
- **Reproducible Pipeline**: All chapters certified with SHA256 consistency checks.
- **Physics Modules**: From CMB spectra to GW phase residuals.

## 🛠 Installation
```bash
git clone https://github.com/JeanPhilipLalumiere/MCGT.git
pip install -r requirements.txt
```

## 📊 Verification
```bash
python check_coherence.py
python assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_master.json
```

## Citation
Lalumière, J.-P. (2025). MCGT : Modèle de la Courbure Gravitationnelle du Temps (Version 2.5.0). Zenodo. https://doi.org/10.5281/zenodo.18002118

---

## Français

> Corpus scientifique structuré (10 chapitres LaTeX) + **scripts**, **données**, **figures** et **manifestes** assurant la **reproductibilité** de bout en bout.

- **Langue du dépôt** : Français  
- **Python** : 3.9 → 3.13 (CI principale sur 3.12)  
- **Licence** : MIT (cf. `LICENSE`)  
- **Sous-projet Python** : `tools` (utilitaires MCGT)

---

### Sommaire

1. Objectifs & périmètre  
2. Arborescence minimale  
3. Installation (venv ou conda)  
4. Variables transverses  
5. Reproduire les résultats (quickstart)  
6. Données, figures & manifestes  
7. Qualité & CI  
8. Tests  
9. Publication & empaquetage  
10. Licence, remerciements, citation

---

### 1) Objectifs & périmètre

MCGT regroupe :
- **Chapitres LaTeX** (conceptuel + détails) : bases théoriques et résultats.
- **Scripts** (`scripts/`) : génération de données et tracés.
- **Données** (`assets/zz-data/`) et **figures** (`assets/zz-figures/`) nommées canoniquement.
- **Manifeste** (`assets/zz-manifests/`) : inventaire des artefacts + rapports de cohérence.
- **Schémas** (`assets/zz-schemas/`) : validation JSON/CSV.
- **Utilitaires Python** (`tools/`) : IO, conventions, métriques simples.

**Ce README** donne un chemin rapide vers l’installation, la reproduction, la validation et la publication. Le détail exhaustif des pipelines est dans **`docs/reproducibility/README-REPRO.md`**.

---

### 2) Arborescence minimale

```
MCGT/
├─ manuscript/main.tex
├─ README.md
├─ docs/reproducibility/README-REPRO.md
├─ RUNBOOK.md
├─ conventions.md
├─ LICENSE
├─ config/
│  └─ mcgt-global-config.ini (et .template)
├─ scripts/
│  └─ chapter{01..10}/...
├─ assets/zz-data/
│  └─ chapter{01..10}/...
├─ assets/zz-figures/
│  └─ chapter{01..10}/...
├─ assets/zz-manifests/
│  ├─ manifest_master.json
│  ├─ manifest_publication.json
│  ├─ manifest_report.md
│  └─ diag_consistency.py
├─ assets/zz-schemas/
│  └─ *.schema.json, validate_*.py, consistency_rules.json
└─ tools/
   ├─ pyproject.toml  (version ≥ 0.2.99)
   └─ tools/
      ├─ __init__.py
      └─ common_io.py
```

---

### 3) Installation

#### Option A — venv + pip

```
python3 -m venv .venv
. .venv/bin/activate
pip install -U pip
pip install -r requirements.txt
```

#### Option B — conda/mamba

```
mamba env create -f environment.yml   # ou: conda env create -f environment.yml
conda activate mcgt
```

#### Utilitaires `tools` (facultatif si non inclus dans `requirements.txt`)

```
pip install tools
```

---

### 4) Variables transverses

```
export MCGT_CONFIG=config/mcgt-global-config.ini
## optionnel (recommandé)
export MCGT_RULES=assets/zz-schemas/consistency_rules.json
```

Conventions d’unités (rappel) : fréquence `f_Hz` (Hz), angles en radians (`_rad`), multipôles `ell`, distances `dist` (Mpc). Voir **`conventions.md`**.

---

### 5) Reproduire les résultats (quickstart)

Le guide complet est dans **`docs/reproducibility/README-REPRO.md`**. Ci-dessous, deux pipelines courants.

#### 5.1 Chapitre 09 — Phase d’ondes gravitationnelles

```
## (0) Générer la référence si besoin
python scripts/chapter09/extract_phenom_phase.py \
  --out assets/zz-data/chapter09/09_phases_imrphenom.csv

## (1) Prétraitement + résidus
python scripts/chapter09/generate_data_chapter09.py \
  --ref assets/zz-data/chapter09/09_phases_imrphenom.csv \
  --out-prepoly assets/zz-data/chapter09/09_phases_mcgt_prepoly.csv \
  --out-diff    assets/zz-data/chapter09/09_phase_diff.csv \
  --log-level INFO

## (2) Optimisation base/degré + rebranch k
python scripts/chapter09/opt_poly_rebranch.py \
  --csv assets/zz-data/chapter09/09_phases_mcgt_prepoly.csv \
  --meta assets/zz-data/chapter09/09_metrics_phase.json \
  --fit-window 30 250 --metrics-window 20 300 \
  --degrees 3 4 5 --bases log10 hz --k-range -10 10 \
  --out-csv  assets/zz-data/chapter09/09_phases_mcgt.csv \
  --out-best assets/zz-data/chapter09/09_best_params.json \
  --backup --log-level INFO

## (3) Figures
python scripts/chapter09/10_fig01_phase_overlay.py \
  --csv  assets/zz-data/chapter09/09_phases_mcgt.csv \
  --meta assets/zz-data/chapter09/09_metrics_phase.json \
  --out  assets/zz-figures/chapter09/09_fig_01_phase_overlay.png \
  --shade 20 300 --show-residual --dpi 300
python scripts/chapter09/10_fig02_residual_phase.py \
  --csv  assets/zz-data/chapter09/09_phases_mcgt.csv \
  --meta assets/zz-data/chapter09/09_metrics_phase.json \
  --out  assets/zz-figures/chapter09/09_fig_02_residual_phase.png \
  --bands 20 300 300 1000 1000 2000 --dpi 300
python scripts/chapter09/10_fig03_hist_absdphi_20_300.py \
  --csv  assets/zz-data/chapter09/09_phases_mcgt.csv \
  --meta assets/zz-data/chapter09/09_metrics_phase.json \
  --out  assets/zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png \
  --mode principal --bins 50 --window 20 300 --xscale log --dpi 300
```

#### 5.2 Chapitre 10 — Monte Carlo global 8D

```
## (1) Config
cat assets/zz-data/chapter10/10_mc_config.json

## (2) Échantillonnage et évaluation
python scripts/chapter10/generate_data_chapter10.py \
  --config assets/zz-data/chapter10/10_mc_config.json \
  --out-results assets/zz-data/chapter10/10_mc_results.csv \
  --out-results-circ assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out-samples assets/zz-data/chapter10/10_mc_samples.csv \
  --log-level INFO

## (3) Diagnostics
python scripts/chapter10/add_phi_at_fpeak.py \
  --results assets/zz-data/chapter10/10_mc_results.circ.csv \
  --out     assets/zz-data/chapter10/10_mc_results.circ.with_fpeak.csv
python scripts/chapter10/inspect_topk_residuals.py \
  --results assets/zz-data/chapter10/10_mc_results.csv \
  --jalons  assets/zz-data/chapter10/10_mc_milestones_eval.csv \
  --out-dir assets/zz-data/chapter10/topk_residuals
python scripts/chapter10/bootstrap_topk_p95.py \
  --results assets/zz-data/chapter10/10_mc_results.csv \
  --topk-json assets/zz-data/chapter10/10_mc_best.json \
  --out-json  assets/zz-data/chapter10/10_mc_best_bootstrap.json \
  --B 1000 --seed 12345

## (4) Figures
python scripts/chapter10/10_fig_01_iso_p95_maps.py        --out assets/zz-figures/chapter10/10_fig_01_iso_p95_maps.png
python scripts/chapter10/10_fig_02_scatter_phi_at_fpeak.py --out assets/zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png
python scripts/chapter10/10_fig_03_convergence.py --out assets/zz-figures/chapter10/10_fig_03_convergence.png
python scripts/chapter10/10_fig_03_convergence.py --out assets/zz-figures/chapter10/10_fig_03_convergence.png
python scripts/chapter10/10_fig_04_p95_comparison.py --out assets/zz-figures/chapter10/10_fig_04_p95_comparison.png
python scripts/chapter10/10_fig_05_hist_cdf_metrics.py     --out assets/zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png
python scripts/chapter10/10_fig_06_residual_map.py         --out assets/zz-figures/chapter10/10_fig_06_heatmap_absdp95_m1m2.png
python scripts/chapter10/10_fig_07_synthesis.py            --out assets/zz-figures/chapter10/10_fig_07_summary_comparison.png
```

---

### 6) Données, figures & manifestes

- **Données** : `assets/zz-data/chapterXX/` — CSV/DAT/JSON ; colonnes et unités documentées dans `conventions.md`.  
- **Figures** : `assets/zz-figures/chapterXX/` — PNG (300 dpi mini), noms `fig_XX_*`.  
- **Manifestes** : inventaire, rapports et corrections :
  - `assets/zz-manifests/manifest_master.json` (source maître)
  - `assets/zz-manifests/manifest_publication.json` (sous-ensemble public)
  - `assets/zz-manifests/diag_consistency.py` (audit; options `--report md`, `--fix`)

---

### 7) Qualité & CI

Workflows principaux (GitHub Actions) :
- `sanity-main.yml` : diagnostics quotidiens et sur push
- `ci-pre-commit.yml` : format/linters
- `ci-yaml-check.yml` : validation YAML
- `release-publish.yml` : build + publication (artefacts/wheel)

Référence : `docs/CI.md`.

---

### 8) Tests

```
pytest -q
```

Tests rapides disponibles pour `tools` (imports, CLI, API publique, IO et figures de base).

---

### 9) Publication & empaquetage

#### Paquet `tools`

```
sed -i 's/^version\s*=\s*".*"/version = "0.2.99"/' pyproject.toml
python -m build
twine check dist/*
```

Contrôle du contenu des artefacts :
```
WHEEL=$(ls -1 dist/*.whl | tail -n1)
python - <<PY
import sys, zipfile
w=sys.argv[1]
with zipfile.ZipFile(w) as z:
    meta=[n for n in z.namelist() if n.endswith("METADATA")][0]
    t=z.read(meta).decode("utf-8","ignore")
    print("\n".join([l for l in t.splitlines() if l.startswith(("Metadata-Version","Name","Version","Requires-Python","Requires-Dist"))]))
PY "$WHEEL"

unzip -Z1 "$WHEEL" | grep -E '\.bak$|\.env$|\.pem$|\.key$|(^|/)assets/zz-figures/|(^|/)assets/zz-data/' || echo "OK wheel clean"
SDIST=$(ls -1 dist/*.tar.gz | tail -n1)
tar -tzf "$SDIST" | grep -E '\.venv|\.env$|\.pem$|\.key$|(^|/)zz-out/|(^|/)\.ci-|(^|/)\.ruff_cache' || echo "OK sdist clean"
```

Tag & push :
```
git add -A
git commit -m "release: tools 0.2.99"
git tag v0.2.99
git push origin HEAD --tags
```

---

### 10) Licence, remerciements, citation

- **Licence** : MIT (cf. `LICENSE`).
- **Contact scientifique** : responsable MCGT.  
- **Contact technique** : mainteneur CI/scripts.

Pour citer : *MCGT — Modèle de Courbure Gravitationnelle Temporelle, v0.2.99, 2025.*


---
<!-- ZENODO_BADGE_START -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.15186836.svg)](https://doi.org/10.5281/zenodo.15186836)

#### Citation
Si vous utilisez MCGT, merci de citer la version DOI : **10.5281/zenodo.15186836**.
Voir aussi `CITATION.cff`.
<!-- ZENODO_BADGE_END -->





---

▶ Guide de reproduction rapide : [docs/reproducibility/README-REPRO.md](docs/reproducibility/README-REPRO.md)

## ci-nudge

## ci-nudge-2

## ci-nudge-3

## ci-nudge-pypi

## ci-nudge-pypi

## ci-nudge-pypi
<!-- ci:touch docs-light -->
<!-- ci:touch docs-light run -->

### Installation

```bash
pip install tools
```

### Reproductibilité

Voir `assets/zz-manifests/manifest_publication.json` et le script `assets/zz-manifests/diag_consistency.py` (0 erreur attendu).

### Licence

Code: MIT. Données/figures: voir en-têtes ou LICENSE-data le cas échéant.

### Utilisation rapide

```bash\npython -m tools --help\n```\n

### Citation

Citez : Lalumière, J.-P. (MCGT). DOI/Zenodo (à compléter).

### Overview
Instantané minimal de publication (manifeste propre, figures référencées).

### Usage
Scripts et manifestes dans `zz-*`. Voir `assets/zz-manifests/diag_consistency.py --help`.

### License
Code MIT, données/figures CC BY 4.0 (voir LICENSE, LICENSE-data).

### Reproducibility
Rebuild best-effort; voir workflows CI et `README-REPRO` si présent.

#### Installation (depuis TestPyPI)
```bash
pip install --index-url https://test.pypi.org/simple \
            --extra-index-url https://pypi.org/simple \
            tools==0.3.1
```

#### Installation (version stable, PyPI)
```bash
pip install -U tools
## ou version spécifique
## pip install tools==0.3.1.post1
```
