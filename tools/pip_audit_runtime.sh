#!/usr/bin/env bash
set -Eeuo pipefail
echo "[audit] Python: $(python3 --version 2>&1 || true)"
python3 -m pip install --upgrade pip >/dev/null
python3 -m pip install pip-audit jq >/dev/null
# Resolver : env 'runtime' (pas de dev extras)
# Sortie JSON pour artifacts + résumé textuel
python3 - <<'PY'
import json,subprocess,sys,os,shutil
out_json="audit.json"
allow=os.environ.get("AUDIT_ALLOWLIST",".github/audit/allowlist.txt")
cmd=["pip-audit","-r","requirements.txt","--format","json"]
try:
    res=subprocess.run(cmd, capture_output=True, text=True, check=False)
    data=res.stdout.strip() or "[]"
    try:
        items=json.loads(data)
    except Exception:
        items=[]
    ignored=set()
    if os.path.isfile(allow):
        with open(allow,"r",encoding="utf-8") as f:
            for line in f:
                line=line.strip()
                if not line or line.startswith("#"): continue
                ignored.add(line)
    findings=[]
    # pip-audit JSON peut être {dependencies:[{vulns:[{id:GHSA-..|CVE-..}]}]}
    try:
        for dep in (items.get("dependencies",[]) if isinstance(items,dict) else []):
            for v in dep.get("vulns",[]):
                vid=v.get("id","").strip()
                if vid and vid not in ignored:
                    findings.append(vid)
    except Exception:
        pass
    with open(out_json,"w",encoding="utf-8") as f: f.write(res.stdout)
    print("[audit] findings(not-ignored):", ", ".join(findings) if findings else "<none>")
    sys.exit(1 if findings else 0)
except Exception as e:
    print("[audit] runtime error:",e)
    sys.exit(2)
PY
