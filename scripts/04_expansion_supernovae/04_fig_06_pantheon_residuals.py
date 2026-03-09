#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import os
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCAL_TEXMF = ROOT / "texmf" / "tex" / "latex" / "local"
LOCAL_MPLCONFIG = ROOT / ".mplconfig"
LOCAL_TEXMF.mkdir(parents=True, exist_ok=True)
LOCAL_MPLCONFIG.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("MPLCONFIGDIR", str(LOCAL_MPLCONFIG))
os.environ.setdefault("XDG_CACHE_HOME", str(LOCAL_MPLCONFIG))
os.environ.setdefault("TMPDIR", str(LOCAL_MPLCONFIG))
texinputs = os.environ.get("TEXINPUTS", "")
local_tex = str(LOCAL_TEXMF)
if local_tex not in texinputs.split(":"):
    os.environ["TEXINPUTS"] = f"{local_tex}:{texinputs}" if texinputs else f"{local_tex}:"

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd


if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts._common.style import apply_manuscript_defaults

DATA_CSV = (
    ROOT
    / "assets"
    / "zz-data"
    / "04_expansion_supernovae"
    / "04_pantheon_residuals.csv"
)
OUT_DIR = ROOT / "assets" / "zz-figures" / "04_expansion_supernovae"
OUT_STEM = "04_fig_06_pantheon_residuals"

apply_manuscript_defaults(usetex=True)

plt.rcParams.update(
    {
        "figure.figsize": (9.5, 7.0),
        "axes.titlepad": 20,
        "axes.labelpad": 10,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.15,
    }
)


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_save(path: Path, fig: plt.Figure, **kwargs) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        with tempfile.NamedTemporaryFile(delete=False, suffix=path.suffix) as tmp:
            tmp_path = Path(tmp.name)
        try:
            fig.savefig(tmp_path, **kwargs)
            if _sha256(tmp_path) == _sha256(path):
                tmp_path.unlink()
                return False
            shutil.move(tmp_path, path)
            return True
        finally:
            if tmp_path.exists():
                tmp_path.unlink()
    fig.savefig(path, **kwargs)
    return True


def render_figure() -> plt.Figure:
    df = pd.read_csv(DATA_CSV).sort_values("z")

    fig, (ax_top, ax_bottom) = plt.subplots(
        2,
        1,
        sharex=True,
        figsize=(9.5, 7.0),
        dpi=400,
        gridspec_kw={"height_ratios": [2.4, 1.3], "hspace": 0.06},
    )

    ax_top.errorbar(
        df["z"],
        df["mu_obs"],
        yerr=df["sigma_mu"],
        fmt="o",
        markersize=2.0,
        linewidth=0.5,
        alpha=0.18,
        color="#7a7a7a",
        ecolor="#b5b5b5",
        label="Pantheon+",
    )
    ax_top.plot(
        df["z"],
        df["mu_lcdm"],
        color="#1f4b99",
        linewidth=1.8,
        label=r"$\Lambda$CDM",
    )
    ax_top.plot(
        df["z"],
        df["mu_mcgt"],
        color="#c4512d",
        linewidth=2.2,
        label=r"$\Psi$TMG",
    )
    ax_top.fill_between(
        df["z"],
        df["mu_mcgt"],
        df["mu_lcdm"],
        where=df["mu_mcgt"] <= df["mu_lcdm"],
        color="#f0b88d",
        alpha=0.35,
    )
    ax_top.set_xscale("log")
    ax_top.set_ylabel(r"$\mu(z)$ [mag]")
    ax_top.set_title(r"Pantheon+ Hubble Residuals: lower luminosity distances in $\Psi$TMG")
    ax_top.grid(True, which="both", linestyle=":", linewidth=0.5, alpha=0.65)
    ax_top.legend(loc="upper left", frameon=False)
    ax_top.text(
        0.98,
        0.06,
        r"$\mu_{\Psi{\rm TMG}} < \mu_{\Lambda{\rm CDM}}$ on the full sample",
        transform=ax_top.transAxes,
        ha="right",
        va="bottom",
        fontsize=10,
        color="#7a3a22",
    )

    ax_bottom.axhline(0.0, color="black", linewidth=1.0, linestyle="--")
    ax_bottom.plot(
        df["z"],
        df["delta_mu_vs_lcdm"],
        color="#c4512d",
        linewidth=2.0,
        label=r"$\Delta\mu = \mu_{\Psi{\rm TMG}} - \mu_{\Lambda{\rm CDM}}$",
    )
    ax_bottom.fill_between(
        df["z"],
        df["delta_mu_vs_lcdm"],
        0.0,
        color="#f0b88d",
        alpha=0.35,
    )
    ax_bottom.set_xscale("log")
    ax_bottom.set_xlabel("Redshift $z$")
    ax_bottom.set_ylabel(r"$\Delta\mu$ [mag]")
    ax_bottom.grid(True, which="both", linestyle=":", linewidth=0.5, alpha=0.65)
    ax_bottom.legend(loc="lower left", frameon=False)

    return fig


def main(formats: tuple[str, ...] = ("png", "pdf", "svg")) -> None:
    fig = render_figure()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for fmt in formats:
        out_path = OUT_DIR / f"{OUT_STEM}.{fmt}"
        save_kwargs = {"format": fmt}
        if fmt == "png":
            save_kwargs["dpi"] = 400
        safe_save(out_path, fig, **save_kwargs)
        print(f"Saved figure -> {out_path}")
    plt.close(fig)


if __name__ == "__main__":
    requested_formats = tuple(
        os.environ.get("MCGT_FIG_FORMATS", "png,pdf,svg").replace(" ", "").split(",")
    )
    main(tuple(fmt for fmt in requested_formats if fmt))
