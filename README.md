# ΨTMG Cosmology Framework

![Status](https://img.shields.io/badge/status-Preprint%20Ready%20(arXiv)-brightgreen)
![Version](https://img.shields.io/badge/version-v4.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

> **Ψ-Time Metric Gravity (ΨTMG).** Resolves the H₀ and S₈ tensions simultaneously with decisive Bayesian evidence of Δ ln 𝒵 = +40.3 against the standard ΛCDM model, intrinsically accounting for Occam's razor penalty.

## Overview
The **ΨTMG** framework introduces a purely geometric friction mechanism at late times, modifying the Hubble expansion rate without introducing additional propagating scalar degrees of freedom (avoiding ghost and Laplacian instabilities). This effective metric deformation naturally suppresses sub-horizon structure growth, offering a unified and falsifiable response to two of the main tensions in modern cosmology.

## Key Scientific Results (v4.0.0)
Our joint likelihood analysis (Pantheon+ SNe Ia, CMB shift parameters, and eBOSS DR16 BAO/RSD) yields the following 68% CL marginalized constraints:
- **Hubble Constant:** H₀ = 74.18 ± 0.82 km s⁻¹ Mpc⁻¹ (alignment with local SH0ES measurements).
- **Structure Growth:** S₈ = 0.748 ± 0.021 (agreement with DES/KiDS weak-lensing data).
- **Statistical Preference:** Δ ln 𝒵 = +40.3 (with > 5σ frequentist exclusion of the ΛCDM baseline in profile-likelihood space).

## Manuscript & Reproducibility
This repository is the source of truth for the v4.0.0 manuscript, formatted to **APS / RevTeX** standards.

### The Preprint
- **Source:** [`paper/main.tex`](paper/main.tex)
- **Bibliography:** [`paper/references.bib`](paper/references.bib)
- **Final PDF:** [`paper/main.pdf`](paper/main.pdf)

### Core Figures
- **Figure 01 (Corner Plot):** [`paper/figures/01_fig_corner.pdf`](paper/figures/01_fig_corner.pdf) — Robust MCMC posteriors.
- **Figure 02 (Profile Likelihood):** [`paper/figures/02_fig_likelihood.pdf`](paper/figures/02_fig_likelihood.pdf) — > 5σ visual exclusion of the ΛCDM baseline with precision inset.
- **Figure 03 (Tension Summary):** [`paper/figures/03_fig_tensions_summary.pdf`](paper/figures/03_fig_tensions_summary.pdf) — Joint H₀/S₈ tension synthesis.

## Build Instructions
To compile the LaTeX manuscript locally:

```bash
cd paper
./compile.sh
```

`paper/compile.sh` supports pinned containerized builds (Docker/Podman), optional local-image build, and local fallback toolchains.

Alternative local sequence:

```bash
cd paper
pdflatex main.tex && bibtex main && pdflatex main.tex && pdflatex main.tex
```

## What's New in Release v4.0.0
- **Theoretical Foundation:** Clarified the geometric friction mechanism at the effective perturbative level (no extra scalar modes, no ghost/Laplacian instabilities in the effective treatment).
- **Statistical Rigor:** Replaced legacy AIC/BIC emphasis with Nested Sampling Bayesian evidence (Δ ln 𝒵), including the model-complexity penalty.
- **Falsifiability:** Established low-redshift growth-rate measurements (especially fσ₈) as primary observational discriminants against standard phantom dark-energy behavior.
- **Repository Purge (Clean Slate):** Removed local virtual environments, Python caches, and legacy thesis artifacts from the active publication path for a lightweight, reproducible package.
