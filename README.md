# MCGT: Model of Gravitational Time Curvature

[![Zenodo](https://zenodo.org/badge/DOI/10.5281/zenodo.18002118.svg)](https://doi.org/10.5281/zenodo.18002118)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

Official repository for the MCGT research project, focused on Gravitational Wave Phase Analysis and Cosmological Invariants.

## ⚙️ Central Configuration
This project is now fully driven by a single central configuration file:
`zz-configuration/mcgt-global-config.ini`. All chapter scripts read their cosmological
parameters from this source of truth, and the `check_coherence.py` sentinel verifies
that no script diverges from the declared best-fit values.

## 🚀 Key Features
- **Sobol 8D Sampling**: Production-grade parameter space exploration.
- **Reproducible Pipeline**: All chapters certified with SHA256 consistency checks.
- **Physics Modules**: From CMB spectra to GW phase residuals.

## 🛠 Installation
```bash
git clone https://github.com/JeanPhilipLalumiere/MCGT.git
pip install -r requirements.txt
```

## 📊 Verification
```bash
python check_coherence.py
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json
```

## Citation
Lalumière, J.-P. (2025). MCGT : Modèle de la Courbure Gravitationnelle du Temps (Version 2.5.0). Zenodo. https://doi.org/10.5281/zenodo.18002118

*For French version, see [README_fr.md](README_fr.md).*
