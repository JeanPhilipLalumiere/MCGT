import os

import matplotlib.colors as mcolors
import matplotlib.pyplot as plt
import pandas as pd

REPO_DATA_PATH = "assets/zz-data/10_global_scan/10_mc_results.agg.csv"
LEGACY_DATA_PATH = os.path.expanduser("~/Downloads/MCGT_Final_Results/10_mc_results.csv")
OUTPUT_DIR = "assets/zz-figures/10_global_scan/"
os.makedirs(OUTPUT_DIR, exist_ok=True)


def resolve_data_path() -> str:
    if os.path.exists(REPO_DATA_PATH):
        return REPO_DATA_PATH
    return LEGACY_DATA_PATH


def generate_heatmap():
    data_path = resolve_data_path()
    if not os.path.exists(data_path):
        print(f"Error: missing input file at {data_path}")
        return

    print("Loading the 100,000-sample global scan...")
    df = pd.read_csv(data_path)
    
    # Keep only converged simulations.
    df = df[df["status"] == "ok"]

    plt.figure(figsize=(12, 9))
    
    sc = plt.scatter(
        df["q0star"],
        df["alpha"],
        c=df["p95_20_300"],
        cmap="viridis_r",
        s=2,
        alpha=0.6,
        norm=mcolors.LogNorm(vmin=1e-5, vmax=1.0)
    )

    cbar = plt.colorbar(sc)
    cbar.set_label(r"Phase dephasing $p_{95}$ (rad) - log scale", fontsize=12)

    plt.axvline(
        x=0,
        color="black",
        linestyle="--",
        alpha=0.5,
        label=r"GR limit ($q_0^* = 0$)",
    )
    
    plt.annotate(
        "EXCLUSION ZONE (> 0.1 rad)",
        xy=(0.0006, 0.7),
        color="red",
        weight="bold",
        fontsize=10,
        bbox=dict(facecolor="white", alpha=0.7),
    )
    
    plt.annotate(
        "VIABLE ZONE (GR-like)",
        xy=(-0.0001, -0.7),
        color="darkgreen",
        weight="bold",
        fontsize=10,
        bbox=dict(facecolor="white", alpha=0.7),
    )

    plt.xlabel(r"MCGT parameter $q_0^*$", fontsize=13)
    plt.ylabel(r"Spectral index $\alpha$", fontsize=13)
    plt.title(
        f"Mapping of the MCGT validity domain\n(Global analysis of {len(df):,} simulations)",
        fontsize=15,
    )
    plt.grid(True, which="both", linestyle=":", alpha=0.4)

    save_path = os.path.join(OUTPUT_DIR, "10_survival_heatmap.png")
    plt.savefig(save_path, dpi=300, bbox_inches="tight")
    plt.close()
    
    print(f"Saved figure to {save_path}")

if __name__ == "__main__":
    generate_heatmap()
