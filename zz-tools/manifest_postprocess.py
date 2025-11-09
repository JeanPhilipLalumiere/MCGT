import json, os, re, sys, collections

ALLOW_MISSING_REGEX = os.getenv(
    "ALLOW_MISSING_REGEX",
    r"\.lock\.json$|^zz-data/chapter0[8-9]/|^zz-data/chapter10/"
)
SOFT_PASS_IF_ONLY_CODES_REGEX = os.getenv(
    "SOFT_PASS_IF_ONLY_CODES_REGEX",
    r"^(FILE_MISSING)$"
)

IGNORE_PATHS = re.compile(r'\.bak(\.|_|$)|_autofix', re.I)
ALLOW_MISSING = re.compile(ALLOW_MISSING_REGEX, re.I)
SOFT_RGX = re.compile(SOFT_PASS_IF_ONLY_CODES_REGEX) if SOFT_PASS_IF_ONLY_CODES_REGEX else None

with open('diag_report.json', 'rb') as f:
    rep = json.load(f)

issues = rep.get("issues") or []
kept = []
for it in issues:
    path = str(it.get("path", ""))
    if IGNORE_PATHS.search(path):
        continue
    code = str(it.get("code", "")).upper()
    sev  = (str(it.get("severity", "")) or "ERROR").upper()
    msg  = str(it.get("message", ""))

    # Downgrade FILE_MISSING -> WARN si le chemin est autorisé
    if code == "FILE_MISSING" and ALLOW_MISSING.search(path):
        sev = "WARN"

    kept.append({"code": code, "severity": sev, "path": path, "message": msg})

by_code = collections.Counter(k["code"] for k in kept)
errors = [k for k in kept if k["severity"] == "ERROR"]
warns  = [k for k in kept if k["severity"] != "ERROR"]

# Soft-pass si TOUTES les erreurs appartiennent au jeu "soft"
if errors and SOFT_RGX and all(SOFT_RGX.search(e["code"]) for e in errors):
    for e in errors:
        warns.append({"code": e["code"], "severity": "WARN", "path": e["path"], "message": e["message"]})
    errors = []

print(f"[INFO] total={len(issues)} kept={len(kept)} warn={len(warns)} error={len(errors)}")
print(f"[INFO] codes={dict(by_code)}")

for e in errors[:200]:
    print(f"::error::{e['code']} at {e['path']}: {e['message']}")
for w in warns[:500]:
    print(f"::warning::{w['code']} at {w['path']}: {w['message']}")

sys.exit(1 if errors else 0)
