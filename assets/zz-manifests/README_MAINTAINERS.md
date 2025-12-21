# Manifest — guide mainteneur

## Vérifier et auditer
```bash
./tools/audit_manifest_files.sh --all
python assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on warnings
pytest -q
```

## Régénérer size/sha/mtime depuis le disque
```bash
python - <<'PY'
import json, os, hashlib
from datetime import datetime, timezone

M="assets/zz-manifests/manifest_master.json"

def sha(p):
    h=hashlib.sha256()
    with open(p,'rb') as f:
        for c in iter(lambda:f.read(1<<20), b''):
            h.update(c)
    return h.hexdigest()

def iso(ts):
    return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

doc=json.load(open(M))
n=0
for e in doc["entries"]:
    p=e["path"]
    st=os.stat(p)
    e["size_bytes"]=st.st_size
    e["size"]=st.st_size
    e["sha256"]=sha(p)
    e["mtime"]=int(st.st_mtime)
    e["mtime_iso"]=iso(st.st_mtime)
    n+=1

open(M,"w").write(json.dumps(doc, indent=2, ensure_ascii=False))
print("SYNCED:", n)
PY
```
