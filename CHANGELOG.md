# Changelog

## v3.3.1 GOLD (2026-03-03)

### Rupture from v3.1 to v3.3
- The repository is now standardized on the `ΨTMG` nomenclature. The earlier `ΨCDM` naming was retired because the validated model is no longer a minor phenomenological extension of `ΛCDM`; it is the metric-coupled `Ψ-Time Metric Gravity` realization used throughout the thesis and artifact pipeline.
- The decisive theoretical change is the abandonment of the universal-coupling branch at all scales. That branch could relieve `S_8`, but it remained structurally "under tension" because the coupling amplitude required by cosmology was incompatible with local gravitational-wave bounds.

### Scale Conflict Resolved
- Chapter 11 quantifies the screening failure of universal coupling: the cosmological amplitude needed to reach `S_8 ≈ 0.77` is of order `10^-3`, while the local LIGO-safe bound is of order `10^-6`, producing a scale conflict of roughly `×2000`.
- Chapter 12 replaces that failing branch with the Step-Function Transition Law centered near `k_c ≈ 10^-4 h Mpc^-1`. The local `k -> high` branch remains LIGO-safe, while the cosmological `k -> 0` branch stays active for structure growth.
- This transition is the decisive rupture that moves the theory from a model still "under tension" to a `Gold Standard` solution that reconciles local and cosmological scales, preserves LIGO, restores the low-`S_8` branch, and keeps the observational gains of the global fit.

### Validated GOLD Outcomes
- Stability and invariant audits (Chapters 01-03) pass under the production definitions and gates.
- Early-observation confrontation (Chapters 04-05) remains competitive against `ΛCDM` while preserving BBN.
- Structure and geometry (Chapters 06-08) confirm the `~9%` high-redshift growth boost, BAO pivot consistency, and the reduced sound horizon required by the high-`H_0` solution.
- Global CPL and MCMC inference (Chapters 09-10) remain locked on `H_0 ≈ 72.97`, `w_0 ≈ -0.69`, `w_a ≈ -2.81`, and `S_8 ≈ 0.718`.
- The final geometric closure (Chapters 11-12) certifies `100%` LIGO compliance together with the active cosmological branch reaching `S_8 = 0.7725`.

## v3.1.0 (2026-02-25)
- Major release integrating the linear-structure ODE solver and the RSD likelihood.
- Simultaneous resolution of the `H_0` and `S_8` tensions confirmed in the pre-transition framework.
- Consolidated MCMC constraints: `Ω_m = 0.243 ± 0.007`, `H_0 = 72.97^{+0.32}_{-0.30}` km/s/Mpc, `w_0 = -0.69 ± 0.05`, `w_a = -2.81^{+0.29}_{-0.14}`, `S_8 = 0.718 ± 0.030`.

## v2.7.2 (2026-02-24)
- Full integration of the `emcee` MCMC sampler and automated generation of the publication-grade corner plot.
- Inclusion of the MCMC corner plot directly in the manuscript PDF.
- Version references updated across code, README, and manuscript.

## v2.6.0 (2025-12-22)
- Version references updated across manuscript and project metadata.
