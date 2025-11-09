import argparse
from _common import cli as C
#!/usr/bin/env python3
# fichier : zz-scripts/chapter08/utils/coupling_example_model.py
# répertoire : zz-scripts/chapter08/utils
# toy_model_couplage.py
# Génère un toy-model pour tester l’interpolation PCHIP en log-log

import os
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import PchipInterpolator

# 1. Points de référence (coarse grid)
z_ref = np.logspace(-2, 0, 6)  # de 0.01 à 1.0
y_ref = z_ref**1.5  # toy-fonction y = z^1.5

# 2. Grille fine pour interpolation
z_fine = np.logspace(np.log10(z_ref.min()), np.log10(z_ref.max()), 200)

# 3. Constructeur PCHIP log-log
interp = PchipInterpolator(np.log10(z_ref), np.log10(y_ref), extrapolate=True)
y_interp = 10 ** interp(np.log10(z_fine))

# 4. Préparation du dossier de sortie
ROOT = Path(__file__).resolve().parents[2]
FIG_DIR = ROOT / "zz-figures" / "chapter08"
os.makedirs(FIG_DIR, exist_ok=True)
out_png = FIG_DIR / "fig_00_toy_model_coupling.png"

# 5. Tracé
plt.figure(figsize=(6.5, 4.5))
plt.loglog(z_ref, y_ref, "o", label="Points de référence")
plt.loglog(z_fine, y_interp, "-", label="Interpolation PCHIP")
plt.xlabel("z")
plt.ylabel("y = z^1.5")
plt.title("Toy-model : test interpolation log–log")
plt.grid(True, which="both", ls=":", lw=0.5, alpha=0.7)
plt.legend()
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
# [autofix] toplevel plt.savefig(...) neutralisé — utiliser C.finalize_plot_from_args(args)
print(f"✅ Toy-model enregistré sous : {out_png}")
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",,)
    C.add_common_plot_args(p)
    return p
def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    # TODO: insère la logique de la figure si nécessaire
    C.finalize_plot_from_args(args)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
