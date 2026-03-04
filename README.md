Version 3.3.1 — "GOLD"
Ψ-Time Metric Gravity (Metric-Coupled Gravity Theory) is the underlying theoretical framework. ΨTMG is its parameterized cosmological realization, designed to address the major tensions of the standard ΛCDM model (H₀, S₈, JWST) through a purely geometric approach.

What's New in v3.3.1
This release seals the GOLD baseline of the theory: the universal-coupling branch has been replaced by the Step-Function Transition Law, separating the local LIGO-safe regime from the cosmological branch that resolves the late-time tensions. The result is a production model that is no longer "under tension" internally, but a stable cross-scale solution with validated theory, observations, and reproducibility gates.

Model Selection: Integration of information-criterion calculations (AIC/BIC), mathematically quantifying the benefit of the model dynamics.

JWST Predictions: Export of falsifiable theoretical curves for structure evolution from z = 0 to z = 20.

Peer-Review Ready: Full reproducibility pipeline with pinned dependencies and one-command execution.

Scale Reconciliation: Explicit k-transition branch proving simultaneous S₈ ≈ 0.7725 and 100% LIGO compliance.

Microphysics Note: Archival of the TIDE exploration as a viscoelastic motivation for metric coupling, without replacing the production CPL baseline.

BHS Deployment Support: Addition of a Kimsufi/Beauharnois deployment script and a Sentinel performance check for rapid qualification of a fresh machine.

Key Results (MCMC Best-Fit)
The global MCMC scan (Pantheon+, BAO, CMB, RSD) breaks the standard degeneracies:

Ωm = 0.243 ± 0.007

H₀ = 72.97 (+0.32 / -0.30) km/s/Mpc

w₀ = -0.69 ± 0.05

wa = -2.81 (+0.29 / -0.14)

S₈ = 0.718 ± 0.030

Model Selection and Information Criteria
The ΨTMG model overwhelmingly overcomes the complexity penalty (Occam's razor). For a total of 1718 data points, the improvement relative to standard ΛCDM qualifies as "decisive evidence" on the Jeffreys scale (ΔBIC ≪ -10).

Plaintext
=== Information Criteria ===
k (free parameters)      5
n (total data points)    1718
AIC                      809.12
BIC                      836.37
(Global improvement: Δχ² = -151.6 | ΔAIC = -145.6 | ΔBIC = -129.2)

Theoretical Note: TIDE Microphysics
Although ΨTMG is currently formulated as an effective field theory (EFT), the v3.2.1 control tests suggest that an inertial-torsion mechanism of TIDE type could provide the microscopic origin of the observed metric coupling, even if the present parametrization still requires a broader generalization to match the statistical precision of ΨTMG.

Control benchmark:

ΨTMG v3.2.0 (CPL baseline): Δχ² = -151.6, H₀ = 72.97, S₈ = 0.718.

TIDE v3.2.1 (research archive): Δχ² ≈ -55.6, H₀ ≈ 74.11, S₈ ≈ 0.740.

The production baseline therefore remains ΨTMG v3.2.0, while the v3.2.1-tide-integration branch is preserved as a theoretical and methodological archive.

Infrastructure and Deployment
Release v3.3.1 introduces a minimal deployment infrastructure for Kimsufi BHS servers running Ubuntu 24.04 LTS.

deploy_kimsufi_bhs.sh: one-click installation of system dependencies, Python environment setup, repository cloning, and optional CLASS compilation.

check_bhs_performance.py: quick Sentinel likelihood benchmark before a long MCMC run.

Bash
chmod +x deploy_kimsufi_bhs.sh
./deploy_kimsufi_bhs.sh
python check_bhs_performance.py
Scientific Breakthroughs
Hubble tension (H₀): Resolved through a dynamical reduction of the sound horizon (rs) at decoupling, without degrading the CMB spectrum (χ²_CMB = 0.04).

JWST anomaly: Explained through a geometric gravitational boost of linear-structure growth at high redshift (z > 10).

S₈ tension: Naturally damped by the dynamical evolution of the equation of state, reconciling expansion data with gravitational shear (weak lensing).

The 9.05% Growth Signature
The calibrated ΨTMG branch develops a ≈ 9.05% enhancement in the linear growth rate relative to ΛCDM for z > 10. This physically lifts the maturity of early halos without invoking exotic astrophysical tuning, providing a direct geometric explanation for the unexpectedly evolved galaxies reported by JWST.

Repository Structure
manuscript/: Contains the LaTeX source (main.tex) of the publication.

scripts/: Utility Python scripts, for example export_predictions.py for generating JWST prediction tables.

output/: Stores the HDF5 MCMC chains, prediction CSV tables, and generated corner plots.

reproduce_paper_results.sh: The main automated pipeline.

Reproducing the Results (Peer-Review Ready)
To guarantee independent transparency and reproducibility, a unified execution script is provided. It installs the exact environment, reruns the MCMC inference, and regenerates the publication figures.

Bash
# 1. Make the script executable (Linux/Mac)
chmod +x reproduce_paper_results.sh

# 2. Run the full pipeline
./reproduce_paper_results.sh full

# Alternative: run a quick validation test
./reproduce_paper_results.sh test
For the repository-level cold-run audit and the table-versus-manuscript consistency checks, see REPRODUCIBILITY.md.
