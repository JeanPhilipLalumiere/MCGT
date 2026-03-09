# PsiTMG Cosmology
![Status](https://img.shields.io/badge/status-Preprint%20Ready%20(arXiv)-brightgreen)
![Version](https://img.shields.io/badge/version-v4.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

`PsiTMG` is a cosmology framework and manuscript pipeline focused on late-time metric-gravity phenomenology.  
The manuscript is now **preprint-ready** and formatted to **APS / RevTeX** standards for arXiv submission.

## Manuscript

- Source: [`paper/main.tex`](paper/main.tex)
- Bibliography: [`paper/references.bib`](paper/references.bib)
- Final PDF: [`paper/main.pdf`](paper/main.pdf)

## Figures (v4.0.0)

- Figure 1 (Corner): [`paper/figures/01_fig_corner.pdf`](paper/figures/01_fig_corner.pdf)
- Figure 2 (Profile likelihood): [`paper/figures/02_fig_likelihood.pdf`](paper/figures/02_fig_likelihood.pdf)
- Figure 3 (Tension summary): [`paper/figures/03_fig_tensions_summary.pdf`](paper/figures/03_fig_tensions_summary.pdf)

Key reported values in the current preprint: $H_0 = 74.18 \pm 0.82$, $S_8 = 0.748 \pm 0.021$, and $\Delta \ln \mathcal{Z} = +40.3$.

## Build

```bash
cd paper
./compile.sh
```

## What's New in v4.0.0

- **Theoretical foundation:** Clarified the purely geometric friction mechanism, with no propagating scalar modes and no ghost/Laplacian instability at the effective perturbative level.
- **Robustness:** Validated the Bayes factor ($\Delta \ln \mathcal{Z}$) under broader absolute-magnitude ($M_B$) priors.
- **Falsifiability:** Added concrete observable predictions, including low-redshift suppression in $f\sigma_8(z)$ and signatures in CMB lensing/ISW channels.
- **Layout:** Optimized two-column manuscript structure, figure placement, and bibliography flow for professional preprint distribution.

## Recent Changes

- Finalized theoretical mechanism, robust prior validation, and optimized layout for physical review standards.
- Consolidated release metadata and artifact naming under version `v4.0.0`.
