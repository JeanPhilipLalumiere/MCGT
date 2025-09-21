# zz-scripts/chapter05/tracer_fig01_schema_reactions_bbn.py
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

def draw_bbn_schema(save_path="zz-figures/chapter05/fig_01_bbn_reaction_network.png"):
    fig, ax = plt.subplots(figsize=(8, 4.2), facecolor="white")

    # Centres des boîtes (x, y)
    P = {
        "n":   np.array((0.07, 0.58)),
        "p":   np.array((0.07, 0.38)),
        "D":   np.array((0.34, 0.48)),
        "T":   np.array((0.56, 0.74)),
        "He3": np.array((0.56, 0.22)),
        "He4": np.array((0.90, 0.48))
    }

    dx       = 0.04   # décalage horizontal flèches ←→ boîtes (légèrement augmenté)
    pad_box  = 0.65    # padding interne des boîtes (boîtes « n », « p » plus larges)

    # Dessin des boîtes
    for lab, pos in P.items():
        ax.text(*pos, lab,
                fontsize=14, ha="center", va="center",
                bbox=dict(boxstyle=f"round,pad={pad_box}",
                          fc="lightgray", ec="gray"))

    # Fonction utilitaire pour tracer une flèche décalée
    def arrow(src, dst):
        x0, y0 = P[src]
        x1, y1 = P[dst]
        start = (x0 + dx, y0) if x1 > x0 else (x0 - dx, y0)
        end   = (x1 - dx, y1) if x1 > x0 else (x1 + dx, y1)
        ax.annotate("", xy=end, xytext=start,
                    arrowprops=dict(arrowstyle="->", lw=2))

    # Flèches du réseau BBN
    arrow("n",   "D")
    arrow("p",   "D")
    arrow("D",   "T")
    arrow("D",   "He3")
    arrow("T",   "He4")
    arrow("He3", "He4")

    # Titre rapproché
    ax.set_title("Schéma des réactions de la nucléosynthèse primordiale",
                 fontsize=14, pad=6)

    ax.axis("off")
    plt.tight_layout(pad=0.5)
    Path(save_path).parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(save_path, dpi=300)
    plt.close()

if __name__ == "__main__":
    draw_bbn_schema()
