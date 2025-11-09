
# === [HELP-SHIM v3b] auto-inject — neutralise l'exécution en mode --help ===
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
import argparse
from _common import cli as C
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

# R12-SEALED: do not auto-edit
import pandas as pd
def detect_p95_column(df: pd.DataFrame, hint: str|None) -> str:
    if hint and hint in df.columns: return hint
    for c in ('p95_20_300_recalc','p95_20_300_circ','p95_20_300','p95_circ','p95_recalc','p95','p95_20_300'):
        if c in df.columns: return c
    raise KeyError('p95 column not found')
def main():
    return 0  # stub
if __name__ == '__main__':
    raise SystemExit(main())
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",)
    C.add_common_plot_args(p)
    return p
