#!/usr/bin/env bash
set -euo pipefail

latest(){ ls -1t _tmp/"$1".*.txt 2>/dev/null | head -n1; }
ADD_IN="${ADD_IN:-$(latest proposed_add_to_manifest)}"
IGN_IN="${IGN_IN:-$(latest proposed_ignore)}"

APPLY_IGNORE="${APPLY_IGNORE:-0}"     # 1 pour patcher .gitignore
APPLY_MANIFEST="${APPLY_MANIFEST:-0}" # 1 pour ajouter au manifeste

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/apply_candidates.$TS.log"
mkdir -p _tmp

say(){ echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG"; }

say "== apply_candidates: start =="
say "inputs: ADD_IN=${ADD_IN:-<none>} ; IGN_IN=${IGN_IN:-<none>}"
say "flags : APPLY_IGNORE=$APPLY_IGNORE ; APPLY_MANIFEST=$APPLY_MANIFEST"

# 1) .gitignore
if [[ "$APPLY_IGNORE" == 1 && -n "${IGN_IN:-}" && -s "${IGN_IN:-}" ]]; then
  say "[ignore] backup & patch .gitignore"
  cp -a .gitignore ".gitignore.bak.$TS" 2>/dev/null || true
  BLK="_tmp/.gitignore.add.$TS"
  { echo ""; echo "# --- auto-ignore (apply_candidates $TS) ---"; cat "$IGN_IN"; } > "$BLK"
  cat "$BLK" >> .gitignore
  awk '!seen[$0]++' .gitignore > .gitignore.tmp && mv .gitignore.tmp .gitignore
  say "[ignore] .gitignore mis à jour (backup: .gitignore.bak.$TS)"
else
  say "[ignore] skipped (flag off ou liste vide)"
fi

# 2) Manifeste
if [[ "$APPLY_MANIFEST" == 1 && -n "${ADD_IN:-}" && -s "${ADD_IN:-}" ]]; then
  say "[manifest] backup & patch"
  cp -a zz-manifests/manifest_master.json "zz-manifests/manifest_master.json.bak.$TS"

  python3 - "$ADD_IN" <<'PY' > "_tmp/apply_manifest.$TS.out" 2>&1
import sys, json, os, hashlib, subprocess, shlex, datetime

ADD = sys.argv[1]
M   = "zz-manifests/manifest_master.json"

def sha256(p):
    h=hashlib.sha256()
    with open(p,'rb') as f:
        for c in iter(lambda:f.read(1<<20), b''): h.update(c)
    return h.hexdigest()

def iso(ts):
    return datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

doc=json.load(open(M))
paths=set(e.get("path") for e in doc.get("entries",[]) if e.get("path"))
to_add=[p.strip() for p in open(ADD, encoding="utf-8", errors="replace") if p.strip()]
added=0

for p in to_add:
    if p in paths: 
        continue
    if not os.path.isfile(p):
        continue
    st=os.stat(p)
    sha=sha256(p)
    git_hash=subprocess.check_output(["bash","-lc", f"git log -n1 --pretty=%H -- {shlex.quote(p)}"]).decode().strip()
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
    added += 1

open(M,"w", encoding="utf-8").write(json.dumps(doc, indent=2, ensure_ascii=False))
print(f"ADDED {added} entries")
PY

  say "[manifest] patch fini — voir _tmp/apply_manifest.$TS.out"
else
  say "[manifest] skipped (flag off ou liste vide)"
fi

# 3) Vérifications
say "[verify] audit"
./tools/audit_manifest_files.sh --all | tee -a "$LOG" || true

say "[verify] diag strict"
python3 zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on warnings \
  > "_tmp/diag_apply.$TS.json" 2>&1 || true
head -n 120 "_tmp/diag_apply.$TS.json" | tee -a "$LOG" || true

say "[verify] tests"
pytest -q | tee -a "$LOG" || true

say "== apply_candidates: done =="
echo "# === COPY LOGS FROM HERE ==="
