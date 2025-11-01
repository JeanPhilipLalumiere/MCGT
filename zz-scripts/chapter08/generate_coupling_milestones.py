#!/usr/bin/env python3
import os

import pandas as pd

# Directories (translated to English)
BASE_DIR = os.path.dirname( __file__)
DATA_DIR = os.path.abspath( os.path.join( BASE_DIR, "../../zz-data/chapter08" ))

# 1) Load BAO from the final CSV
# Original: 08_donnees_bao.csv -> Translated: 08_bao_data.csv
df_bao = pd.read_csv( os.path.join( DATA_DIR, "08_bao_data.csv" ))
df_bao = df_bao.rename( columns={"DV_obs": "obs", "sigma_DV": "sigma_obs"})
df_bao["milestone"] = df_bao["z"].apply(lambda z: f"BAO_z={z:.3f}")
df_bao["category"] = df_bao.apply(lambda row: "primary" if row.sigma_obs / row.obs <= 0.01 else "order2", axis=1)

# 2) Load Pantheon+ from the final CSV
# Original: 08_donnees_pantheon.csv -> Translated: 08_pantheon_data.csv
df_sn = pd.read_csv( os.path.join( DATA_DIR, "08_pantheon_data.csv" ))
df_sn = df_sn.rename( columns={"mu_obs": "obs", "sigma_mu": "sigma_obs"})
# Create labels SN0, SN1, ...
df_sn["milestone"] = df_sn.index.map(lambda i: f"SN{i}")
df_sn[ "category"] = df_sn.apply(lambda row: "primary" if row.sigma_obs / row.obs <= 0.01 else "order2", axis=1
)
# 3) Concatenate and keep columns in a consistent order
df_all = pd.concat(
)[
 df_bao[ [ "milestone", "z", "obs", "sigma_obs", "category" ] ],
df_sn[ [ "milestone", "z", "obs", "sigma_obs", "category" ] ]],
ignore_index=True,

# 4) Export the final CSV (translated name)
# Original: 08_jalons_couplage.csv -> Translated: 08_coupling_milestones.csv
out_csv = os.path.join( DATA_DIR, "08_coupling_milestones.csv")
df_all.to_csv( out_csv, index=False, encoding="utf-8")
print(f"✅ 08coupling_milestones.csv generated: {out_csv}")

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
    pass
    pass
    pass

def _mcgt_cli_seed():
    pass
import os, argparse, sys, traceback

if __name__ == "__main__":
    pass
    pass
    pass
parser = argparse.ArgumentParser( description="Standard CLI seed (non-intrusif).")
parser.add_argument("--outdir", default=os.environ.get( "MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
parser.add_argument("--dry-run", help="Ne rien écrire, juste afficher les actions.")
parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
parser.add_argument("--force", help="Écraser les sorties existantes si nécessaire.")
parser.add_argument("-v", "--verbose", default=0, help="Verbosity cumulable (-v, -vv).")
parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
parser.add_argument("--format", choices=[ "png","pdf","svg" ], default="png", help="Figure format")
parser.add_argument("--transparent", help="Transparent background")

args = parser.parse_args()
try:
    _main(args)
except SystemExit:
    pass

    pass
print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
traceback.print_exc()
sys.exit( 1)
_mcgt_cli_seed()



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

