#!/usr/bin/env bash
set -euo pipefail

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/manifest_fix_git_hash.$TS.log"
mkdir -p _tmp

say(){ echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG"; }

say "== fix_git_hash_from_diag: start =="

# 1) Backup du manifeste
cp -a zz-manifests/manifest_master.json "zz-manifests/manifest_master.json.bak.$TS"
say "[backup] -> zz-manifests/manifest_master.json.bak.$TS"

# 2) Lancer un diag *non bloquant* pour récupérer les commits attendus
python3 zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check \
  > "_tmp/diag_git.$TS.json" 2>&1 || true

# 3) Parser le diag et patcher les git_hash attendus
python3 - "$TS" <<'PY'
import json, re, sys
ts=sys.argv[1]
diag=json.load(open(f"_tmp/diag_git.{ts}.json"))
pat=re.compile(r"git_hash diffère \(manifest=[0-9a-f]{40}, git=([0-9a-f]{40})\)")
expected={}
for it in diag.get("issues", []):
    if it.get("code")=="GIT_HASH_DIFFERS":
        m=pat.search(it.get("message",""))
        if m:
            expected[it["path"]]=m.group(1)

if not expected:
    print("NO_GIT_HASH_DIFFERS")
    sys.exit(0)

doc=json.load(open("zz-manifests/manifest_master.json",encoding="utf-8"))
changed=0
for e in doc.get("entries",[]):
    p=e.get("path")
    if p in expected:
        h=expected[p]
        if e.get("git_hash")!=h:
            e["git_hash"]=h
            changed+=1

open("zz-manifests/manifest_master.json","w",encoding="utf-8").write(
    json.dumps(doc,indent=2,ensure_ascii=False)
)
print(f"UPDATED git_hash entries: {changed}")
PY

# 4) Vérifs: audit, diag strict, tests
say "[verify] audit --all"
./tools/audit_manifest_files.sh --all | tee -a "$LOG" || true

say "[verify] diag strict"
python3 zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on warnings \
  > "_tmp/diag_fix.$TS.json" 2>&1 || true
head -n 200 "_tmp/diag_fix.$TS.json" | tee -a "$LOG" || true

say "[verify] tests"
pytest -q | tee -a "$LOG" || true

say "== fix_git_hash_from_diag: done =="
echo "# === COPY LOGS FROM HERE ==="
