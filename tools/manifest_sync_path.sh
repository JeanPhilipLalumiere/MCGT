#!/usr/bin/env bash
set -euo pipefail

PATH_IN="${1:-}"
[[ -z "$PATH_IN" ]] && { echo "Usage: $0 <path>"; exit 2; }
[[ ! -f "$PATH_IN" ]] && { echo "ERROR: not a regular file: $PATH_IN"; exit 2; }

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/manifest_sync.$(echo "$PATH_IN" | tr '/.' '__').$TS.log"
mkdir -p _tmp

say(){ echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG"; }

say "== manifest_sync_path: start =="
say "target: $PATH_IN"

# Backup manifeste
cp -a zz-manifests/manifest_master.json "zz-manifests/manifest_master.json.bak.$TS"
say "[backup] -> zz-manifests/manifest_master.json.bak.$TS"

# Patch des champs (size/sha/mtime + git_hash dernier commit)
python3 - "$PATH_IN" <<'PY'
import sys, json, os, hashlib, subprocess, shlex, datetime
M="zz-manifests/manifest_master.json"
p=sys.argv[1]

def sha256(fp):
    h=hashlib.sha256()
    with open(fp,'rb') as f:
        for c in iter(lambda:f.read(1<<20), b''): h.update(c)
    return h.hexdigest()

def iso(ts):
    return datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

doc=json.load(open(M, encoding="utf-8"))
st=os.stat(p)
sha=sha256(p)
git_hash=subprocess.check_output(["bash","-lc",f"git log -n1 --pretty=%H -- {shlex.quote(p)}"]).decode().strip()

updated=False
for e in doc.get("entries", []):
    if e.get("path")==p:
        e["size_bytes"]=st.st_size
        e["size"]=st.st_size
        e["sha256"]=sha
        e["mtime"]=int(st.st_mtime)
        e["mtime_iso"]=iso(st.st_mtime)
        e["git_hash"]=git_hash
        updated=True
        break

if not updated:
    # si l'entrée n'existe pas, on l’ajoute proprement
    entry={
        "path": p,
        "role": "artifact",
        "size_bytes": st.st_size,
        "sha256": sha,
        "mtime_iso": iso(st.st_mtime),
        "media_type": "application/octet-stream",
        "size": st.st_size,
        "mtime": int(st.st_mtime),
        "git_hash": git_hash
    }
    doc.setdefault("entries",[]).append(entry)

open(M,"w",encoding="utf-8").write(json.dumps(doc,indent=2,ensure_ascii=False))
print(f"SYNCED: {p} size={st.st_size} sha256={sha} git_hash={git_hash}")
PY

# Vérifs
say "[verify] audit --all"
./tools/audit_manifest_files.sh --all | tee -a "$LOG" || true

say "[verify] diag strict"
python3 zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on warnings \
  > "_tmp/diag_sync.$TS.json" 2>&1 || true
head -n 200 "_tmp/diag_sync.$TS.json" | tee -a "$LOG" || true

say "[verify] tests -q"
pytest -q | tee -a "$LOG" || true

say "== manifest_sync_path: done =="
echo "# === COPY LOGS FROM HERE ==="
