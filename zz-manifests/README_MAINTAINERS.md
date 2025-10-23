# Manifest — guide mainteneur

## Vérifier et auditer
```bash
./tools/audit_manifest_files.sh --all
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json   --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on warnings
pytest -q
```

## Régénérer size/sha/mtime depuis le disque
```bash
python - <<'PY'
import json, os, hashlib
from datetime import datetime, timezone
M="zz-manifests/manifest_master.json"
def sha(p):
  h=hashlib.sha256()
  with open(p,'rb') as f:
    for c in iter(lambda:f.read(1<<20), b''): h.update(c)
  return h.hexdigest()
def iso(ts): return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
doc=json.load(open(M)); n=0
for e in doc["entries"]:
  p=e["path"]; st=os.stat(p)
  e["size_bytes"]=st.st_size; e["size"]=st.st_size
  e["sha256"]=sha(p); e["mtime"]=int(st.st_mtime); e["mtime_iso"]=iso(st.st_mtime); n+=1
open(M,"w").write(json.dumps(doc,indent=2,ensure_ascii=False))
print("SYNCED:", n)
PY
```

## Aligner git_hash sur l’état attendu par le diag
```bash
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json   --report json --normalize-paths --apply-aliases --strip-internal --content-check > _tmp/diag.json 2>&1 || true

python - <<'PY'
import json, re
M="zz-manifests/manifest_master.json"
diag=json.load(open("_tmp/diag.json"))
pat=re.compile(r"git_hash diffère \(manifest=[0-9a-f]{40}, git=([0-9a-f]{40})\)")
want={}
for it in diag.get("issues",[]):
  m=pat.search(it.get("message",""))
  if m: want[it["path"]]=m.group(1)
doc=json.load(open(M)); fix=0
for e in doc["entries"]:
  h=want.get(e["path"])
  if h and e.get("git_hash")!=h:
    e["git_hash"]=h; fix+=1
open(M,"w").write(json.dumps(doc,indent=2,ensure_ascii=False))
print("FIXED:", fix)
PY
```
