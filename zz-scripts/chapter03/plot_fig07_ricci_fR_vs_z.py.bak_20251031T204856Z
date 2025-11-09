#!/usr/bin/env python3
# tracer_fig07_ricci_fR_contre_z.py

"""
Trace f_R et f_{RR} aux points jalons en fonction du redshift — Chapitre 3
========================================================================

Entrée :
    zz-data/chapter03/03_ricci_fR_vs_z.csv
Colonnes requises :
    R_over_R0, f_R, f_RR, z

Sortie :
    zz-figures/chapter03/03_fig_07_ricci_fr_vs_z.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# ----------------------------------------------------------------------
# Configuration logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_FILE = Path("zz-data") / "chapter03" / "03_ricci_fR_vs_z.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_07_ricci_fR_vs_z.png"


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
def main() -> None:
    # 1. Lecture des données
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return

    df = pd.read_csv(DATA_FILE)
    required = {"R_over_R0", "f_R", "f_RR", "z"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes dans %s : %s", DATA_FILE, missing)
        return

    # 2. Filtrer z > 0 et trier
    df = df[df["z"] > 0].sort_values("z")
    if df.empty:
        log.error("Aucun jalon avec z>0.")
        return

    zmin, zmax = df["z"].iloc[0], df["z"].iloc[-1]

    # 3. Préparer la figure
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    fig, ax1 = plt.subplots(dpi=300, figsize=(6, 4))

    # 4. Tracer f_R sur l'axe de gauche
    ax1.scatter(
        df["z"],
        df["f_R"],
        color="tab:blue",
        marker="o",
        s=40,
        alpha=0.8,
        label=r"$f_R$",
    )
    ax1.plot(df["z"], df["f_R"], color="tab:blue", lw=1, alpha=0.6)
    ax1.set_ylabel(r"$f_R$", color="tab:blue")
    ax1.tick_params(axis="y", colors="tab:blue")
    ax1.set_yscale("log")
    ax1.set_xscale("log")

    # 5. Tracer f_RR sur un second axe de droite
    ax2 = ax1.twinx()
    ax2.scatter(
        df["z"],
        df["f_RR"],
        color="tab:orange",
        marker="s",
        s=40,
        alpha=0.8,
        label=r"$f_{RR}$",
    )
    ax2.plot(df["z"], df["f_RR"], color="tab:orange", lw=1, alpha=0.6, linestyle="--")
    ax2.set_ylabel(r"$f_{RR}$", color="tab:orange")
    ax2.tick_params(axis="y", colors="tab:orange")
    ax2.set_yscale("log")

    # 6. Axes communs & grille
    ax1.set_xlabel("Redshift $z$")
    ax1.grid(True, which="both", ls=":", alpha=0.3)

    # 7. Légende combinée
    handles1, labels1 = ax1.get_legend_handles_labels()
    handles2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(
        handles1 + handles2,
        labels1 + labels2,
        loc="upper left",
        framealpha=0.8,
        edgecolor="black",
    )

    # 8. Titre avec plage effective
    ax1.set_title(
        rf"Jalons $f_R$ et $f_{{RR}}$ vs redshift $z\in[{zmin:.2f},\,{zmax:.2f}]$"
    )

    # 9. Finalisation
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    fig.savefig(FIG_PATH)
    plt.close(fig)
    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
    main()



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

