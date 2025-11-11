#!/usr/bin/env python3
import json, sys, os

MODE = os.environ.get("CONSISTENCY_MODE", "equal").lower()  # "equal" ou "subset"
MASTER = "zz-manifests/manifest_master.json"
PUB    = "zz-manifests/manifest_publication.json"

def load_paths(p):
    try:
        with open(p, "rb") as fh:
            data = json.load(fh)
    except Exception as e:
        print(f"[ERR] JSON invalide: {p}: {e}")
        sys.exit(3)
    files = data.get("files") or []
    paths = sorted({str(x.get("path","")) for x in files
                    if isinstance(x, dict) and x.get("path")})
    return paths

m = load_paths(MASTER)
p = load_paths(PUB)

set_m, set_p = set(m), set(p)

ok = False
detail = ""
if MODE == "equal":
    ok = (set_m == set_p)
    if not ok:
        missing_in_pub = sorted(set_m - set_p)
        extra_in_pub   = sorted(set_p - set_m)
        detail = f"missing_in_pub={len(missing_in_pub)} extra_in_pub={len(extra_in_pub)}"
elif MODE == "subset":
    ok = set_p.issubset(set_m)
    if not ok:
        detail = f"violations={len(set_p - set_m)}"
else:
    print(f"[ERR] MODE inconnu: {MODE} (expected equal|subset)")
    sys.exit(4)

print(f"[INFO] master={len(m)} publication={len(p)} mode={MODE} ok={ok} {detail}".strip())

summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
if summary_path:
    with open(summary_path, "a", encoding="utf-8") as fh:
        fh.write(f"### Manifest consistency\n")
        fh.write(f"- mode: `{MODE}`\n")
        fh.write(f"- master: `{len(m)}` paths\n")
        fh.write(f"- publication: `{len(p)}` paths\n")
        if not ok:
            if MODE == "equal":
                fh.write(f"- missing_in_pub: {sorted(set_m - set_p)}\n")
                fh.write(f"- extra_in_pub: {sorted(set_p - set_m)}\n")
            else:
                fh.write(f"- extra_in_pub (not in master): {sorted(set_p - set_m)}\n")

sys.exit(0 if ok else 2)
