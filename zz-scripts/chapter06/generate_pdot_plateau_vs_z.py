import os
import argparse
import logging
from pathlib import Path

import numpy as np

from mcgt.constants import H0_KM_S_PER_MPC as H0  # unified

# --- Configuration logging ---
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# --- Chemins ---
ROOT = Path(__file__).resolve().parents[2]
# English folder name for configuration
CONF_DIR = ROOT / "zz-config"
OUT_FILE = CONF_DIR / "pdot_plateau_z.dat"
OUT_FILE.parent.mkdir(parents=True, exist_ok=True)

# --- Paramètres cosmologiques par défaut ---
# H0 unifié → import
ombh2 = 0.0224
omch2 = 0.12
tau = 0.06

# --- CLI ---
parser = argparse.ArgumentParser(description="Génère pdot_plateau_z.dat")
parser.add_argument("--zmin", type=float, default=1e-4, help="Redshift minimal")
parser.add_argument("--zmax", type=float, default=1e5, help="Redshift maximal")
parser.add_argument("--npoints", type=int, default=1000, help="Nombre de points")
args = parser.parse_args()

# --- Grille de redshift log-uniforme ---
log_z = np.linspace(np.log10(args.zmin), np.log10(args.zmax), args.npoints)
z_grid = 10**log_z

# --- Calcul de H(z)/H0 pour univers plat ---
h = H0 / 100.0
Omega_m = (ombh2 + omch2) / (h**2)
Omega_L = 1.0 - Omega_m
Hz_over_H0 = np.sqrt(Omega_m * (1 + z_grid) ** 3 + Omega_L)

# --- Export ---
header = "# z    H_over_H0"
np.savetxt(
    OUT_FILE,
    np.column_stack([z_grid, Hz_over_H0]),
    header=header,
    comments="",
    fmt="%.6e  %.6e",
)
logging.info(f"Fichier généré → {OUT_FILE}")

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
        parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
        parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
        parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
        parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
        parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
        parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")        parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
        parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
        parser.add_argument("--transparent", action="store_true", help="Transparent background")

        args = parser.parse_args()
        try:
            os.makedirs(args.outdir, exist_ok=True)
        os.environ["MCGT_OUTDIR"] = args.outdir
        import matplotlib as mpl
        mpl.rcParams["savefig.dpi"] = args.dpi
        mpl.rcParams["savefig.format"] = args.format
        mpl.rcParams["savefig.transparent"] = args.transparent
        except Exception:
            pass
        _main = globals().get("main")
        if callable(_main):
            try:
                _main(args)
            except SystemExit:
                raise
            except Exception as e:
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
                traceback.print_exc()
                sys.exit(1)
    _mcgt_cli_seed()
