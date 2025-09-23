#!/usr/bin/env bash
set -euo pipefail
# Validation CSV simple & robuste :
# - Lisibilité / non-vide
# - Chargement pandas (header auto)
# - Vérif colonnes dupliquées / entièrement vides
# - Comptage NaN, lignes, colonnes

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

REPORT="_reports/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$REPORT"
OUT="$REPORT/csv_validation_report.txt"

PYCODE=$(cat <<'PY'
import sys, os, glob, json
from pathlib import Path
import pandas as pd

root = Path(".")
targets = sorted(root.glob("zz-data/**/*.csv"))
ok=0; bad=0
lines=[]
for p in targets:
    rel = p.as_posix()
    try:
        # existence & non-vide
        if p.stat().st_size == 0:
            bad+=1
            lines.append(f"[EMPTY] {rel}")
            continue
        # lecture
        df = pd.read_csv(p)
        # colonnes dupliquées ?
        if df.columns.duplicated().any():
            bad+=1
            lines.append(f"[DUPCOL] {rel} duplicated columns: {list(df.columns[df.columns.duplicated()])}")
            continue
        # colonnes entièrement vides ?
        empty_cols = [c for c in df.columns if df[c].isna().all()]
        if empty_cols:
            bad+=1
            lines.append(f"[EMPTYCOL] {rel} empty columns: {empty_cols}")
            continue
        # petit résumé
        nrows, ncols = df.shape
        nans = int(df.isna().sum().sum())
        lines.append(f"[OK] {rel} rows={nrows} cols={ncols} totalNaN={nans}")
        ok+=1
    except Exception as e:
        bad+=1
        lines.append(f"[FAIL] {rel} {type(e).__name__}: {e}")
print("\n".join(lines))
print(f"\nSummary: ok={ok} bad={bad}", file=sys.stderr)
PY
)
python - <<PYEOF | tee "$OUT"
$PYCODE
PYEOF
