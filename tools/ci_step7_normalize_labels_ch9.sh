#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
# shellcheck disable=SC2034
set -euo pipefail

KEEP_OPEN="${KEEP_OPEN:-0}"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
REPORT=".ci-out/labels_ch9_report.txt"
: >"$REPORT"

log() { echo "INFO:  $*" | tee -a "$REPORT"; }
err() { echo "ERROR: $*" | tee -a "$REPORT"; }

files=(
  "zz-data/chapter09/09_comparison_milestones.csv"
  "zz-data/chapter09/09_comparison_milestones.flagged.csv"
)

changed_any=0
ts="$(date +%Y%m%dT%H%M%S)"

log "==> Normalisation des labels (ordre2→order2, primaire→primary) sur colonnes *class/label* (si présentes)"
python - <<'PY' | tee -a "$REPORT"
import csv, sys, os, json
from pathlib import Path

root = Path(os.getcwd())
files = [
    Path("zz-data/chapter09/09_comparison_milestones.csv"),
    Path("zz-data/chapter09/09_comparison_milestones.flagged.csv"),
]

syn = {"ordre2": "order2", "primaire": "primary"}

def normalize_value(v: str) -> str:
    if v is None: return v
    low = v.strip().lower()
    return syn.get(low, v)

def process_csv(path: Path):
    if not path.exists():
        return {"path": str(path), "status": "missing"}

    # Sniff delimiter
    sample = path.read_text(encoding="utf-8", errors="replace")[:4096]
    try:
        dialect = csv.Sniffer().sniff(sample)
        delim = dialect.delimiter
    except Exception:
        delim = ","  # fallback

    # Read
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f, delimiter=delim)
        rows = list(reader)
    if not rows:
        return {"path": str(path), "status": "empty"}

    header = rows[0]
    hdr_lc = [h.strip().lower() for h in header]
    # colonnes candidates
    candidates = []
    for i, h in enumerate(hdr_lc):
        if h in ("class","classe","class_label","label","classe_norm"):
            candidates.append(i)

    if not candidates:
        return {"path": str(path), "status": "no-class-column"}

    changed = 0
    total = 0
    out = [header]
    for r in rows[1:]:
        r2 = list(r)
        for ci in candidates:
            if ci < len(r2):
                old = r2[ci]
                new = normalize_value(old)
                if new != old:
                    r2[ci] = new
                    changed += 1
                total += 1
        out.append(r2)

    if changed > 0:
        # backup
        bak = Path(str(path) + ".bak")
        if not bak.exists():
            bak.write_text(Path(path).read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
        # write
        with path.open("w", encoding="utf-8", newline="") as f:
            csv.writer(f, delimiter=delim).writerows(out)

    return {
        "path": str(path), "delimiter": delim,
        "columns_normalized": candidates,
        "cells_touched": changed, "cells_scanned": total,
        "status": "changed" if changed>0 else "unchanged"
    }

summary = []
for p in files:
    summary.append(process_csv(p))

print(json.dumps({"summary": summary}, indent=2, ensure_ascii=False))
PY

echo "==> (2) pre-commit (tolérant puis strict)"
pre-commit run --all-files || true
pre-commit run --all-files

echo "==> (3) Tests (rapide) : diag master strict déjà OK; on relance pour vérifier l'absence de nouveaux soucis"
pytest -q zz-tests/test_schemas.py -k test_diag_master_no_errors_json_report \
  --disable-warnings --maxfail=1 \
  --junitxml .ci-out/schemas_after_labels.xml || {
  echo "WARN: le test strict échoue — voir rapports, corriger les CSV si nécessaire." | tee -a "$REPORT"
  exit 1
}

echo "==> (4) Commit & push des normalisations (si diff)"
git add zz-data/chapter09/*.csv || true
git commit -m "data(ch9): normalize class labels (ordre2/primaire -> order2/primary)" || true
git push || true

echo "✅ labels normalization: OK. Rapport: $REPORT"
