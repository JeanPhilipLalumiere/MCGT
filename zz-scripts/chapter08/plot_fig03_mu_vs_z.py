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
params = json.loads(
    (DATA_DIR /
     "08_coupling_params.json").read_text(
        encoding="utf-8"))
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
fig.tight_layout()
fig.savefig(FIG_DIR / "fig_03_mu_vs_z.png", dpi=300)
print("✅ fig_03_mu_vs_z.png générée dans", FIG_DIR)

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os
        import argparse
        import sys
        import traceback

if __name__ == "__main__":
    import argparse
    import os
    import sys
    import logging
    import matplotlib
    import matplotlib.pyplot as plt
    parser = argparse.ArgumentParser(description="MCGT CLI")
    parser.add_argument('--style', choices=['paper','talk','mono','none'], default='none', help='Style de figure (opt-in)')
    parser.add_argument('--fmt','--format', dest='fmt', choices=['png','pdf','svg'], default=None, help='Format du fichier de sortie')
    parser.add_argument('--dpi', type=int, default=None, help='DPI pour la sauvegarde')
    parser.add_argument('--outdir', type=str, default=None, help='Dossier pour copier la figure (fallback $MCGT_OUTDIR)')
    parser.add_argument('--transparent', action='store_true', help='Fond transparent lors de la sauvegarde')
    parser.add_argument('--verbose', action='store_true', help='Verbosity CLI (logs supplémentaires)')
    args = parser.parse_args()

    # [smoke] OUTDIR+copy
    OUTDIR_ENV = os.environ.get("MCGT_OUTDIR")
    if OUTDIR_ENV:
        args.outdir = OUTDIR_ENV
    os.makedirs(args.outdir, exist_ok=True)
    import atexit
    import glob
    import shutil
    import time
    _ch = os.path.basename(os.path.dirname(__file__))
    _repo = os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            "..",
            ".."))
    _default_dir = os.path.join(_repo, "zz-figures", _ch)
    _t0 = time.time()

    def _smoke_copy_latest():
        try:
            pngs = sorted(
                glob.glob(
                    os.path.join(
                        _default_dir,
                        "*.png")),
                key=os.path.getmtime,
                reverse=True)
            for _p in pngs:
                if os.path.getmtime(_p) >= _t0 - 10:
                    _dst = os.path.join(args.outdir, os.path.basename(_p))
                    if not os.path.exists(_dst):
                        shutil.copy2(_p, _dst)
                    break
        except Exception:
            pass
    atexit.register(_smoke_copy_latest)
    if args.verbose:
        level = logging.INFO if args.verbose == 1 else logging.DEBUG
        logging.basicConfig(level=level, format="%(levelname)s: %(message)s")

    if args.outdir:
        try:
            os.makedirs(args.outdir, exist_ok=True)
        except Exception:
            pass

    try:
        matplotlib.rcParams.update({"savefig.dpi": args.dpi,
                                    "savefig.format": args.fmt,
                                    "savefig.transparent": bool(args.transparent)})
    except Exception:
        pass

    # Laisse le code existant agir; la plupart des fichiers exécutent du code top-level.
    # Si une fonction main(...) est fournie, tu peux la dé-commenter :
    # rc = main(args) if "main" in globals() else 0
    rc = 0
    sys.exit(rc)


# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os
    import sys
    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
except Exception:
    def _mcgt_postparse_apply(*_a, **_k):
        pass
try:
    if "args" in globals():
        _mcgt_postparse_apply(args, caller_file=__file__)
except Exception:
    pass



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

