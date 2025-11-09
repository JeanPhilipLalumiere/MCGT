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
    p = argparse.ArgumentParser(description="(autofix)",,)
    C.add_common_plot_args(p)
    return p
