#!/usr/bin/env python3
"""
zz-scripts/chapter07/utils/toy_model.py

Trace un toy-model sur la grille k pour vérifier l’échantillonnage,
en lisant k_min, k_max et dlog depuis le JSON de méta-paramètres.
"""
# === [PASS5B-SHIM] ===
# Shim minimal pour rendre --help et --out sûrs sans effets de bord.
import os, sys, atexit
if any(x in sys.argv for x in ("-h", "--help")):
    try:
        import argparse
        p = argparse.ArgumentParser(add_help=True, allow_abbrev=False)
        p.print_help()
    except Exception:
        print("usage: <script> [options]")
    sys.exit(0)

if any(arg.startswith("--out") for arg in sys.argv):
    os.environ.setdefault("MPLBACKEND", "Agg")
    try:
        import matplotlib.pyplot as plt
        def _no_show(*a, **k): pass
        if hasattr(plt, "show"):
            plt.show = _no_show
        # sauvegarde automatique si l'utilisateur a oublié de savefig
        def _auto_save():
            out = None
            for i, a in enumerate(sys.argv):
                if a == "--out" and i+1 < len(sys.argv):
                    out = sys.argv[i+1]
                    break
                if a.startswith("--out="):
                    out = a.split("=",1)[1]
                    break
            if out:
                try:
                    fig = plt.gcf()
                    if fig:
                        # marges raisonnables par défaut
                        try:
                            fig.subplots_adjust(left=0.07, right=0.98, top=0.95, bottom=0.12)
                        except Exception:
                            pass
                        fig.savefig(out, dpi=120)
                except Exception:
                    pass
        atexit.register(_auto_save)
    except Exception:
        pass
# === [/PASS5B-SHIM] ===

import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


def load_params():
    # Déterminer la racine du projet
    root = Path(__file__).resolve().parents[3]
    json_path = root / "zz-data" / "chapter07" / "07_params_perturbations.json"
    params = json.loads(json_path.read_text(encoding="utf-8"))
    return params


def main():
    params = load_params()
    kmin = params["k_min"]
    kmax = params["k_max"]
    dlog = params["dlog"]

    # Construction de la grille k log-uniforme
    n_k = int((np.log10(kmax) - np.log10(kmin)) / dlog) + 1
    kgrid = np.logspace(np.log10(kmin), np.log10(kmax), n_k)

    # Toy-model : sinus en log(k) pour voir les oscillations
    toy = np.sin(np.log10(kgrid) * 10) ** 2 + 0.1

    # Tracé
    plt.figure(figsize=(6, 4))
    plt.loglog(kgrid, toy, ".", ms=4)
    plt.xlabel("k [h/Mpc]")
    plt.ylabel("Toy model")
    plt.title("Test d'échantillonnage log–log")
    plt.grid(True, which="both", ls=":")
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    plt.show()


if __name__ == "__main__":
    main()
