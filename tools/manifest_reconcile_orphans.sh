#!/usr/bin/env bash
# But: détecter les orphelins du manifeste et (optionnel) les retirer proprement.
# - Dry-run par défaut (APPLY=1 pour patcher)
# - Toujours sauvegarder le manifeste avant patch
# - N'écrit rien hors _tmp/ si APPLY!=1

set -euo pipefail
: "${APPLY:=0}"   # 1 pour appliquer le patch (retrait des entrées orphelines)
TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/manifest_orphans.$TS.log"
OUT="_tmp/health_manifest_orphans.txt"

echo "[orphans] start $TS" | tee -a "$LOG"

# (Re)génère la liste des orphelins (au cas où)
python - <<'PY' > "$OUT"
import json, os
doc=json.load(open("zz-manifests/manifest_master.json"))
missing=[]
for i,e in enumerate(doc.get("entries",[])):
    p=e.get("path")
    if p and not os.path.exists(p):
        missing.append(p)
print("\n".join(missing))
PY

count=$(grep -c '' "$OUT" || true)
echo "[orphans] count=$count" | tee -a "$LOG"

if [[ "$count" -eq 0 ]]; then
  echo "[orphans] nothing to do." | tee -a "$LOG"
  echo "# === COPY LOGS FROM HERE ==="
  exit 0
fi

echo "[orphans] list ↓" | tee -a "$LOG"
sed -n '1,200p' "$OUT" | tee -a "$LOG"

if [[ "${APPLY}" != "1" ]]; then
  echo "[orphans] dry-run only (APPLY=1 to patch)" | tee -a "$LOG"
  echo "# === COPY LOGS FROM HERE ==="
  exit 0
fi

# Patch (sûr): backup + filtre les entrées absentes du FS
cp -a zz-manifests/manifest_master.json "zz-manifests/manifest_master.json.bak.$TS"
python - <<'PY'
import json, os, shutil
M="zz-manifests/manifest_master.json"
doc=json.load(open(M))
new=[]
for e in doc.get("entries",[]):
    p=e.get("path")
    if p and not os.path.exists(p):
        # skip -> retrait
        continue
    new.append(e)
doc["entries"]=new
open(M,"w").write(json.dumps(doc,indent=2,ensure_ascii=False))
PY

echo "[orphans] patched manifest (backup: zz-manifests/manifest_master.json.bak.$TS)" | tee -a "$LOG"

# Vérif diag strict
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on warnings \
  > "_tmp/diag_orphans_after.$TS.json" 2>&1 || {
    echo "[orphans] diag failed — head ↓" | tee -a "$LOG"
    head -n 200 "_tmp/diag_orphans_after.$TS.json" | tee -a "$LOG"
    echo "# === COPY LOGS FROM HERE ==="
    exit 1
  }

echo "[orphans] diag strict OK after patch" | tee -a "$LOG"
echo "# === COPY LOGS FROM HERE ==="
