import os
import argparse
import logging
from pathlib import Path
import glob

import numpy as np

from mcgt.constants import H0KM_S_PER_MPC as H0  # unified

# --- Configuration logging ---


# --- Chemins ---
ROOT = Path( __file__).resolve().parents[ 2]
# English folder name for configuration
CONF_DIR = ROOT / "zz-config"
OUT_FILE = CONF_DIR / "pdot_plateau_z.dat"
OUT_FILE.parent.mkdir( parents=True, exist_ok=True)

# --- Paramètres cosmologiques par défaut ---
# H0 unifié → import
ombh2 = 0.0224
omch2 = 0.12
tau = 0.06

# --- CLI ---

if __name__ == "__main__":
    pass  # auto-added by STEP05c
parser = argparse.ArgumentParser( description="Génère pdot_plateau_z.dat")
parser.add_argument("--zmin", type=float, default=1e-4, help="Redshift minimal")
parser.add_argument("--zmax", type=float, default=1e5, help="Redshift maximal")
parser.add_argument("--npoints", type=int, default=1000, help="Nombre de points")
args = parser.parse_args()
try:
    _main(args)
except SystemExit:
    pass
except Exception as e:
    print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
    traceback.print_exc()
