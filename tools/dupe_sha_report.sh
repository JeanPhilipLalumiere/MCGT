#!/usr/bin/env bash
# tools/dupe_sha_report.sh
# Objet : lister les fichiers *suivis* qui sont des doublons SHA256,
#         et indiquer s'ils figurent dans le manifeste.
# - Ne modifie rien
# - Sorties : _tmp/dupes_grouped.<TS>.tsv et _tmp/dupes_with_manifest.<TS>.tsv
# - Robuste aux '\x00' résiduels et aux chemins non décodables

set -euo pipefail
TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/dupe_sha.$TS.log"
mkdir -p _tmp

echo "[dupe] start $TS" | tee -a "$LOG"

# Liste des fichiers suivis (0-terminated)
git ls-files -z > "_tmp/tracked.$TS.zlist"

# Ensemble des chemins présents dans le manifeste
python - "$TS" <<'PY' > "_tmp/manifest_set.$TS.txt"
import json,sys
doc=json.load(open("zz-manifests/manifest_master.json"))
for e in doc.get("entries", []):
    p=e.get("path")
    if p:
        print(p)
PY

# SHA256 par fichier suivi (robuste aux NULs/encodage)
python - "$TS" <<'PY' > "_tmp/dupes_raw.$TS.tsv"
import sys, os, hashlib

def read_tracked(ts):
    data = open(f"_tmp/tracked.{ts}.zlist","rb").read()
    items = data.split(b"\0")
    out=[]
    for b in items:
        if not b:
            continue
        try:
            p = b.decode("utf-8", "surrogatepass")
        except UnicodeDecodeError:
            p = b.decode("utf-8","ignore")
        # retire tout NUL résiduel (sécurité)
        p = p.replace("\x00","").strip()
        if not p:
            continue
        out.append(p)
    return out

def sha256(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for chunk in iter(lambda:f.read(1<<20), b''):
            h.update(chunk)
    return h.hexdigest()

ts=sys.argv[1]
tracked = read_tracked(ts)

print("sha256\tsize_bytes\tpath")
for p in tracked:
    # git ls-files ne liste que des fichiers, mais on reste défensifs
    if not os.path.isfile(p):
        continue
    try:
        sz=os.path.getsize(p)
        h=sha256(p)
        print(f"{h}\t{sz}\t{p}")
    except (FileNotFoundError, PermissionError, OSError):
        # fichier supprimé/renommé entre-temps, droits, etc. -> on ignore
        continue
PY

# Agrégation : ne garder que les hash ayant >=2 occurrences
python - "$TS" <<'PY' > "_tmp/dupes_grouped.$TS.tsv"
import sys, collections
rows=[l.rstrip("\n").split("\t") for l in open(f"_tmp/dupes_raw.{sys.argv[1]}.tsv", "r", encoding="utf-8", errors="replace")][1:]
by=collections.defaultdict(list)
for h,sz,p in rows:
    try:
        by[h].append((int(sz),p))
    except ValueError:
        continue

print("sha256\tsize_bytes\tcount\tpaths")
for h, lst in by.items():
    if len(lst) >= 2:
        sz = lst[0][0]
        ps = " | ".join(p for _,p in lst[:200])  # garde max 200 chemins en ligne
        print(f"{h}\t{sz}\t{len(lst)}\t{ps}")
PY

# Marquer si chaque chemin du groupe est présent dans le manifeste
python - "$TS" <<'PY' > "_tmp/dupes_with_manifest.$TS.tsv"
import sys
manifest=set(open(f"_tmp/manifest_set.{sys.argv[1]}.txt","r",encoding="utf-8",errors="replace").read().splitlines())

print("sha256\tsize_bytes\tcount\tpath\tin_manifest")
for line in open(f"_tmp/dupes_grouped.{sys.argv[1]}.tsv","r",encoding="utf-8",errors="replace"):
    if line.startswith("sha256"):
        continue
    h,sz,c,paths=line.rstrip("\n").split("\t",3)
    for p in paths.split(" | "):
        flag = "yes" if p in manifest else "no"
        print(f"{h}\t{sz}\t{c}\t{p}\t{flag}")
PY

echo "[dupe] wrote:" | tee -a "$LOG"
echo "  _tmp/dupes_grouped.$TS.tsv" | tee -a "$LOG"
echo "  _tmp/dupes_with_manifest.$TS.tsv" | tee -a "$LOG"
echo "[dupe] done" | tee -a "$LOG"
echo "# === COPY LOGS FROM HERE ==="
