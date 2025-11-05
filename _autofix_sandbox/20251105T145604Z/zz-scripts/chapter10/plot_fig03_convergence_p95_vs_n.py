from __future__ import annotations
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
