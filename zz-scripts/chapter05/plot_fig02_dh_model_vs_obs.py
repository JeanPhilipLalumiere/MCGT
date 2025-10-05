import os
import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.interpolate import PchipInterpolator

# Répertoires
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter05"
FIG_DIR = ROOT / "zz-figures" / "chapter05"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Chargement des données
jalons = pd.read_csv(DATA_DIR / "05_bbn_milestones.csv")
donnees = pd.read_csv(DATA_DIR / "05_bbn_data.csv")

# Chargement des métriques
params_path = DATA_DIR / "05_bbn_params.json"
if params_path.exists():
    params = json.load(open(params_path))
    max_ep_primary = params.get("max_epsilon_primary", None)
    max_ep_order2 = params.get("max_epsilon_order2", None)
else:
    max_ep_primary = None
    max_ep_order2 = None

# Interpolation PCHIP pour DH_calc aux temps des jalons
interp = PchipInterpolator(
    np.log10(donnees["T_Gyr"].values),
    np.log10(donnees["DH_calc"].values),
    extrapolate=False,
)
jalons["DH_calc"] = 10 ** interp(np.log10(jalons["T_Gyr"].values))

# Préparation du tracé
fig, ax = plt.subplots(figsize=(8, 5))
ax.set_xscale("log")
ax.set_yscale("log")

# Barres d'erreur et points de calibration
ax.errorbar(
    jalons["DH_obs"],
    jalons["DH_calc"],
    yerr=jalons["sigma_DH"],
    fmt="o",
    label="Points de calibration",
)

# Droite d'identité y = x
lims = [
    min(jalons["DH_obs"].min(), jalons["DH_calc"].min()),
    max(jalons["DH_obs"].max(), jalons["DH_calc"].max()),
]
ax.plot(lims, lims, ls="--", color="black", label="Identité")

# Annotation des métriques de calibration repositionnée
txt_lines = []
if max_ep_primary is not None:
    txt_lines.append(f"max ε_primary = {max_ep_primary:.2e}")
if max_ep_order2 is not None:
    txt_lines.append(f"max ε_order2 = {max_ep_order2:.2e}")
if txt_lines:
    ax.text(
        0.05,
        0.5,
        "\n".join(txt_lines),
        transform=ax.transAxes,
        va="center",
        ha="left",
        bbox=dict(boxstyle="round", facecolor="white", alpha=0.5),
    )

# Légendes et annotations
ax.set_xlabel("D/H observé")
ax.set_ylabel("D/H calculé")
ax.set_title("Diagramme D/H : modèle vs observations")
ax.legend(framealpha=0.3, loc="upper left")

# Enregistrement
plt.tight_layout()
plt.savefig(FIG_DIR / "fig_02_dh_model_vs_obs.png", dpi=300)
plt.close()

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
    parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
    parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
    parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
    parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
    parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
    parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
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
