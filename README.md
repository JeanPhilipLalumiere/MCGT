# ΨTMG Cosmology Framework

![Status](https://img.shields.io/badge/status-Preprint%20Ready%20(arXiv)-brightgreen)
![Version](https://img.shields.io/badge/version-v4.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

> **Ψ-Time Metric Gravity (ΨTMG).** Resolves the H₀ and S₈ tensions simultaneously with decisive Bayesian evidence of Δ ln 𝒵 = +40.3 against the standard ΛCDM model, intrinsically accounting for Occam's razor penalty.

## Overview
The **ΨTMG** framework introduces a purely geometric friction mechanism at late times, modifying the Hubble expansion rate without introducing additional propagating scalar degrees of freedom (avoiding ghost and Laplacian instabilities). This effective metric deformation naturally "freezes" the growth of sub-horizon structures, offering a unified and falsifiable solution to the most pressing crises in modern cosmology.

## Key Scientific Results (v4.0.0)
Our joint likelihood analysis (combining Pantheon+ SNe Ia, CMB shift parameters, and eBOSS DR16 BAO/RSD) yields the following 68% CL marginalized constraints:
- **Hubble Constant:** H₀ = 74.18 ± 0.82 km s⁻¹ Mpc⁻¹ (perfect alignment with local SH0ES measurements).
- **Structure Growth:** S₈ = 0.748 ± 0.021 (excellent agreement with DES/KiDS weak-lensing data).
- **Statistical Preference:** Δ ln 𝒵 = +40.3 (decisive > 5σ frequentist exclusion of ΛCDM).

## Manuscript & Reproducibility
This repository serves as the single source of truth for the v4.0.0 manuscript, formatted to **APS / RevTeX** standards and targeting a zero-warning build.

### The Preprint
- **Source:** [`paper/main.tex`](paper/main.tex)
- **Bibliography:** [`paper/references.bib`](paper/references.bib)
- **Final PDF:** [`paper/main.pdf`](paper/main.pdf)

### Core Figures
All figures are generated via isolated Python scripts and exported as vector PDFs.
- **Figure 01 (Corner Plot):** [`paper/figures/01_fig_corner.pdf`](paper/figures/01_fig_corner.pdf) — Robust MCMC posteriors.
- **Figure 02 (Profile Likelihood):** [`paper/figures/02_fig_likelihood.pdf`](paper/figures/02_fig_likelihood.pdf) — Demonstrates the > 5σ exclusion of the ΛCDM baseline, featuring a precision inset zoom.
- **Figure 03 (Tension Summary):** [`paper/figures/03_fig_tensions_summary.pdf`](paper/figures/03_fig_tensions_summary.pdf) — The definitive whisker plot showing simultaneous H₀ and S₈ reconciliation.

## Build Instructions
To compile the LaTeX manuscript locally:

```bash
cd paper
./compile.sh
```

Alternative standard LaTeX sequence:

```bash
cd paper
pdflatex main.tex && bibtex main && pdflatex main.tex && pdflatex main.tex
```

## What's New in Release v4.0.0
- **Theoretical Foundation:** Clarified the geometric friction mechanism at the effective perturbative level (no scalar modes, no instabilities in the effective treatment).
- **Statistical Rigor:** Replaced legacy AIC/BIC emphasis with Nested Sampling Bayesian evidence (Δ ln 𝒵), validating robustness under Occam's penalty.
- **Falsifiability:** Established low-redshift growth-rate measurements (fσ₈) as the primary observational discriminator against standard phantom dark energy.
- **Repository Purge (Clean Slate):** Deep repository overhaul. Removed local virtual environments, Python caches, and legacy thesis artifacts to provide a lightweight, reproducible scientific package.
