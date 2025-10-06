# zz-scripts/chapter05/tracer_fig01_schema_reactions_bbn.py
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


def draw_bbn_schema(
    save_path="zz-figures/chapter05/05_fig_01_bbn_reaction_network.png",
):
    fig, ax = plt.subplots(figsize=(8, 4.2), facecolor="white")

    # Centres des boîtes (x, y)
    P = {
        "n": np.array((0.07, 0.58)),
        "p": np.array((0.07, 0.38)),
        "D": np.array((0.34, 0.48)),
        "T": np.array((0.56, 0.74)),
        "He3": np.array((0.56, 0.22)),
        "He4": np.array((0.90, 0.48)),
    }

    dx = 0.04  # décalage horizontal flèches ←→ boîtes (légèrement augmenté)
    # padding interne des boîtes (boîtes « n », « p » plus larges)
    pad_box = 0.65

    # Dessin des boîtes
    for lab, pos in P.items():
        ax.text(
            *pos,
            lab,
            fontsize=14,
            ha="center",
            va="center",
            bbox=dict(
                boxstyle=f"round,pad={pad_box}",
                fc="lightgray",
                ec="gray"),
         )

    # Fonction utilitaire pour tracer une flèche décalée
    def arrow(src, dst):
        x0, y0 = P[src]
        x1, y1 = P[dst]
        start = (x0 + dx, y0) if x1 > x0 else (x0 - dx, y0)
        end = (x1 - dx, y1) if x1 > x0 else (x1 + dx, y1)
        ax.annotate(
            "",
            xy=end,
            xytext=start,
            arrowprops=dict(
                arrowstyle="->",
                lw=2))

    # Flèches du réseau BBN
    arrow("n", "D")
    arrow("p", "D")
    arrow("D", "T")
    arrow("D", "He3")
    arrow("T", "He4")
    arrow("He3", "He4")

    # Titre rapproché
    ax.set_title(
        "Schéma des réactions de la nucléosynthèse primordiale",
        fontsize=14,
        pad=6 )

    ax.axis("off")
    plt.tight_layout(pad=0.5)
    Path(save_path).parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(save_path, dpi=300)
    plt.close()


if __name__ == "__main__":
    draw_bbn_schema()

# [MCGT POSTPARSE EPILOGUE v1]
try:
    # On n agit que si un objet args existe au global
    if "args" in globals():
        import os
        import atexit
        # 1) Fallback via MCGT_OUTDIR si outdir est vide/None
        env_out = os.environ.get("MCGT_OUTDIR")
        if getattr(args, "outdir", None) in (None, "", False) and env_out:
            args.outdir = env_out
        # 2) Création sûre du répertoire s il est défini
        if getattr(args, "outdir", None):
            try:
                os.makedirs(args.outdir, exist_ok=True)
            except Exception:
                pass
        # 3) rcParams savefig si des attributs existent
        try:
            import matplotlib
            _rc = {}
            if hasattr(args, "dpi") and args.dpi:
                _rc["savefig.dpi"] = args.dpi
            if hasattr(args, "fmt") and args.fmt:
                _rc["savefig.format"] = args.fmt
            if hasattr(args, "transparent"):
                _rc["savefig.transparent"] = bool(args.transparent)
            if _rc:
                matplotlib.rcParams.update(_rc)
        except Exception:
            pass
        # 4) Copier automatiquement le dernier PNG vers outdir à la fin

        def _smoke_copy_latest():
            try:
                if not getattr(args, "outdir", None):
                    return
                import glob
                import os
                import shutil
                _ch = os.path.basename(os.path.dirname(__file__))
                _repo = os.path.abspath(
                    os.path.join(
                        os.path.dirname(__file__),
                        "..",
                        ".."))
                _default_dir = os.path.join(_repo, "zz-figures", _ch)
                pngs = sorted(
                    glob.glob(os.path.join(_default_dir, "*.png")),
                    key=os.path.getmtime,
                    reverse=True,
                )
                for _p in pngs:
                    if os.path.exists(_p):
                        _dst = os.path.join(args.outdir, os.path.basename(_p))
                        if not os.path.exists(_dst):
                            shutil.copy2(_p, _dst)
                        break
            except Exception:
                pass
        atexit.register(_smoke_copy_latest)
except Exception:
    # épilogue best-effort — ne doit jamais casser le script principal
    pass
