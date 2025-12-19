#!/usr/bin/env python3
from __future__ import annotations

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
"""Fig. 06 — Comparaison des invariants et dérivées (Chapitre 7).

Trace trois panneaux en k :

1. I1(k) (invariant scalaire)
2. |∂ₖ c_s²(k)|
3. |∂ₖ(δφ/φ)(k)|

Tous en échelle log-log, avec repère k_split issu de 07_meta_perturbations.json.
"""

import argparse
import json
import logging
from pathlib import Path
from typing import Optional, Sequence, List

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogLocator, FuncFormatter


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def setup_logging(verbose: int = 0) -> None:
    if verbose >= 2:
        level = logging.DEBUG
    elif verbose == 1:
        level = logging.INFO
    else:
        level = logging.WARNING
    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")


def detect_value_column(
    df: pd.DataFrame,
    explicit: Optional[str],
    preferred: Sequence[str],
) -> str:
    """Choisit une colonne numérique pour un tracé 1D (k, valeur).

    Priorité :
    1) `explicit` si fournie et présente
    2) première colonne trouvée dans `preferred`
    3) s'il n'y a qu'une seule colonne numérique (hors 'k'), on la prend
    """
    cols = list(df.columns)

    if explicit:
        if explicit in df.columns:
            logging.info("Colonne explicite utilisée : %s", explicit)
            return explicit
        else:
            raise KeyError(
                f"Colonne explicite '{explicit}' absente. Colonnes disponibles : {cols}"
            )

    for name in preferred:
        if name in df.columns:
            logging.info("Colonne détectée automatiquement : %s", name)
            return name

    numeric_candidates: List[str] = []
    for c in df.columns:
        if c == "k":
            continue
        if np.issubdtype(df[c].dtype, np.number):
            numeric_candidates.append(c)

    if len(numeric_candidates) == 1:
        logging.info("Colonne numérique unique sélectionnée : %s", numeric_candidates[0])
        return numeric_candidates[0]

    raise RuntimeError(
        "Impossible de déterminer la colonne à tracer. "
        f"Colonnes : {cols}"
    )


def format_pow10(x: float, pos: int) -> str:
    if x <= 0 or not np.isfinite(x):
        return ""
    power = int(np.round(np.log10(x)))
    return rf"$10^{{{power}}}$"


def auto_log_limits(values: np.ndarray) -> tuple[float, float]:
    mask = np.isfinite(values) & (values > 0)
    if mask.sum() == 0:
        raise ValueError("Aucune valeur positive finie pour fixer les limites log.")
    v = values[mask]
    vmin = v.min()
    vmax = v.max()
    pmin = int(np.floor(np.log10(vmin)))
    pmax = int(np.ceil(np.log10(vmax)))
    return 10.0**pmin, 10.0**pmax


# ---------------------------------------------------------------------------
# Coeur du tracé
# ---------------------------------------------------------------------------


def plot_comparison(
    *,
    inv_csv: Path,
    dcs2_csv: Path,
    ddphi_csv: Path,
    meta_json: Path,
    inv_col: Optional[str],
    dcs2_col: Optional[str],
    ddphi_col: Optional[str],
    out_png: Path,
    dpi: int,
) -> None:
    logging.info("Début du tracé de la figure 06 – Comparaison I1 / dcs2/dk / d(δφ/φ)/dk")
    logging.info("CSV invariants : %s", inv_csv)
    logging.info("CSV dcs2       : %s", dcs2_csv)
    logging.info("CSV ddphi      : %s", ddphi_csv)
    logging.info("JSON méta      : %s", meta_json)
    logging.info("Figure out     : %s", out_png)

    # Méta
    if not meta_json.exists():
        raise FileNotFoundError(f"Méta-paramètres introuvables : {meta_json}")
    meta = json.loads(meta_json.read_text(encoding="utf-8"))
    k_split = float(meta.get("x_split", meta.get("k_split", 0.02)))
    logging.info("Lecture de k_split = %.2e [h/Mpc]", k_split)

    # Invariant I1
    col_inv = "i1_synth"
    if not inv_csv.exists():
        logging.warning("CSV invariants introuvable : %s ; génération d'un jeu synthétique.", inv_csv)
        k1 = np.logspace(-3, 0, 50)
        I1 = 1e-3 + 1e-3 * k1
    else:
        df_inv = pd.read_csv(inv_csv, comment="#")
        if "k" not in df_inv.columns:
            raise KeyError(f"Colonne 'k' absente de {inv_csv}")
        col_inv = detect_value_column(df_inv, inv_col, ["I1_cs2", "I1"])
        k1 = df_inv["k"].to_numpy()
        I1 = df_inv[col_inv].to_numpy()

    # dcs2/dk
    col_dcs2 = "dcs2_synth"
    if not dcs2_csv.exists():
        logging.warning("CSV dcs2 introuvable : %s ; génération d'un jeu synthétique.", dcs2_csv)
        k2 = np.logspace(-3, 0, 50)
        dcs2 = 5e-4 * k2
    else:
        df_dcs2 = pd.read_csv(dcs2_csv, comment="#")
        if "k" not in df_dcs2.columns:
            raise KeyError(f"Colonne 'k' absente de {dcs2_csv}")
        col_dcs2 = detect_value_column(df_dcs2, dcs2_col, ["d_cs2_dk", "dcs2_dk", "dcs2_vs_k"])
        k2 = df_dcs2["k"].to_numpy()
        dcs2 = np.abs(df_dcs2[col_dcs2].to_numpy())

    # d(δφ/φ)/dk
    col_ddp = "ddphi_synth"
    if not ddphi_csv.exists():
        logging.warning("CSV ddphi introuvable : %s ; génération d'un jeu synthétique.", ddphi_csv)
        k3 = np.logspace(-3, 0, 50)
        ddp = 2e-4 * k3
    else:
        df_ddp = pd.read_csv(ddphi_csv, comment="#")
        if "k" not in df_ddp.columns:
            raise KeyError(f"Colonne 'k' absente de {ddphi_csv}")
        col_ddp = detect_value_column(
            df_ddp,
            ddphi_col,
            ["d_delta_phi_dk", "ddelta_phi_dk", "ddelta_phi_vs_k"],
        )
        k3 = df_ddp["k"].to_numpy()
        ddp = np.abs(df_ddp[col_ddp].to_numpy())

    # Nettoyage / masques de base
    mask1 = np.isfinite(k1) & np.isfinite(I1) & (I1 > 0)
    mask2 = np.isfinite(k2) & np.isfinite(dcs2) & (dcs2 > 0)
    mask3 = np.isfinite(k3) & np.isfinite(ddp) & (ddp > 0)

    k1, I1 = k1[mask1], I1[mask1]
    k2, dcs2 = k2[mask2], dcs2[mask2]
    k3, ddp = k3[mask3], ddp[mask3]

    plt.style.use("classic")
    fig, axs = plt.subplots(3, 1, figsize=(8, 14), sharex=True)

    # 1) I1(k)
    ax = axs[0]
    ax.loglog(k1, I1, color="C0", lw=2, label=rf"$I_1(k)$ ({col_inv})")
    ax.axvline(k_split, ls="--", color="k", lw=1)
    ax.set_ylabel(r"$I_1(k)$")
    ax.set_title("Scalar invariant and derivatives (Chapter 7)")
    ax.grid(which="both", ls=":", lw=0.5)

    # 2) |∂ₖ c_s²|
    ax = axs[1]
    ax.loglog(k2, dcs2, color="C1", lw=2, label=rf"$|\partial_k c_s^2|$ ({col_dcs2})")
    ax.axvline(k_split, ls="--", color="k", lw=1)
    ax.set_ylabel(r"$|\partial_k c_s^2|$")
    ax.grid(which="both", ls=":", lw=0.5)

    # 3) |∂ₖ(δφ/φ)|
    ax = axs[2]
    ax.loglog(k3, ddp, color="C2", lw=2, label=rf"$|\partial_k(\delta\phi/\phi)|$ ({col_ddp})")
    ax.axvline(k_split, ls="--", color="k", lw=1)
    ax.set_ylabel(r"$|\partial_k(\delta\phi/\phi)|$")
    ax.set_xlabel(r"$k\,[h/\mathrm{Mpc}]$")
    ax.grid(which="both", ls=":", lw=0.5)

    # Limites X/Y globales
    k_all = np.concatenate([k1, k2, k3])
    k_mask = np.isfinite(k_all) & (k_all > 0)
    if k_mask.sum() == 0:
        raise ValueError("Aucune valeur positive pour k.")
    k_min = k_all[k_mask].min()
    k_max = k_all[k_mask].max()

    axs[-1].set_xlim(k_min, k_max)

    for ax in axs:
        ax.xaxis.set_major_locator(LogLocator(base=10))
        ax.xaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))
        ax.yaxis.set_major_locator(LogLocator(base=10))
        ax.yaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))
        ax.yaxis.set_major_formatter(FuncFormatter(format_pow10))
        ax.legend(loc="upper right", fontsize=8, framealpha=0.8)

    fig.subplots_adjust(top=0.93, bottom=0.07, left=0.12, right=0.97, hspace=0.30)

    out_png.parent.mkdir(parents=True, exist_ok=True)
    safe_save(out_png, dpi=dpi)
    plt.close(fig)

    logging.info("Figure sauvegardée : %s", out_png)
    logging.info("Tracé de la figure 06 terminé ✔")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Fig. 06 — Comparaison I1 / dcs2/dk / d(δφ/φ)/dk – Chapitre 7.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--inv-csv",
        default="zz-data/chapter07/07_scalar_invariants.csv",
        help="CSV de l'invariant I1(k).",
    )
    p.add_argument(
        "--dcs2-csv",
        default="zz-data/chapter07/07_dcs2_vs_k.csv",
        help="CSV pour la dérivée dcs2/dk.",
    )
    p.add_argument(
        "--ddphi-csv",
        default="zz-data/chapter07/07_ddelta_phi_vs_k.csv",
        help="CSV pour la dérivée d(δφ/φ)/dk.",
    )
    p.add_argument(
        "--meta-json",
        default="zz-data/chapter07/07_meta_perturbations.json",
        help="JSON méta contenant x_split/k_split.",
    )
    p.add_argument(
        "--out",
        default="zz-figures/chapter07/07_fig_06_comparison.png",
        help="Chemin de la figure de sortie.",
    )
    p.add_argument(
        "--inv-col",
        default=None,
        help="Nom explicite de la colonne d'invariant I1 (sinon auto-détection).",
    )
    p.add_argument(
        "--dcs2-col",
        default=None,
        help="Nom explicite de la colonne de dérivée c_s² (sinon auto-détection).",
    )
    p.add_argument(
        "--ddphi-col",
        default=None,
        help="Nom explicite de la colonne de dérivée δφ/φ (sinon auto-détection).",
    )
    p.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="Résolution de la figure.",
    )
    p.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity cumulable (-v, -vv).",
    )
    return p


def main(argv: Optional[Sequence[str]] = None) -> None:
    parser = build_arg_parser()
    args = parser.parse_args(argv)

    setup_logging(args.verbose)

    inv_csv = Path(args.inv_csv)
    dcs2_csv = Path(args.dcs2_csv)
    ddphi_csv = Path(args.ddphi_csv)
    meta_json = Path(args.meta_json)
    out_png = Path(args.out)

    plot_comparison(
        inv_csv=inv_csv,
        dcs2_csv=dcs2_csv,
        ddphi_csv=ddphi_csv,
        meta_json=meta_json,
        inv_col=args.inv_col,
        dcs2_col=args.dcs2_col,
        ddphi_col=args.ddphi_col,
        out_png=out_png,
        dpi=args.dpi,
    )


if __name__ == "__main__":
    main()
