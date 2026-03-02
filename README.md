# Ψ-Time Metric Gravity (ΨTMG): A Metric-Coupled Resolution to Cosmological Tensions
### Version 3.3.0 — "The BHS & Microphysics Update"

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/badge/version-v3.3.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**Ψ-Time Metric Gravity** (Metric-Coupled Gravity Theory) is the underlying theoretical framework. **ΨTMG** is its parameterized cosmological realization, designed to address the major tensions of the standard $\Lambda$CDM model ($H_0$, $S_8$, JWST) through a purely geometric approach.

## What's New in v3.3.0
This release consolidates the v3.2.0 statistical baseline while adding the TIDE microphysical motivation and deployment infrastructure for Ubuntu 24.04 LTS environments.
* **Model Selection:** Integration of information-criterion calculations (AIC/BIC), mathematically quantifying the benefit of the model dynamics.
* **JWST Predictions:** Export of falsifiable theoretical curves for structure evolution from `$z=0$` to `$z=20$`.
* **Peer-Review Ready:** Full reproducibility pipeline with pinned dependencies and one-command execution.
* **Microphysics Note:** Archival of the TIDE exploration as a viscoelastic motivation for metric coupling, without replacing the production CPL baseline.
* **BHS Deployment Support:** Addition of a Kimsufi/Beauharnois deployment script and a Sentinel performance check for rapid qualification of a fresh machine.

## Key Results (MCMC Best-Fit)
The global MCMC scan (Pantheon+, BAO, CMB, RSD) breaks the standard degeneracies:
* **$\Omega_m$** = 0.243 ± 0.007
* **$H_0$** = 72.97 (+0.32 / -0.30) km/s/Mpc
* **$w_0$** = -0.69 ± 0.05
* **$w_a$** = -2.81 (+0.29 / -0.14)
* **$S_8$** = 0.718 ± 0.030

## Model Selection and Information Criteria
The ΨTMG model overwhelmingly overcomes the complexity penalty (Occam's razor). For a total of 1718 data points, the improvement relative to standard $\Lambda$CDM qualifies as "decisive evidence" on the Jeffreys scale ($\Delta\text{BIC} \ll -10$).

```text
=== Information Criteria ===
k (free parameters)      5
n (total data points)    1718
AIC                      809.12
BIC                      836.37

```

*(Global improvement: $\Delta\chi^2$ = -151.6 | $\Delta$AIC = -145.6 | $\Delta$BIC = -129.2)*

## Theoretical Note: TIDE Microphysics
Although $\Psi$TMG is currently formulated as an effective field theory (EFT), the v3.2.1 control tests suggest that an inertial-torsion mechanism of TIDE type could provide the microscopic origin of the observed metric coupling, even if the present parametrization still requires a broader generalization to match the statistical precision of $\Psi$TMG.

Control benchmark:
* **$\Psi$TMG v3.2.0 (CPL baseline):** $\Delta\chi^2 = -151.6$, $H_0 = 72.97$, $S_8 = 0.718$.
* **TIDE v3.2.1 (research archive):** $\Delta\chi^2 \approx -55.6$, $H_0 \approx 74.11$, $S_8 \approx 0.740$.

The production baseline therefore remains $\Psi$TMG v3.2.0, while the `v3.2.1-tide-integration` branch is preserved as a theoretical and methodological archive.

## Infrastructure and Deployment

Release `v3.3.0` introduces a minimal deployment infrastructure for Kimsufi BHS servers running Ubuntu 24.04 LTS.

* `deploy_kimsufi_bhs.sh`: one-click installation of system dependencies, Python environment setup, repository cloning, and optional CLASS compilation.
* `check_bhs_performance.py`: quick Sentinel likelihood benchmark before a long MCMC run.

Example:

```bash
chmod +x deploy_kimsufi_bhs.sh
./deploy_kimsufi_bhs.sh
python check_bhs_performance.py
```

## Scientific Breakthroughs

* **Hubble tension ($H_0$):** Resolved through a dynamical reduction of the sound horizon ($r_s$) at decoupling, without degrading the CMB spectrum ($\chi^2_{CMB}$ = 0.04).
* **JWST anomaly:** Explained through a geometric gravitational boost of linear-structure growth at high redshift ($z > 10$).
* **$S_8$ tension:** Naturally damped by the dynamical evolution of the equation of state, reconciling expansion data with gravitational shear (weak lensing).

## Repository Structure

* `manuscript/`: Contains the LaTeX source (`main.tex`) of the publication.
* `scripts/`: Utility Python scripts, for example `export_predictions.py` for generating JWST prediction tables.
* `output/`: Stores the HDF5 MCMC chains, prediction CSV tables, and generated corner plots.
* `reproduce_paper_results.sh`: The main automated pipeline.

## Reproducing the Results (Peer-Review Ready)

To guarantee independent transparency and reproducibility, a unified execution script is provided. It installs the exact environment, reruns the MCMC inference, and regenerates the publication figures.

```bash
# 1. Make the script executable (Linux/Mac)
chmod +x reproduce_paper_results.sh

# 2. Run the full pipeline
./reproduce_paper_results.sh full

# Alternative: run a quick validation test
./reproduce_paper_results.sh test
