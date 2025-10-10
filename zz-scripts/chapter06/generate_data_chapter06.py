import os
import glob
# ---IMPORTS & CONFIGURATION---

import argparse
import json
import logging
from pathlib import Path

import camb
import numpy as np
import pandas as pd

# Configuration du logging


# Parser CLI
parser = argparse.ArgumentParser(description="Chapter 6 pipeline: generate CMB spectra for MCGT")
parser.add_argument("--alpha", type=float, default=0.0, help="Modulation amplitude α")
# "--q0star",
# MCGT(fixed): type=float,
# MCGT(fixed): default=0.0,
# MCGT(fixed): help="Effective curvature parameter q0star (Ω_k)",
parser.add_argument("--export-derivative", action="store_true", help="Export derivative Δχ2/Δℓ")
args = parser.parse_args()

ALPHA = args.alpha
Q0STAR = args.q0star

    # Project root directory
ROOT = Path( __file__).resolve().parents[ 2]

    # Config and data directories (English names)
CONF_DIR = ROOT / "zz-configuration"
DATA_DIR = ROOT / "zz-data" / "chapter06"
INI_DIR = ROOT / "06-cmb"
DATA_DIR.mkdir( parents=True, exist_ok=True)
# ---LOAD CHAPTER-2 SPECTRUM COEFFICIENTS---
# Note: chapter02 path uses English folder name "chapter02" and spec file
SPEC2FILE = ROOT / "zz-data" / "chapter02" / "02_spec_spectrum.json"
with open(SPEC2FILE, encoding="utf-8") as f:
    spec2 = json.load(f)
A_S0 = spec2.get("constantes", {}).get("A_s0", spec2.get("constants", {}).get("A_s0"))
