#!/usr/bin/env bash
# tools/scan_repo_health.sh
# Objectif: produire des rapports *sans modifier le dépôt* pour planifier le cleanup.
# - Rapports écrits dans _tmp/
# - Zéro écriture dans le repo (hors _tmp/)
# - Idempotent, n’échoue pas la session terminal

set -euo pipefail

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/scan_repo_health.$TS.log"
mkdir -p _tmp
: "${LARGE_BYTES:=5000000}"   # seuil "gros fichier" (par défaut 5 MB)
: "${COMPUTE_SHA:=0}"         # 1 pour produire un rapport de doublons SHA256 (peut être plus long)

ts(){ date -u +'%Y-%m-%dT%H:%M:%SZ'; }
log(){ echo "[$(ts)] $*" | tee -a "$LOG"; }

log "== scan_repo_health: start =="
log "threshold LARGE_BYTES=$LARGE_BYTES ; COMPUTE_SHA=$COMPUTE_SHA"

# --- chemins suivis par git
git ls-files -z > "_tmp/tracked.$TS.zlist"

# --- chemins présents dans le manifeste
python - "$TS" <<'PY' > "_tmp/manifest_paths.$TS.txt"
import json,sys
doc=json.load(open("zz-manifests/manifest_master.json"))
for e in doc.get("entries", []):
    p=e.get("path")
    if p: print(p)
PY

# --- (A) Fichiers suivis par git mais absents du manifeste
python - "$TS" <<'PY' > "_tmp/health_tracked_not_in_manifest.txt"
import sys, os
tracked = [p for p in open(f"_tmp/tracked.{sys.argv[1]}.zlist","rb").read().split(b"\0") if p]
tracked = [p.decode() for p in tracked]
manifest = set(open(f"_tmp/manifest_paths.{sys.argv[1]}.txt").read().splitlines())
out=[]
for p in tracked:
    if p.startswith("zz-manifests/"): 
        continue
    if p not in manifest:
        out.append(p)
print("\n".join(sorted(out)))
PY
log "Wrote _tmp/health_tracked_not_in_manifest.txt"

# --- (B) Entrées du manifeste dont le fichier n’existe pas (orphelins)
python - "$TS" <<'PY' > "_tmp/health_manifest_orphans.txt"
import os, sys
manifest = [l.strip() for l in open(f"_tmp/manifest_paths.{sys.argv[1]}.txt")]
missing=[p for p in manifest if p and not os.path.exists(p)]
print("\n".join(missing))
PY
log "Wrote _tmp/health_manifest_orphans.txt"

# --- (C) Gros fichiers suivis (seuil configurable)
python - "$TS" <<'PY' > "_tmp/health_large_tracked.tsv"
import sys, os
thresh = int(os.environ.get("LARGE_BYTES","5000000"))
tracked=[p for p in open(f"_tmp/tracked.{sys.argv[1]}.zlist","rb").read().split(b"\0") if p]
tracked=[p.decode() for p in tracked]
print("size_bytes\tpath")
for p in tracked:
    try:
        sz=os.path.getsize(p)
        if sz>=thresh:
            print(f"{sz}\t{p}")
    except FileNotFoundError:
        pass
PY
log "Wrote _tmp/health_large_tracked.tsv (threshold=${LARGE_BYTES})"

# --- (D) SHA256 doublons (optionnel)
if [[ "${COMPUTE_SHA}" == "1" ]]; then
  log "Computing SHA256 for tracked files (may take a while)…"
  python - "$TS" <<'PY' > "_tmp/health_dupe_sha256.tsv"
import sys, os, hashlib, itertools
tracked=[p for p in open(f"_tmp/tracked.{sys.argv[1]}.zlist","rb").read().split(b"\0") if p]
tracked=[p.decode() for p in tracked]
def sha256(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for chunk in iter(lambda:f.read(1<<20), b''):
            h.update(chunk)
    return h.hexdigest()
records=[]
for p in tracked:
    try:
        sz=os.path.getsize(p)
        h=sha256(p)
        records.append((h,sz,p))
    except FileNotFoundError:
        pass
# regrouper par hash, ne garder que doublons
from collections import defaultdict
g=defaultdict(list)
for h,sz,p in records:
    g[h].append((sz,p))
print("sha256\tsize_bytes\tcount\tsample_paths")
for h, lst in g.items():
    if len(lst)>1:
        sz = lst[0][0]
        samples = ", ".join(p for _,p in itertools.islice(lst,0,5))
        print(f"{h}\t{sz}\t{len(lst)}\t{samples}")
PY
  log "Wrote _tmp/health_dupe_sha256.tsv"
fi

# --- Résumés rapides
log "SUMMARY counts:"
printf "  tracked_not_in_manifest: %s\n" "$(grep -c '' _tmp/health_tracked_not_in_manifest.txt || echo 0)" | tee -a "$LOG"
printf "  manifest_orphans       : %s\n" "$(grep -c '' _tmp/health_manifest_orphans.txt || echo 0)" | tee -a "$LOG"
printf "  large_tracked_rows     : %s\n" "$(($(wc -l < _tmp/health_large_tracked.tsv)-1))" | tee -a "$LOG"
if [[ "${COMPUTE_SHA}" == "1" ]]; then
  printf "  dupe_sha256_rows       : %s\n" "$(($(wc -l < _tmp/health_dupe_sha256.tsv)-1))" | tee -a "$LOG"
fi

log "== scan_repo_health: done =="
echo "# === COPY LOGS FROM HERE ==="
