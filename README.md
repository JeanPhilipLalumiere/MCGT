# ΨTMG Cosmology Framework

![Status](https://img.shields.io/badge/status-Preprint%20Ready%20(arXiv)-brightgreen)
![Version](https://img.shields.io/badge/version-v4.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

> **Ψ-Time Metric Gravity (ΨTMG).** Resolves the H₀ and S₈ tensions simultaneously with a decisive Bayesian evidence of Δ ln 𝒵 = +40.3 against the standard ΛCDM model, intrinsically accounting for Occam's razor penalty.

## Overview
The **ΨTMG** framework introduces a purely geometric friction mechanism at late times, modifying the Hubble expansion rate without introducing additional propagating scalar degrees of freedom (avoiding ghost and Laplacian instabilities). This effective metric deformation naturally "freezes" the growth of sub-horizon structures, offering a unified, falsifiable solution to the most pressing crises in modern cosmology.

## Key Scientific Results (v4.0.0)
Our joint likelihood analysis (combining Pantheon+ SNe Ia, CMB shift parameters, and eBOSS DR16 BAO/RSD) yields the following 68% CL marginalized constraints:
- **Hubble Constant:** H₀ = 74.18 ± 0.82 km s⁻¹ Mpc⁻¹ (alignment with local SH0ES measurements).
- **Structure Growth:** S₈ = 0.748 ± 0.021 (agreement with DES/KiDS weak-lensing data).
- **Statistical Preference:** Δ ln 𝒵 = +40.3 (with > 5σ frequentist exclusion of the ΛCDM baseline in the profile-likelihood view).

## Manuscript & Reproducibility
This repository is the source of truth for the v4.0.0 manuscript, formatted to **APS / RevTeX** standards.

### The Preprint
- **Source:** [`paper/main.tex`](paper/main.tex)
- **Bibliography:** [`paper/references.bib`](paper/references.bib)
- **Final PDF:** [`paper/main.pdf`](paper/main.pdf)

### Core Figures
- **Figure 01 (Corner Plot):** [`paper/figures/01_fig_corner.pdf`](paper/figures/01_fig_corner.pdf)
- **Figure 02 (Profile Likelihood):** [`paper/figures/02_fig_likelihood.pdf`](paper/figures/02_fig_likelihood.pdf)
- **Figure 03 (Tension Summary):** [`paper/figures/03_fig_tensions_summary.pdf`](paper/figures/03_fig_tensions_summary.pdf)

## Build Instructions
To compile the LaTeX manuscript locally:

```bash
cd paper
./compile.sh
```

`paper/compile.sh` now supports:
- pinned container image (default) with Docker **or** Podman,
- optional local image build (`--local-image`),
- controlled local fallback (`latexmk` / `pdflatex+bibtex` / `tectonic`) when no container runtime is usable.

Examples:

```bash
cd paper
./compile.sh --engine podman
./compile.sh --local-image
./compile.sh --local-only
```

## Reproducibility Quick Check

```bash
export PYTHONPATH="$(pwd)/src:$(pwd):${PYTHONPATH}"
python scripts/verify_table_consistency.py
pytest -q tests/test_00_imports.py tests/test_phase4_zenodo_package.py
```

## What's New in Release v4.0.0
- **Theoretical foundation:** Clarified the geometric friction mechanism at the effective perturbative level (no additional scalar modes, no ghost/Laplacian instabilities in the effective treatment).
- **Statistical rigor:** Emphasized Nested Sampling Bayesian evidence (Δ ln 𝒵), including the model-complexity penalty.
- **Falsifiability:** Established low-redshift growth-rate measurements, especially \(f\sigma_8(z)\), as a primary discriminator.
- **Repository clean slate:** Removed local virtual environments, Python caches, and legacy thesis material from the active publication path.
