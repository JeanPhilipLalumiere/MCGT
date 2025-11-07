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
import argparse
from _common import cli as C
# fichier : zz-scripts/_common/style.py
# répertoire : zz-scripts/_common
"""
MCGT common figure styles (opt-in).
Usage:
    import zz-scripts._common.style  # via postparse loader
    style.apply(theme="paper")       # or "talk", "mono"
"""

import matplotlib
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

_THEMES = {
    "paper": dict(
        figure_dpi=150,
        font_size=9,
        font_family="DejaVu Sans",
        axes_linewidth=0.8,
        grid=True,
    ),
    "talk": dict(
        figure_dpi=150,
        font_size=12,
        font_family="DejaVu Sans",
        axes_linewidth=1.0,
        grid=True,
    ),
    "mono": dict(
        figure_dpi=150,
        font_size=9,
        font_family="DejaVu Sans Mono",
        axes_linewidth=0.8,
        grid=True,
    ),
}


def apply(theme: str | None) -> None:
    if not theme or theme == "none":
        return
    t = _THEMES.get(theme, _THEMES["paper"])
    rc = matplotlib.rcParams
    # taille police
    rc["font.size"] = t["font_size"]
    rc["font.family"] = [t["font_family"]]
    # traits axes
    rc["axes.linewidth"] = t["axes_linewidth"]
    rc["xtick.major.width"] = t["axes_linewidth"]
    rc["ytick.major.width"] = t["axes_linewidth"]
    # DPI figure par défaut (ne force pas savefig.*)
    rc["figure.dpi"] = t["figure_dpi"]
    # grille légère
    rc["axes.grid"] = bool(t["grid"])
    rc["grid.linestyle"] = ":"
    rc["grid.linewidth"] = 0.6
def build_parser() -> argparse.ArgumentParser:
    p = argparseArgumentParser(description="(autofix)",)
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
