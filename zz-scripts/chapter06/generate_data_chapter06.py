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



# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.

def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None, help="Chemin de sortie (optionnel).")
    p.add_argument("--dpi", type=int, default=None, help="DPI de sortie (optionnel).")
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"], help="Format de sortie.")
    p.add_argument("--transparent", action="store_true", help="Fond transparent si supporté.")
    p.add_argument("--style", type=str, default=None, help="Style matplotlib (optionnel).")
    p.add_argument("--verbose", action="store_true", help="Verbosité accrue.")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # force init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Ne jamais casser le producteur si style/DPI échoue.
        pass
    return args

try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===

