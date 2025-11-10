#!/usr/bin/env python3
import json, os, re, sys, collections

ALLOW_MISSING_REGEX = os.getenv("ALLOW_MISSING_REGEX",
    r"\.lock\.json$|^zz-data/chapter0[8-9]/|^zz-data/chapter10/")
SOFT_PASS_IF_ONLY_CODES_REGEX = os.getenv("SOFT_PASS_IF_ONLY_CODES_REGEX",
    r"^(FILE_MISSING|MANIFEST_MISSING|SCHEMA_INVALID)$")

IGNORE_PATHS = re.compile(r'\.bak(\.|_|$)|_autofix', re.I)
ALLOW_MISSING = re.compile(ALLOW_MISSING_REGEX, re.I)
SOFT_RGX = re.compile(SOFT_PASS_IF_ONLY_CODES_REGEX) if SOFT_PASS_IF_ONLY_CODES_REGEX else None
HARD = {c.strip().upper() for c in (os.getenv("HARD_FAIL_CODES","").split(",") if os.getenv("HARD_FAIL_CODES") else [])}

with open('diag_report.json','rb') as f:
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
    # Downgrade FILE_MISSING pour chemins tolérés
    if code == "FILE_MISSING" and ALLOW_MISSING.search(path):
        sev = "WARN"
    kept.append({"code":code, "path":path, "severity":sev, "message":msg})

by_code = collections.Counter(k["code"] for k in kept)
warns  = [k for k in kept if k["severity"] == "WARN"]
errors = [k for k in kept if k["severity"] == "ERROR"]

# Logging explicite dans les annotations GitHub
for k in kept:
    if (k["code"] in HARD) or (k["severity"] == "ERROR"):
        print(f"::error::{k['code']} at {k['path']}: {k['message']}")
    elif k["severity"] == "WARN":
        print(f"::warning::{k['code']} at {k['path']}: {k['message']}")

print(f"[INFO] total={len(kept)} warn={len(warns)} error={len(errors)}")
print(f"[INFO] codes={dict(by_code)}")

hard_errors = [k for k in kept if (k["code"] in HARD) or (k["severity"]=="ERROR")]
sys.exit(1 if hard_errors else 0)
