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

