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
# Script   : extract_bao_data.py
# Objectif : extraire et formater les données BAO pour le Chapitre 8
# Source   : https://raw.githubusercontent.com/SDSS-Science-Archive-Server/BOSS-LSS/
#            master/lss/BAOtables/bao_distances_DR12v5.dat

import os

import pandas as pd

# 1. Définition des chemins
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "../../../zz-data/chapter08"))
os.makedirs(DATA_DIR, exist_ok=True)

input_file = os.path.join(DATA_DIR, "bao_distances_DR12v5.dat")
output_file = os.path.join(DATA_DIR, "08_bao_data.csv")

# 2. Lecture du fichier brut BAO
df = pd.read_csv(input_file, delim_whitespace=True, comment="#")

# 3. Sélection et renommage des colonnes
#    - 'z'        : redshift
#    - 'DV'       : distance de diffusion baryonique
#    - 'sigma_DV' : incertitude absolue de DV
df_out = df[["z", "DV", "sigma_DV"]].rename(
    columns={"DV": "DV_obs", "sigma_DV": "sigma_DV"}
)


# 4. Classification des jalons (primaire / ordre2)
def classify(row):
    frac = row["sigma_DV"] / row["DV_obs"] if row["DV_obs"] != 0 else float("inf")
    return "primaire" if frac <= 0.01 else "ordre2"


df_out["classe"] = df_out.apply(classify, axis=1)

# 5. (Optionnel) Filtrer la plage de redshift
# df_out = df_out[(df_out['z'] >= 0.1) & (df_out['z'] <= 2.5)]

# 6. Sauvegarde au format CSV UTF-8
df_out.to_csv(output_file, index=False, encoding="utf-8")

print(f"✅ 08_bao_data.csv généré dans : {output_file}")
