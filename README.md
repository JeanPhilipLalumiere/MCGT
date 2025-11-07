<!-- BEGIN BADGES -->
[![Docs](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/docs.yml/badge.svg)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/docs.yml)
[![CI](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci.yml/badge.svg)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci.yml)
[![Pre-commit](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-pre-commit.yml/badge.svg)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-pre-commit.yml)
[![Release](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/release-publish.yml/badge.svg)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/release-publish.yml)
<!-- END BADGES -->
<!-- ci:touch 20251102T020901Z -->
# MCGT : Modèle de la Courbure Gravitationnelle du Temps


> Corpus scientifique structuré (10 chapitres LaTeX) + **scripts**, **données**, **figures** et **manifestes** assurant la **reproductibilité** de bout en bout.

- **Langue du dépôt** : Français  
- **Python** : 3.9 → 3.13 (CI principale sur 3.12)  
- **Licence** : MIT (cf. `LICENSE`)  
- **Sous-projet Python** : `zz-tools` (utilitaires MCGT)

---

## Sommaire

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

## 1) Objectifs & périmètre

MCGT regroupe :
- **Chapitres LaTeX** (conceptuel + détails) : bases théoriques et résultats.
- **Scripts** (`zz-scripts/`) : génération de données et tracés.
- **Données** (`zz-data/`) et **figures** (`zz-figures/`) nommées canoniquement.
- **Manifeste** (`zz-manifests/`) : inventaire des artefacts + rapports de cohérence.
- **Schémas** (`zz-schemas/`) : validation JSON/CSV.
- **Utilitaires Python** (`zz-tools/`) : IO, conventions, métriques simples.

**Ce README** donne un chemin rapide vers l’installation, la reproduction, la validation et la publication. Le détail exhaustif des pipelines est dans **`README-REPRO.md`**.

---

## 2) Arborescence minimale

```
MCGT/
├─ main.tex
├─ README.md
├─ README-REPRO.md
├─ RUNBOOK.md
├─ conventions.md
├─ LICENSE
├─ zz-configuration/
│  └─ mcgt-global-config.ini (et .template)
├─ zz-scripts/
│  └─ chapter{01..10}/...
├─ zz-data/
│  └─ chapter{01..10}/...
├─ zz-figures/
│  └─ chapter{01..10}/...
├─ zz-manifests/
│  ├─ manifest_master.json
│  ├─ manifest_publication.json
│  ├─ manifest_report.md
│  └─ diag_consistency.py
├─ zz-schemas/
│  └─ *.schema.json, validate_*.py, consistency_rules.json
└─ zz-tools/
   ├─ pyproject.toml  (version ≥ 0.2.99)
   └─ zz_tools/
      ├─ __init__.py
      └─ common_io.py
```

---

## 3) Installation

### Option A — venv + pip

```
python3 -m venv .venv
. .venv/bin/activate
PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U pip
PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements.txt
```

### Option B — conda/mamba

```
mamba env create -f environment.yml   # ou: conda env create -f environment.yml
conda activate mcgt
```

### Utilitaires `zz-tools` (facultatif si non inclus dans `requirements.txt`)

```
PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install zz-tools
```

---

## 4) Variables transverses

```
export MCGT_CONFIG=zz-configuration/mcgt-global-config.ini
# optionnel (recommandé)
export MCGT_RULES=zz-schemas/consistency_rules.json
```

Conventions d’unités (rappel) : fréquence `f_Hz` (Hz), angles en radians (`_rad`), multipôles `ell`, distances `dist` (Mpc). Voir **`conventions.md`**.

---

## 5) Reproduire les résultats (quickstart)

Le guide complet est dans **`README-REPRO.md`**. Ci-dessous, deux pipelines courants.

### 5.1 Chapitre 09 — Phase d’ondes gravitationnelles

```
# (0) Générer la référence si besoin
python zz-scripts/chapter09/extract_phenom_phase.py \
  --out zz-data/chapter09/09_phases_imrphenom.csv

# (1) Prétraitement + résidus
python zz-scripts/chapter09/generate_data_chapter09.py \
  --ref zz-data/chapter09/09_phases_imrphenom.csv \
  --out-prepoly zz-data/chapter09/09_phases_mcgt_prepoly.csv \
  --out-diff    zz-data/chapter09/09_phase_diff.csv \
  --log-level INFO

# (2) Optimisation base/degré + rebranch k
python zz-scripts/chapter09/opt_poly_rebranch.py \
  --csv zz-data/chapter09/09_phases_mcgt_prepoly.csv \
  --meta zz-data/chapter09/09_metrics_phase.json \
  --fit-window 30 250 --metrics-window 20 300 \
  --degrees 3 4 5 --bases log10 hz --k-range -10 10 \
  --out-csv  zz-data/chapter09/09_phases_mcgt.csv \
  --out-best zz-data/chapter09/09_best_params.json \
  --backup --log-level INFO

# (3) Figures
python zz-scripts/chapter09/plot_fig01_phase_overlay.py \
  --csv  zz-data/chapter09/09_phases_mcgt.csv \
  --meta zz-data/chapter09/09_metrics_phase.json \
  --out  zz-figures/chapter09/fig_01_phase_overlay.png \
  --shade 20 300 --show-residual --dpi 300
python zz-scripts/chapter09/plot_fig02_residual_phase.py \
  --csv  zz-data/chapter09/09_phases_mcgt.csv \
  --meta zz-data/chapter09/09_metrics_phase.json \
  --out  zz-figures/chapter09/fig_02_residual_phase.png \
  --bands 20 300 300 1000 1000 2000 --dpi 300
python zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py \
  --csv  zz-data/chapter09/09_phases_mcgt.csv \
  --meta zz-data/chapter09/09_metrics_phase.json \
  --out  zz-figures/chapter09/fig_03_hist_absdphi_20_300.png \
  --mode principal --bins 50 --window 20 300 --xscale log --dpi 300
```

### 5.2 Chapitre 10 — Monte Carlo global 8D

```
# (1) Config
cat zz-data/chapter10/10_mc_config.json

# (2) Échantillonnage et évaluation
python zz-scripts/chapter10/generate_data_chapter10.py \
  --config zz-data/chapter10/10_mc_config.json \
  --out-results zz-data/chapter10/10_mc_results.csv \
  --out-results-circ zz-data/chapter10/10_mc_results.circ.csv \
  --out-samples zz-data/chapter10/10_mc_samples.csv \
  --log-level INFO

# (3) Diagnostics
python zz-scripts/chapter10/add_phi_at_fpeak.py \
  --results zz-data/chapter10/10_mc_results.circ.csv \
  --out     zz-data/chapter10/10_mc_results.circ.with_fpeak.csv
python zz-scripts/chapter10/inspect_topk_residuals.py \
  --results zz-data/chapter10/10_mc_results.csv \
  --jalons  zz-data/chapter10/10_mc_milestones_eval.csv \
  --out-dir zz-data/chapter10/topk_residuals
python zz-scripts/chapter10/bootstrap_topk_p95.py \
  --results zz-data/chapter10/10_mc_results.csv \
  --topk-json zz-data/chapter10/10_mc_best.json \
  --out-json  zz-data/chapter10/10_mc_best_bootstrap.json \
  --B 1000 --seed 12345

# (4) Figures
python zz-scripts/chapter10/plot_fig01_iso_p95_maps.py        --out zz-figures/chapter10/fig_01_iso_p95_maps.png
python zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py --out zz-figures/chapter10/fig_02_scatter_phi_at_fpeak.png
python zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py --out zz-figures/chapter10/fig_03_convergence_p95_vs_n.png
python zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py --out zz-figures/chapter10/fig_03b_coverage_bootstrap_vs_n_hires.png
python zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py --out zz-figures/chapter10/fig_04_scatter_p95_recalc_vs_orig.png
python zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py     --out zz-figures/chapter10/fig_05_hist_cdf_metrics.png
python zz-scripts/chapter10/plot_fig06_residual_map.py         --out zz-figures/chapter10/fig_06_heatmap_absdp95_m1m2.png
python zz-scripts/chapter10/plot_fig07_synthesis.py            --out zz-figures/chapter10/fig_07_summary_comparison.png
```

---

## 6) Données, figures & manifestes

- **Données** : `zz-data/chapterXX/` — CSV/DAT/JSON ; colonnes et unités documentées dans `conventions.md`.  
- **Figures** : `zz-figures/chapterXX/` — PNG (300 dpi mini), noms `fig_XX_*`.  
- **Manifestes** : inventaire, rapports et corrections :
  - `zz-manifests/manifest_master.json` (source maître)
  - `zz-manifests/manifest_publication.json` (sous-ensemble public)
  - `zz-manifests/diag_consistency.py` (audit; options `--report md`, `--fix`)

---

## 7) Qualité & CI

Workflows principaux (GitHub Actions) :
- `sanity-main.yml` : diagnostics quotidiens et sur push
- `ci-pre-commit.yml` : format/linters
- `ci-yaml-check.yml` : validation YAML
- `release-publish.yml` : build + publication (artefacts/wheel)

Référence : `docs/CI.md`.

---

## 8) Tests

```
pytest -q
```

Tests rapides disponibles pour `zz-tools` (imports, CLI, API publique, IO et figures de base).

---

## 9) Publication & empaquetage

### Paquet `zz-tools`

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

unzip -Z1 "$WHEEL" | grep -E '\.bak$|\.env$|\.pem$|\.key$|(^|/)zz-figures/|(^|/)zz-data/' || echo "OK wheel clean"
SDIST=$(ls -1 dist/*.tar.gz | tail -n1)
tar -tzf "$SDIST" | grep -E '\.venv|\.env$|\.pem$|\.key$|(^|/)zz-out/|(^|/)\.ci-|(^|/)\.ruff_cache' || echo "OK sdist clean"
```

Tag & push :
```
git add -A
git commit -m "release: zz-tools 0.2.99"
git tag v0.2.99
git push origin HEAD --tags
```

---

## 10) Licence, remerciements, citation

- **Licence** : MIT (cf. `LICENSE`).
- **Contact scientifique** : responsable MCGT.  
- **Contact technique** : mainteneur CI/scripts.

Pour citer : *MCGT — Modèle de Courbure Gravitationnelle Temporelle, v0.2.99, 2025.*


---
<!-- ZENODO_BADGE_START -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.15186836.svg)](https://doi.org/10.5281/zenodo.15186836)

### Citation
Si vous utilisez MCGT, merci de citer la version DOI : **10.5281/zenodo.15186836**.
Voir aussi `CITATION.cff`.
<!-- ZENODO_BADGE_END -->





---

▶ Guide de reproduction rapide : [docs/README-REPRO.md](docs/README-REPRO.md)

# ci-nudge

# ci-nudge-2

# ci-nudge-3

# ci-nudge-pypi

# ci-nudge-pypi

# ci-nudge-pypi
<!-- ci:touch docs-light -->
<!-- ci:touch docs-light run -->

### Installation (sécurisée par contrainte)

```bash
PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements.txt
PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements-dev.txt
```
