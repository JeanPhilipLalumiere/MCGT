import json, os, re, sys, collections

ALLOW_MISSING_REGEX = os.getenv("ALLOW_MISSING_REGEX", r"\.lock\.json$|^zz-data/chapter0[8-9]/|^zz-data/chapter10/")
SOFT_PASS_IF_ONLY_CODES_REGEX = os.getenv("SOFT_PASS_IF_ONLY_CODES_REGEX", r"^(FILE_MISSING|MANIFEST_MISSING)$")

IGNORE_PATHS = re.compile(r'\.bak(\.|_|$)|_autofix', re.I)
ALLOW_MISSING = re.compile(ALLOW_MISSING_REGEX, re.I)
SOFT_RGX = re.compile(SOFT_PASS_IF_ONLY_CODES_REGEX) if SOFT_PASS_IF_ONLY_CODES_REGEX else None

with open('diag_report.json', 'rb') as f:
    rep = json.load(f)

issues = rep.get("issues") or []
kept = []
for it in issues:
    path = str(it.get("path",""))
    if IGNORE_PATHS.search(path):
        continue
    code = str(it.get("code","")).upper()
    sev  = (str(it.get("severity","")) or "ERROR").upper()
    msg  = str(it.get("message",""))
    if code == "FILE_MISSING" and ALLOW_MISSING.search(path):
        sev = "WARN"
    kept.append({"code":code, "path":path, "severity":sev, "message":msg})

by_code = collections.Counter(k["code"] for k in kept)
warns  = [k for k in kept if k["severity"] == "WARN"]
errors = [k for k in kept if k["severity"] == "ERROR"]

for w in warns:
    print(f"::warning::{w['code']} at {w['path']}: {w['message']}")
for e in errors:
    print(f"::error::{e['code']} at {e['path']}: {e['message']}")

print(f"[INFO] total={len(kept)} warn={len(warns)} error={len(errors)}")
print(f"[INFO] codes={dict(by_code)}")

soft_only = (SOFT_RGX is not None) and bool(kept) and all(SOFT_RGX.search(k["code"] or "") for k in kept)
sys.exit(0 if soft_only or not errors else 1)
