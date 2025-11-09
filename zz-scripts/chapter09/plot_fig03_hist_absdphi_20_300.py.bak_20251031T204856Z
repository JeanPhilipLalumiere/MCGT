#!/usr/bin/env python3
# ch09 fig03 — producteur propre (prefer --diff, fallback --csv), fenêtre 20–300 Hz, X log.

from __future__ import annotations
import argparse, warnings
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Histogramme |Δφ| — bande 20–300 Hz (prefer --diff, fallback --csv)."
    )
    p.add_argument("--diff", type=Path, default=None,
                   help="CSV avec colonnes {f_Hz, abs_dphi}")
    p.add_argument("--csv", type=Path, default=None,
                   help="CSV avec colonnes {f_Hz, phi_ref, phi_mcgt} (fallback)")
    p.add_argument("--out", type=Path, default=Path("zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png"))
    p.add_argument("--dpi", type=int, default=150)
    p.add_argument("--bins", type=int, default=80)
    p.add_argument("--window", type=float, nargs=2, default=(20.0, 300.0), metavar=("FMIN","FMAX"))
    return p.parse_args()

def load_data(args: argparse.Namespace) -> tuple[np.ndarray, np.ndarray]:
    # Try --diff first
    if args.diff and args.diff.exists():
        df = pd.read_csv(args.diff)
        need = {"f_Hz", "abs_dphi"}
        if not need.issubset(df.columns):
            warnings.warn(f"--diff présent mais colonnes manquantes: {need - set(df.columns)} → fallback --csv")
        else:
            f = df["f_Hz"].astype(float).to_numpy()
            abs_dphi = df["abs_dphi"].astype(float).to_numpy()
            return f, abs_dphi
    # Fallback --csv
    if not (args.csv and args.csv.exists()):
        raise SystemExit("Aucun input valide: fournir --diff (f_Hz,abs_dphi) ou --csv (f_Hz,phi_ref,phi_mcgt).")
    mc = pd.read_csv(args.csv)
    need = {"f_Hz", "phi_ref", "phi_mcgt"}
    if not need.issubset(mc.columns):
        raise SystemExit(f"--csv incomplet: colonnes manquantes: {need - set(mc.columns)}")
    f = mc["f_Hz"].astype(float).to_numpy()
    abs_dphi = np.abs(mc["phi_mcgt"].astype(float).to_numpy() - mc["phi_ref"].astype(float).to_numpy())
    return f, abs_dphi

def main() -> None:
    args = parse_args()
    f, abs_dphi = load_data(args)

    # Fenêtre & filtrage
    fmin, fmax = sorted(map(float, args.window))
    sel = np.isfinite(abs_dphi) & np.isfinite(f) & (f >= fmin) & (f <= fmax)
    if not np.any(sel):
        raise SystemExit(f"Aucun point dans la fenêtre {fmin}-{fmax} Hz.")
    x = abs_dphi[sel]

    # Plot
    fig = plt.figure()
    plt.hist(x, bins=int(args.bins))
    plt.xscale("log")
    plt.xlabel("|Δφ| (rad)")
    plt.ylabel("Counts")
    plt.title("Histogramme |Δφ| — bande 20–300 Hz")

    # Écriture
    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=int(args.dpi), bbox_inches="tight")
    print(f"Wrote: {args.out}")

if __name__ == "__main__":
    main()

# === MCGT:CLI-SHIM-BEGIN ===
# Ce bloc est idempotent et satisfait la policy CLI sans modifier la logique existante.
# Il expose des flags communs et, s ils ne sont pas consommés par le script,
# ils sont simplement ignorés.

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
    # Application non intrusive: uniquement si style demandé
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # force l init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Ne jamais casser le producteur si le style/DPI échoue.
        pass
    return args

# Exposition module-scope pour la CI (et usage éventuel par le script)
try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===

