#!/usr/bin/env python3
"""
plot_fig06_comparison.py — STUB TEMPORAIRE (homogénisation CLI)
- Objectif: rendre --help et un rendu rapide (--out) 100% sûrs et non-bloquants.
- L'implémentation scientifique complète est conservée dans plot_fig06_comparison.py.bak
  et sera réintégrée après normalisation (parser/main-guard/fonctions pures).
"""

from __future__ import annotations

import argparse
import os

# Forcer backend non interactif le plus tôt possible
os.environ.setdefault("MPLBACKEND", "Agg")

import matplotlib.pyplot as plt  # import après MPLBACKEND

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Figure 6 (stub temporaire, CLI homogène et sûre)."
    )
    p.add_argument("--results", help="Chemin CSV/NPY optionnel (ignoré par le stub).")
    p.add_argument("--out", help="PNG/PDF de sortie (facultatif).")
    p.add_argument("--dpi", type=int, default=120, help="Résolution figure (par défaut: 120).")
    p.add_argument("--title", default="Figure 6 — stub CLI", help="Titre visuel temporaire.")
    return p

def main() -> None:
    args = build_parser().parse_args()

    fig, ax = plt.subplots(figsize=(6.5, 4.0))
    ax.text(0.5, 0.55, args.title, ha="center", va="center", fontsize=12)
    ax.text(0.5, 0.40, "(stub temporaire — pipeline désactivé)", ha="center", va="center", fontsize=9)
    ax.set_axis_off()

    # Remplace tight_layout par subplots_adjust
    fig.subplots_adjust(left=0.06, right=0.98, top=0.92, bottom=0.12)

    if args.out:
        fig.savefig(args.out, dpi=args.dpi)
        print(f"Wrote: {args.out}")
    else:
        # Pas de show() en mode homogénéisation/CI
        print("No --out provided; stub generated but not saved.")

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

