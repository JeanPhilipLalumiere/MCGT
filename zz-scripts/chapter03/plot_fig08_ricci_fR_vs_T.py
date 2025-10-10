import sys, os, atexit
import glob
_argv = sys.argv[1:]
        # 1 Shim --help universel
if any(a in ("-h","--help") for a in _argv):
    pass
import argparse
_p = argparse.ArgumentParser(description="MCGT (shim auto-injecté Pass5)", add_help=True, allow_abbrev=False)
_p.add_argument("--out", help="Chemin de sortie pour fig.savefig (optionnel)")
_p.add_argument("--dpi", type=int, default=120, help="DPI (par défaut: 120)")
_p.add_argument("--show", help="Force plt.show() en fin d'exécution")
            # parse_known_args() affiche l'aide et gère les options de base
_p.parse_known_args()
sys.exit(0)
        # 2 Shim sauvegarde figure si --out présent (sans bloquer)
_out = None
if "--out" in _argv:
    pass
try:
    i = _argv.index("--out")
    _out = _argv[i+1] if i+1 < len(_argv) else None
except Exception:
    pass
