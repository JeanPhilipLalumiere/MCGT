#!/usr/bin/env python3
import os
# plot_fig03_mu_vs_z.py
# ---------------------------------------------------------------
# Plot μ_obs(z) vs μ_th(z) for Chapter 8 (Dark coupling) of the MCGT project
# ---------------------------------------------------------------

import json
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# -- Chemins
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter08"
FIG_DIR = ROOT / "zz-figures" / "chapter08"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# -- Chargement des données
pantheon = pd.read_csv(DATA_DIR / "08_pantheon_data.csv", encoding="utf-8")
theory = pd.read_csv(DATA_DIR / "08_mu_theory_z.csv", encoding="utf-8")
params = json.loads((DATA_DIR / "08_coupling_params.json").read_text(encoding="utf-8"))
q0star = params.get("q0star_optimal", None)  # ou autre clé selon ton JSON

# -- Tri par redshift
pantheon = pantheon.sort_values("z")
theory = theory.sort_values("z")

# -- Configuration du tracé
plt.rcParams.update({"font.size": 11})
fig, ax = plt.subplots(figsize=(6.5, 4.5))

# -- Observations avec barres d'erreur
ax.errorbar(
    pantheon["z"],
    pantheon["mu_obs"],
    yerr=pantheon["sigma_mu"],
    fmt="o",
    markersize=5,
    capsize=3,
    label="Pantheon + obs",
)

# -- Courbe théorique
label_th = (
    rf"$\mu^{{\rm th}}(z; q_0^*={q0star:.3f})$"
    if q0star is not None
    else r"$\mu^{\rm th}(z)$"
)
ax.semilogx(theory["z"], theory["mu_calc"], "-", lw=2, label=label_th)

# -- Labels & titre
ax.set_xlabel("Redshift $z$")
ax.set_ylabel(r"Distance modulaire $\mu$\;[mag]")
ax.set_title(r"Comparaison $\mu^{\rm obs}$ vs $\mu^{\rm th}$")

# -- Grille & légende
ax.grid(which="both", ls=":", lw=0.5, alpha=0.6)
ax.legend(loc="lower right")

# -- Mise en page & sauvegarde
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
fig.savefig(FIG_DIR / "fig_03_mu_vs_z.png", dpi=300)
print("✅ fig_03_mu_vs_z.png générée dans", FIG_DIR)

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
