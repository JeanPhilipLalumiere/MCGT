import logging
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle

# --- Logging ---
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# --- Paths ---
ROOT = Path(__file__).resolve().parents[2]
FIG_DIR = ROOT / "zz-figures" / "chapter06"
FIG_DIR.mkdir(parents=True, exist_ok=True)
OUT_PNG = FIG_DIR / "fig_01_schema_data_flow_cmb.png"

# --- Figure setup ---
fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
ax.axis("off")
fig.suptitle(
    "Pipeline de génération des données CMB (Chapitre 6)",
    fontsize=14,
    fontweight="bold",
    y=0.96,
)

# --- Block parameters ---
W, H = 0.26, 0.20  # largeur/hauteur des blocs
Ymid = 0.45  # position centrale en Y
DY = 0.25  # décalage vertical standard

# --- Blocks definitions ---
blocks = {
    "in": (0.05, Ymid, "pdot_plateau_z.dat", "#d7d7d7"),
    "scr": (0.36, Ymid, "generate_chapter06_data.py", "#a9dfbf"),
    "data": (
        0.67,
        Ymid + DY,
        "06_cls_*.dat\n06_delta_*.csv\n06_delta_rs_*.csv\n06_cmb_chi2_scan2D.csv\n06_params_cmb.json",
        "#d7d7d7",
    ),
    "fig": (
        0.67,
        Ymid - DY,
        "fig_02.png\nfig_03.png\nfig_04.png\nfig_05.png",
        "#d7d7d7",
    ),
}

# --- Draw blocks ---
for key, (x, y, label, color) in blocks.items():
    ax.add_patch(Rectangle((x, y), W, H, facecolor=color, edgecolor="k", lw=1.2))
    ax.text(
        x + W / 2,
        y + H / 2,
        label,
        ha="center",
        va="center",
        fontsize=8,
        family="monospace",
    )


# --- Arrow helpers ---
def east_center(x, y):
    return (x + W, y + H / 2)


def west_center(x, y):
    return (x, y + H / 2)


def draw_arrow(start, end, text, x_off=0, y_off=0):
    ax.add_patch(
        FancyArrowPatch(
            start, end, arrowstyle="-|>", mutation_scale=15, lw=1.3, color="k"
        )
    )
    xm = 0.5 * (start[0] + end[0]) + x_off
    ym = 0.5 * (start[1] + end[1]) + y_off
    ax.text(xm, ym, text, ha="center", va="center", fontsize=9)


# --- Draw arrows with adjusted offsets ---
# 1) input -> script : label déplacé vers le bas
draw_arrow(
    east_center(*blocks["in"][:2]),
    west_center(*blocks["scr"][:2]),
    "1. Lecture pdot",
    y_off=-DY / 1.8,
)

# 2) script -> data
draw_arrow(
    east_center(*blocks["scr"][:2]),
    west_center(*blocks["data"][:2]),
    "2. Génération données",
    x_off=+DY / 3,
    y_off=-DY / 8,
)

# 3) script
draw_arrow(
    east_center(*blocks["scr"][:2]),
    west_center(*blocks["fig"][:2]),
    "3. Export PNG",
    x_off=+DY / 4,
    y_off=+DY / 8,
)

# --- Finalize and save ---
plt.tight_layout(rect=[0, 0, 1, 0.93])
plt.savefig(OUT_PNG)
logging.info(f"Schéma enregistré → {OUT_PNG}")

# === MCGT CLI SEED v1 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
        parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
        parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
        parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
        parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
        parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
        parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
        args = parser.parse_args()
        try:
            os.makedirs(args.outdir, exist_ok=True)
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

