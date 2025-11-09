import json
import os
import sys

p = "zz-manifests/manifest_master.json"
if not os.path.exists(p):
    print("SKIP:", p, "(missing)")
    sys.exit(0)
m = json.load(open(p, encoding="utf-8"))
missing = []


def check(path):
    if not os.path.isabs(path):
        path = os.path.join(".", path)
    if not os.path.exists(path):
        missing.append(path)


def visit(v):
    if isinstance(v, list):
        for x in v:
            visit(x)
    elif isinstance(v, dict):
        if "path" in v:
            check(v["path"])
        if "file" in v:
            check(v["file"])
    elif isinstance(v, str):
        check(v)


for k in ("files", "data", "artifacts"):
    visit(m.get(k, []))
if missing:
    print("Missing files in manifest:")
    [print("  -", x) for x in missing]
    sys.exit(1)
print("Manifest OK.")
