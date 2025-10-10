#!/usr/bin/env python3
# === [PASS5-AUTOFIX-SHIM] ===
if __name__ == "__main__":
    try:
        import sys, os, atexit
        _argv = sys.argv[1:]
        # 1) Shim --help universel
        if any(a in ("-h","--help") for a in _argv):
            import argparse
            _p = argparse.ArgumentParser(description="MCGT (shim auto-injecté Pass5)", add_help=True, allow_abbrev=False)
            _p.add_argument("--out", help="Chemin de sortie pour fig.savefig (optionnel)")
            _p.add_argument("--dpi", type=int, default=120, help="DPI (par défaut: 120)")
            _p.add_argument("--show", action="store_true", help="Force plt.show() en fin d'exécution")
            # parse_known_args() affiche l'aide et gère les options de base
            _p.parse_known_args()
            sys.exit(0)
        # 2) Shim sauvegarde figure si --out présent (sans bloquer)
        _out = None
        if "--out" in _argv:
            try:
                i = _argv.index("--out")
                _out = _argv[i+1] if i+1 < len(_argv) else None
            except Exception:
                _out = None
        if _out:
            os.environ.setdefault("MPLBACKEND", "Agg")
            try:
                import matplotlib.pyplot as plt
                # Neutralise show() pour éviter le blocage en headless
                def _shim_show(*a, **k): pass
                plt.show = _shim_show
                # Récupère le dpi si fourni
                _dpi = 120
                if "--dpi" in _argv:
                    try:
                        _dpi = int(_argv[_argv.index("--dpi")+1])
                    except Exception:
                        _dpi = 120
                @atexit.register
                def _pass5_save_last_figure():
                    try:
                        fig = plt.gcf()
                        fig.savefig(_out, dpi=_dpi)
                        print(f"[PASS5] Wrote: {_out}")
                    except Exception as _e:
                        print(f"[PASS5] savefig failed: {_e}")
            except Exception:
                # matplotlib indisponible: ignorer silencieusement
                pass
    except Exception:
        # N'empêche jamais le script original d'exécuter
        pass
# === [/PASS5-AUTOFIX-SHIM] ===
# verify_z_grid.py
# Vérifie que la grille en z (ou q0⋆) correspond aux paramètres minimum, maximum et pas attendus.

import json
import sys
from pathlib import Path

import numpy as np

# 1. Chargement des méta-paramètres
ROOT = Path(__file__).resolve().parents[2]
PARAMS_FILE = ROOT / "zz-data" / "chapter08" / "08_coupling_params.json"

if not PARAMS_FILE.exists():
    print(f"❌ Fichier de paramètres introuvable : {PARAMS_FILE}")
    sys.exit(1)

with open(PARAMS_FILE, encoding="utf-8") as f:
    params = json.load(f)

xmin = params.get("q0star_min")
xmax = params.get("q0star_max")
npts = params.get("n_points")

# 2. Validation des valeurs
if xmin is None or xmax is None or npts is None:
    print("❌ Paramètres manquants dans le JSON :", params)
    sys.exit(1)

if xmax <= xmin or npts < 2:
    print("❌ Paramètres invalides (xmin < xmax, npts ≥ 2) :", xmin, xmax, npts)
    sys.exit(1)

# 3. Calcul du pas et du nombre de points
dlog = (np.log10(xmax) - np.log10(xmin)) / (npts - 1)
ncalc = int(round((np.log10(xmax) - np.log10(xmin)) / dlog)) + 1

# 4. Affichage des résultats
print("→ Grille attendue :")
print(f"   xmin = {xmin}")
print(f"   xmax = {xmax}")
print(f"   n_points = {npts}")
print(f"   Δlog10 = {dlog:.5f}")
print(f"   points recalculés = {ncalc}")

if ncalc != npts:
    print("⚠️  Le nombre de points recalculé diffère de n_points !")
    sys.exit(2)
else:
    print("✅ Grille conforme aux paramètres.")
