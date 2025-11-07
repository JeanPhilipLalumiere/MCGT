#!/usr/bin/env bash
# But: quantifier l'écart git↔manifest par top-level et par extension.
# - Aide à décider quoi ajouter au manifeste vs. ignorer
# - Aucun changement sur le repo

set -euo pipefail
TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/manifest_gap.$TS.log"
mkdir -p _tmp

echo "[gap] start $TS" | tee -a "$LOG"

# Tracked (0-terminated)
git ls-files -z > "_tmp/tracked.$TS.zlist"

# Manifest paths
python - "$TS" <<'PY' > "_tmp/manifest_paths.$TS.txt"
import json,sys
doc=json.load(open("zz-manifests/manifest_master.json"))
for e in doc.get("entries", []):
    p=e.get("path")
    if p: print(p)
PY

# Diff list
python - "$TS" <<'PY' > "_tmp/gap_tracked_not_in_manifest.$TS.txt"
import sys
tracked=[p for p in open(f"_tmp/tracked.{sys.argv[1]}.zlist","rb").read().split(b"\0") if p]
tracked=[p.decode() for p in tracked]
manifest=set(open(f"_tmp/manifest_paths.{sys.argv[1]}.txt").read().splitlines())
out=[]
for p in tracked:
    if p.startswith("zz-manifests/"): continue
    if p not in manifest: out.append(p)
print("\n".join(out))
PY

# Group by toplevel
awk -F/ '{print $1}' "_tmp/gap_tracked_not_in_manifest.$TS.txt" | sort | uniq -c | sort -rn \
  > "_tmp/gap_by_toplevel.$TS.txt"
echo "[gap] wrote _tmp/gap_by_toplevel.$TS.txt" | tee -a "$LOG"

# Group by extension
awk -F. 'NF>1{print $NF} NF==1{print "<noext>"}' "_tmp/gap_tracked_not_in_manifest.$TS.txt" \
  | sort | uniq -c | sort -rn > "_tmp/gap_by_ext.$TS.txt"
echo "[gap] wrote _tmp/gap_by_ext.$TS.txt" | tee -a "$LOG"

# Sample per top-level (first 10 lines each)
echo "[gap] sample per toplevel (≤10 each) ↓" | tee -a "$LOG"
while read -r cnt dir; do
  echo "== $dir ($cnt) ==" | tee -a "$LOG"
  grep -E "^${dir}(/|$)" "_tmp/gap_tracked_not_in_manifest.$TS.txt" | head -n 10 | tee -a "$LOG"
done < "_tmp/gap_by_toplevel.$TS.txt"

echo "[gap] done" | tee -a "$LOG"
echo "# === COPY LOGS FROM HERE ==="
