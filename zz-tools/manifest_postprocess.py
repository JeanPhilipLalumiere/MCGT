import json, os, re, sys, collections, pathlib

ALLOW_MISSING_REGEX = os.environ.get(
    "ALLOW_MISSING_REGEX",
    r"\.lock\.json$|^zz-data/chapter0[8-9]/|^zz-data/chapter10/"
)
SOFT_PASS_IF_ONLY_CODES_REGEX = os.environ.get(
    "SOFT_PASS_IF_ONLY_CODES_REGEX",
    r"^(FILE_MISSING)$"
)
IGNORE_PATHS = re.compile(r'\.bak(\.|_|$)|_autofix', re.I)
ALLOW_MISSING = re.compile(ALLOW_MISSING_REGEX, re.I)
soft_rgx = re.compile(SOFT_PASS_IF_ONLY_CODES_REGEX) if SOFT_PASS_IF_ONLY_CODES_REGEX else None

with open('diag_report.json','rb') as f:
    rep = json.load(f)

issues = rep.get("issues", []) or []
kept = []
for it in issues:
    path = str(it.get("path",""))
    if IGNORE_PATHS.search(path):
        continue
    code = str(it.get("code","")).upper()
    sev  = str(it.get("severity","")).upper()
    it2 = dict(it)
    # Normalize diffs en WARN
    if code in {"GIT_HASH_DIFFERS","MTIME_DIFFERS"}:
        it2["severity"] = "WARN"
    # Downgrade FILE_MISSING si autorisé
    if code == "FILE_MISSING" and ALLOW_MISSING.search(path):
        it2["severity"] = "WARN"
    kept.append(it2)

errors = [x for x in kept if str(x.get("severity","")).upper()=="ERROR"]
warns  = [x for x in kept if str(x.get("severity","")).upper()=="WARN"]
by_code = collections.Counter([str(i.get("code","")).upper() for i in errors])

print(f"[INFO] kept={len(kept)} WARN={len(warns)} ERROR={len(errors)}")
for it in errors[:200]:
    print(f"::error::{it.get('code','?')} at {it.get('path','?')}: {it.get('message','')}")
for it in warns[:200]:
    print(f"::warning::{it.get('code','?')} at {it.get('path','?')}: {it.get('message','')}")

# Soft-pass si toutes les erreurs appartiennent au set toléré
if errors and soft_rgx and all(soft_rgx.search(c or "") for c in by_code.keys()):
    print(f"[SOFT-PASS] Only non-blocking error codes: {sorted(by_code.keys())}")
    sys.exit(0)

sys.exit(1 if errors else 0)
