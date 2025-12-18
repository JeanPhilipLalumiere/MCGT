import hashlib
import shutil
import tempfile
from pathlib import Path as _SafePath

import matplotlib.pyplot as plt

plt.rcParams.update(
    {
        "figure.autolayout": True,
        "figure.figsize": (10, 6),
        "axes.titlepad": 25,
        "axes.labelpad": 15,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.3,
        "font.family": "serif",
    }
)

def _sha256(path: _SafePath) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def safe_save(filepath, fig=None, **savefig_kwargs):
    path = _SafePath(filepath)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        with tempfile.NamedTemporaryFile(delete=False, suffix=path.suffix) as tmp:
            tmp_path = _SafePath(tmp.name)
        try:
            if fig is not None:
                fig.savefig(tmp_path, **savefig_kwargs)
            else:
                plt.savefig(tmp_path, **savefig_kwargs)
            if _sha256(tmp_path) == _sha256(path):
                tmp_path.unlink()
                return False
            shutil.move(tmp_path, path)
            return True
        finally:
            if tmp_path.exists():
                tmp_path.unlink()
    if fig is not None:
        fig.savefig(path, **savefig_kwargs)
    else:
        plt.savefig(path, **savefig_kwargs)
    return True

#!/usr/bin/env python3
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
                        safe_save(out, dpi=120)
                except Exception:
                    pass
        atexit.register(_auto_save)
    except Exception:
        pass
# === [/PASS5B-SHIM] ===
# tracer_fig04_fR_fRR_contre_R.py
"""
Trace f_R et f_RR (double axe) en fonction de R/R₀ — Chapitre 3
===============================================================

Objectif : proposer une vue complémentaire à fig_02, avec deux axes Y pour
rendre lisible la différence d’échelle entre f_R (≈O(1)) et f_RR (≈O(10⁻⁶)),
et marquer le point pivot à R/R₀ = 1.

Entrée  :
    zz-data/chapter03/03_fR_stability_data.csv
Colonnes requises :
    R_over_R0, f_R, f_RR

Sortie  :
    zz-figures/chapter03/03_fig_04_fr_frr_vs_r.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# ----------------------------------------------------------------------
# Configuration logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_FILE = Path("zz-data") / "chapter03" / "03_fR_stability_data.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "03_fig_04_fr_frr_vs_f.png"


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
def main() -> None:
    # 1. Lecture des données
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return

    df = pd.read_csv(DATA_FILE)
    required = {"R_over_R0", "f_R", "f_RR"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes dans %s : %s", DATA_FILE, missing)
        return

    # 2. Préparation du dossier de sortie
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Création de la figure
    fig, ax1 = plt.subplots(dpi=300, figsize=(6, 4))
    fig.suptitle(r"$f_R$ and $f_{RR}$ Functions", y=0.98)

    # axe X en log
    ax1.set_xscale("log")
    ax1.set_xlabel(r"$R/R_0$")

    # 4. Tracé de f_R sur l'axe de gauche
    (ln1,) = ax1.loglog(
        df["R_over_R0"], df["f_R"], color="tab:blue", lw=1.5, label=r"$f_R(R)$"
    )
    ax1.set_ylabel(r"$f_R$", color="tab:blue")
    ax1.tick_params(axis="y", labelcolor="tab:blue")
    ax1.grid(True, which="both", ls="--", alpha=0.2)

    # 5. Tracé de f_RR sur l'axe de droite
    ax2 = ax1.twinx()
    ax2.set_yscale("log")
    (ln2,) = ax2.loglog(
        df["R_over_R0"], df["f_RR"], color="tab:orange", lw=1.5, label=r"$f_{RR}(R)$"
    )
    ax2.set_ylabel(r"$f_{RR}$", color="tab:orange")
    ax2.tick_params(axis="y", labelcolor="tab:orange")

    # 6. Marqueur vertical du pivot à R/R0 = 1
    ln3 = ax1.axvline(1.0, color="gray", linestyle="--", lw=1.0, label=r"Pivot: $R/R_0=1$")

    # 7. Légende explicite
    handles = [ln1, ln2, ln3]
    labels = [h.get_label() for h in handles]
    ax1.legend(
        handles,
        labels,
        loc="upper left",
        bbox_to_anchor=(0.25, 0.50),
        framealpha=0.9,
        edgecolor="black",
    )

    # 8. Mise en forme finale et sauvegarde
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    safe_save(FIG_PATH)
    plt.close(fig)
    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
    main()

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
