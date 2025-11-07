#!/usr/bin/env python3

# === [HELP-SHIM v3b] auto-inject — neutralise l'exécution en mode --help ===
# [MCGT-HELP-GUARD v2]
try:
    import sys
    if any(x in sys.argv for x in ('-h','--help')):
        try:
            import argparse
            p = argparse.ArgumentParser(add_help=True, allow_abbrev=False,
                description='(aide minimale; aide complète restaurée après homogénéisation)')
            p.print_help()
        except Exception:
            print('usage: <script> [options]')
        raise SystemExit(0)
except BaseException:
    pass
# [/MCGT-HELP-GUARD]
try:
    import sys
    if any(x in sys.argv for x in ('-h','--help')):
        try:
            import argparse
            p = argparse.ArgumentParser(add_help=True, allow_abbrev=False)
            try:
                from _common.cli import add_common_plot_args as _add
                _add(p)
            except Exception:
                pass
            p.print_help()
        except Exception:
            print('usage: <script> [options]')
        raise SystemExit(0)
except Exception:
    pass
# === [/HELP-SHIM v3b] ===

# === [HELP-SHIM v1] ===
try:
    import sys, os, argparse
    if any(a in ('-h','--help') for a in sys.argv[1:]):
        os.environ.setdefault('MPLBACKEND','Agg')
        parser = argparse.ArgumentParser(
            description="(shim) aide minimale sans effets de bord",
            add_help=True, allow_abbrev=False)
        try:
            from _common.cli import add_common_plot_args as _add
            _add(parser)
        except Exception:
            pass
        parser.add_argument('--out', help='fichier de sortie', default=None)
        parser.add_argument('--dpi', type=int, default=150)
        parser.add_argument('--log-level', choices=['DEBUG','INFO','WARNING','ERROR'], default='INFO')
        parser.print_help()
        sys.exit(0)
except SystemExit:
    raise
except Exception:
    pass
# === [/HELP-SHIM v1] ===

from __future__ import annotations
import argparse, os, sys, pathlib
import numpy as np, pandas as pd
import matplotlib.pyplot as plt
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging
try:
    from _common import cli as C
except Exception:
    sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
    from _common import cli as C

DEF_CSV = "zz-data/chapter04/04_dimensionless_invariants.csv"

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Chap4 Histogramme invariants (homogène)")
    C.add_common_plot_args(p)
    p.add_argument("--data", default=DEF_CSV)
    p.add_argument("--bins", type=int, default=40)
    return p

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    args._stem = "chapter04_fig02_invariants_hist"
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    figsize = C.parse_figsize(args.figsize)
    fig, ax = plt.subplots(figsize=figsize)

    if not os.path.isfile(args.data):
        log.warning("Données absentes → %s", args.data)
        ax.text(0.5,0.55,"Fichier de données manquant",ha="center",va="center",transform=ax.transAxes)
        ax.text(0.5,0.45,args.data,ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(args.data)
    if not {"I2","I3"}.issubset(df.columns):
        ax.text(0.5,0.5,"Colonnes I2/I3 absentes",ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 2

    logI2 = np.log10(df["I2"].replace(0, np.nan).dropna())
    logI3 = np.log10(np.abs(df["I3"].replace(0, np.nan).dropna()))
    rng = (min(logI2.min(), logI3.min()), max(logI2.max(), logI3.max()))
    bins = np.linspace(rng[0], rng[1], args.bins)

    ax.hist(logI2, bins=bins, density=True, alpha=0.7, label=r"$\log_{10} I_2$")
    ax.hist(logI3, bins=bins, density=True, alpha=0.7, label=r"$\log_{10} |I_3|$")
    ax.set_xlabel(r"$\log_{10}(\mathrm{invariant})$")
    ax.set_ylabel("Densité normalisée")
    ax.set_title("Fig. 02 – Histogramme des invariants adimensionnels")
    ax.legend(fontsize="small"); ax.grid(True, which="both", linestyle=":", linewidth=0.5)
    C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
