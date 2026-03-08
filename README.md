# PsiTMG Cosmology - Release Gold 4.0
![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Release](https://img.shields.io/badge/release-GOLD_4.0-gold)
![License](https://img.shields.io/badge/license-MIT-green)

`PsiTMG` is a scientific cosmology framework implementing a metric-coupled dark-energy/gravity scenario designed to test and potentially resolve late-time cosmological tensions against `LambdaCDM`.

## Scientific Highlights (Gold 4.0)

- `Victoire Statistique`: `Delta ln Z = 40.3` against `LambdaCDM`.
- `Tension H0`: `H0 = 74.185 km/s/Mpc`.
- `Tension S8`: `S8 = 0.748` (suppressed late-time growth).
- `Stabilite primordiale`: age of the Universe validated at `14.04 Gyr` with BBN preserved (`Delta N_eff = 0.0`).
- `Qualite logicielle`: object-oriented architecture, JIT acceleration (Numba), automated tests (`PyTest: 38 passed`), and Docker containerization.

## Software Architecture

- [`core_physics.py`](core_physics.py): cosmological background (`w(z)`, `E(z)`, inverse Hubble), including radiation and JIT kernels.
- [`perturbations.py`](perturbations.py): linear structure growth engine (`f sigma8`) with robust ODE solving.
- [`likelihoods.py`](likelihoods.py): modular likelihood evaluator (SNe, CMB, BAO isotropic/anisotropic, RSD, CC), with covariance support.
- [`diagnostics.py`](diagnostics.py): age, `S8` tension, NEC/BBN diagnostics, and validation plotting tools.
- [`boltzmann_interface.py`](boltzmann_interface.py): export interface for CLASS/CAMB workflows.
- [`test_architecture.py`](test_architecture.py): integration smoke test of the full stack.

## Quick Start (Local)

```bash
python -m pip install -r requirements.txt
python test_architecture.py
pytest tests/
```

## Quick Start (Docker)

```bash
docker build -t psitmg:gold4 .
docker run --rm psitmg:gold4
```

The container entrypoint runs:

```bash
python test_architecture.py
```

## Repository Layout

- `manuscript/`: publication material and LaTeX sources.
- `scripts/analysis/`: analysis pipelines (prior sensitivity, profile likelihood, etc.).
- `output/`: generated numerical outputs and diagnostics.
- `tests/`: automated regression and scientific integrity checks.

## Reproducibility

For reproducibility policies and cold-run checks, see [REPRODUCIBILITY.md](REPRODUCIBILITY.md).
