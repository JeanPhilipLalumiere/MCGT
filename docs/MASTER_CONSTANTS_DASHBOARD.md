# Master Constants Dashboard

Reference: config/scalar_perturbations.ini

## Reference Values (from scalar_perturbations.ini)

| Parameter | Value | Notes |
| --- | --- | --- |
| H0 | 67.36 |  |
| Omega_m | 0.313772 | Derived from ombh2+omch2 and H0 |
| Omega_lambda | 0.686228 | Derived from 1 - Omega_m - Omega_k |
| Omega_k | 0 |  |
| Omega_r | N/A |  |
| T_cmb | N/A |  |
| z_eq | N/A |  |
| z_rec | N/A |  |
| n_s | 0.9649 |  |
| A_s | 2.1e-09 |  |
| k_pivot | N/A |  |

## Hard-Coding Scan (chapters 01-06)

- scripts/chapter02/primordial_spectrum.py
  - L63: `As = A_S0 * (1 + C1 * alpha)`
  - L64: `ns = NS0 + C2 * alpha`
- scripts/chapter06/generate_data_chapter06.py
  - L124: `H0=cosmo_params["H0"],`
  - L167: `H0=cosmo_params["H0"],`
  - L307: `H0=cosmo_params["H0"],`
- scripts/chapter06/generate_pdot_plateau_vs_z.py
  - L38: `Omega_m = (ombh2 + omch2) / (h**2)`
