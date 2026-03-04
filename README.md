# Ψ-Time Metric Gravity (ΨTMG): A Metric-Coupled Resolution to Cosmological Tensions
![v3.3.1 GOLD - Verified Stability](https://img.shields.io/badge/v3.3.1_GOLD-Verified_Stability-gold)

Jean-Philip Lalumière

### Version 3.3.1 — "GOLD"

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/badge/version-v3.3.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**Ψ-Time Metric Gravity** (Metric-Coupled Gravity Theory) is the underlying theoretical framework. **ΨTMG** is its parameterized cosmological realization, designed to address the major tensions of the standard `ΛCDM` model (`H0`, `S8`, JWST) through a purely geometric approach.

## What's New in v3.3.1

This release seals the GOLD baseline of the theory: the universal-coupling branch has been replaced by the Step-Function Transition Law, separating the local LIGO-safe regime from the cosmological branch that resolves the late-time tensions. The result is a production model that is no longer under tension internally, but a stable cross-scale solution with validated theory, observations, and reproducibility gates.

- **Model Selection:** Integration of information-criterion calculations (`AIC/BIC`) to quantify the gain of the model dynamics.
- **JWST Predictions:** Export of falsifiable theoretical curves for structure evolution from `z=0` to `z=20`.
- **Peer-Review Ready:** Full reproducibility pipeline with pinned dependencies and one-command execution.
- **Scale Reconciliation:** Explicit `k`-transition branch proving simultaneous `S8 = 0.7725` and `100%` LIGO compliance.

## Key Results (MCMC Best-Fit)

The global MCMC scan (`Pantheon+`, BAO, CMB, RSD) yields:

- `Ωm = 0.243 ± 0.007`
- `H0 = 72.97 (+0.32 / -0.30)` km/s/Mpc
- `w0 = -0.69 ± 0.05`
- `wa = -2.81 (+0.29 / -0.14)`
- `S8 = 0.718 ± 0.030`

## The 9% Growth Signature

[Figure 9: Structure Growth Factor](assets/zz-figures/06_early_growth_jwst/06_fig_09_structure_growth_factor.png) shows the calibrated `ΨTMG` branch developing a `~9.05%` enhancement in the linear growth rate relative to `ΛCDM` for `z > 10`. This extra geometric pull accelerates early halo assembly enough to make the JWST population less anomalous without adding ad hoc astrophysical tuning. It is the direct observable signature of the low-`k` cosmological branch that remains active after the Step-Function Transition Law isolates the local LIGO-safe regime.

## Repository Structure

- `manuscript/`: LaTeX source of the thesis.
- `scripts/`: Scientific pipelines and plotting utilities.
- `output/`: Derived chains, tables, and auxiliary exported figures.
- `zz-zenodo/`: Final local delivery package and release artifacts.

## Reproducing the Results

```bash
chmod +x reproduce_paper_results.sh
./reproduce_paper_results.sh full
```

For the repository-level cold-run audit and the table-versus-manuscript consistency checks, see [REPRODUCIBILITY.md](REPRODUCIBILITY.md).

## Release Governance

The archival release tag `v3.3.1-GOLD` is immutable. Force-push, tag deletion, or tag retargeting on this archival reference is forbidden once published.
