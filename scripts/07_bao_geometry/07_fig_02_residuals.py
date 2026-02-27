#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import logging
import sys
import tempfile
from pathlib import Path as _SafePath
from pathlib import Path
from typing import Optional

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

plt.rcParams["text.usetex"] = False
plt.rcParams["font.family"] = "serif"
plt.rcParams["pdf.fonttype"] = 42
plt.rcParams["ps.fonttype"] = 42

plt.rcParams.update(
    {
        "figure.autolayout": True,
        "figure.figsize": (8, 5),
        "axes.titlepad": 15,
        "axes.labelpad": 10,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.3,
        "font.family": "serif",
    }
)

ROOT = Path(__file__).resolve().parents[2]
COSMO_DIR = ROOT / "scripts" / "08_sound_horizon" / "utils"
sys.path.insert(0, str(COSMO_DIR))
try:
    from cosmo import distance_modulus  # type: ignore
except Exception as exc:  # pragma: no cover - import guard for CLI usage
    raise SystemExit(f"Unable to import cosmo.distance_modulus: {exc}") from exc


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


def setup_logging(verbose: int = 0) -> None:
    if verbose >= 2:
        level = logging.DEBUG
    elif verbose == 1:
        level = logging.INFO
    else:
        level = logging.WARNING
    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")


def detect_project_root() -> Path:
    try:
        return Path(__file__).resolve().parents[2]
    except NameError:
        return Path.cwd()


def plot_hubble_residuals(
    *,
    pantheon_csv: Path,
    chi2_csv: Path,
    out_png: Path,
    dpi: int = 300,
) -> None:
    if not pantheon_csv.exists():
        raise FileNotFoundError(f"Pantheon+ CSV missing: {pantheon_csv}")
    if not chi2_csv.exists():
        raise FileNotFoundError(f"Chi2 scan CSV missing: {chi2_csv}")

    pant = pd.read_csv(pantheon_csv, encoding="utf-8")
    chi2 = pd.read_csv(chi2_csv, encoding="utf-8")

    for col in ("z", "mu_obs", "sigma_mu"):
        if col not in pant.columns:
            raise ValueError(f"Missing column '{col}' in {pantheon_csv}")
    for col in ("q0star", "chi2_total"):
        if col not in chi2.columns:
            raise ValueError(f"Missing column '{col}' in {chi2_csv}")

    q0_best = chi2.loc[chi2["chi2_total"].idxmin(), "q0star"]
    logging.info("Best-fit q0star = %.6f", q0_best)

    z = pant["z"].to_numpy(dtype=float)
    mu_obs = pant["mu_obs"].to_numpy(dtype=float)
    sigma_mu = pant["sigma_mu"].to_numpy(dtype=float)

    mu_lcdm = np.array([distance_modulus(zv, 0.0) for zv in z])
    mu_mcgt = np.array([distance_modulus(zv, float(q0_best)) for zv in z])

    resid_data = mu_obs - mu_lcdm
    resid_mcgt = mu_mcgt - mu_lcdm

    order = np.argsort(z)
    z_sorted = z[order]
    resid_mcgt_sorted = resid_mcgt[order]

    fig, ax = plt.subplots(figsize=(8, 5), dpi=dpi)
    ax.set_xscale("log")
    ax.axhline(0.0, color="0.2", lw=1.5, label=r"$\Lambda$CDM reference")
    ax.errorbar(
        z,
        resid_data,
        yerr=sigma_mu,
        fmt="o",
        color="black",
        ecolor="black",
        markersize=3,
        alpha=0.6,
        linestyle="none",
        label="Pantheon+ Data",
    )
    ax.plot(z_sorted, resid_mcgt_sorted, color="tab:blue", lw=2.5, label="MCGT (best-fit)")

    bins = np.linspace(0.0, 2.3, 15)
    bin_centers = 0.5 * (bins[:-1] + bins[1:])
    binned_mean = []
    binned_err = []
    binned_centers = []
    for left, right, center in zip(bins[:-1], bins[1:], bin_centers):
        mask = (z >= left) & (z < right) & np.isfinite(resid_data) & np.isfinite(sigma_mu)
        if not np.any(mask):
            continue
        weights = 1.0 / np.square(sigma_mu[mask])
        weighted_mean = np.sum(weights * resid_data[mask]) / np.sum(weights)
        weighted_err = np.sqrt(1.0 / np.sum(weights))
        binned_centers.append(center)
        binned_mean.append(weighted_mean)
        binned_err.append(weighted_err)
    if binned_centers:
        ax.errorbar(
            binned_centers,
            binned_mean,
            yerr=binned_err,
            fmt="o",
            color="red",
            ecolor="red",
            markersize=10,
            elinewidth=2,
            capsize=3,
            label="Binned Average",
            zorder=99,
        )

    ax.set_xlabel(r"Redshift $z$")
    ax.set_ylabel(r"Residuals $\mu_{obs} - \mu_{\Lambda CDM}$ (mag)")
    ax.set_title("Pantheon+ Hubble Residuals vs Redshift")
    ax.legend(frameon=False)
    ax.grid(True, which="both", alpha=0.25)

    resid_low = np.nanmin(resid_data - sigma_mu)
    resid_high = np.nanmax(resid_data + sigma_mu)
    mcgt_low = np.nanmin(resid_mcgt)
    mcgt_high = np.nanmax(resid_mcgt)
    y_min = min(resid_low, mcgt_low)
    y_max = max(resid_high, mcgt_high)
    if np.isfinite(y_min) and np.isfinite(y_max) and y_max > y_min:
        pad = 0.08 * (y_max - y_min)
        ax.set_ylim(y_min - pad, y_max + pad)

    fig.tight_layout()
    safe_save(out_png, dpi=dpi)
    plt.close(fig)
    logging.info("Figure saved: %s", out_png)


def build_arg_parser() -> argparse.ArgumentParser:
    racine = detect_project_root()
    default_pantheon = (
        racine / "assets/zz-data/08_sound_horizon/08_pantheon_data.csv"
    )
    default_chi2 = racine / "assets/zz-data/08_sound_horizon/08_chi2_total_vs_q0.csv"
    default_out = (
        racine / "assets/zz-figures/07_bao_geometry/07_fig_02_residuals.png"
    )

    p = argparse.ArgumentParser(
        description=(
            "Figure 02 – Diagramme de Hubble des résidus (Pantheon+). "
            "Trace Δμ vs z avec la courbe MCGT best-fit."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--pantheon-csv",
        default=str(default_pantheon),
        help="Pantheon+ CSV (z, mu_obs, sigma_mu).",
    )
    p.add_argument(
        "--chi2-csv",
        default=str(default_chi2),
        help="Scan chi2 vs q0star (best-fit selection).",
    )
    p.add_argument(
        "--out",
        default=str(default_out),
        help="Chemin de sortie pour la figure PNG.",
    )
    p.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="Resolution de la figure.",
    )
    p.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity cumulable (-v, -vv).",
    )
    return p


def main(argv: Optional[list[str]] = None) -> None:
    parser = build_arg_parser()
    args = parser.parse_args(argv)
    setup_logging(args.verbose)

    plot_hubble_residuals(
        pantheon_csv=Path(args.pantheon_csv),
        chi2_csv=Path(args.chi2_csv),
        out_png=Path(args.out),
        dpi=args.dpi,
    )


if __name__ == "__main__":
    main()
