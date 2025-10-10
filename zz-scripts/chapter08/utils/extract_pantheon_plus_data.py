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
# Script : extract_pantheon_plus_data.py
# Source des données brutes Pantheon+ SH0ES :
# https://raw.githubusercontent.com/PantheonPlusSH0ES/DataRelease/
#   main/Pantheon+_Data/4_DISTANCES_AND_COVAR/Pantheon+SH0ES.dat

import os

import pandas as pd

# Chemins relatifs depuis ce script
DATA_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../../zz-data/chapter08")
)

# Fichier brut Pantheon+SH0ES (sans caractères spéciaux dans le nom)
input_file = os.path.join(DATA_DIR, "pantheon_plus_sh0es.dat")
# Fichier CSV de sortie
output_file = os.path.join(DATA_DIR, "08_pantheon_data.csv")

# 1. Lecture du fichier brut
df = pd.read_csv(input_file, delim_whitespace=True, comment="#")

# 2. Sélection et renommage des colonnes
df_out = df[["zHD", "MU_SH0ES", "MU_SH0ES_ERR_DIAG"]].rename(
    columns={"zHD": "z", "MU_SH0ES": "mu_obs", "MU_SH0ES_ERR_DIAG": "sigma_mu"}
)

# 3. Filtrer la plage 0 ≤ z ≤ 2.3
df_out = df_out[(df_out["z"] >= 0) & (df_out["z"] <= 2.3)]

# 4. Sauvegarde au format CSV UTF-8
df_out.to_csv(output_file, index=False, encoding="utf-8")

print(f"✅ 08_pantheon_data.csv généré dans : {output_file}")
