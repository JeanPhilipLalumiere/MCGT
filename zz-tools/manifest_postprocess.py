#!/usr/bin/env python3
import json, os, re, sys

ALLOW_RX  = os.environ.get("ALLOW_MISSING_REGEX", "")
SOFT_RX   = os.environ.get("SOFT_PASS_IF_ONLY_CODES_REGEX", "")
HARDLIST  = [c.strip() for c in os.environ.get("HARD_FAIL_CODES","").split(",") if c.strip()]
IGNORE_RX = os.environ.get("IGNORE_PATHS_REGEX", "")

def rx(pat):
    try: return re.compile(pat) if pat else None
    except re.error: return None

allow_re  = rx(ALLOW_RX)
soft_re   = rx(SOFT_RX)
ignore_re = rx(IGNORE_RX)

try:
    data = json.load(open("diag_report.json","rb"))
    issues = data.get("issues", [])
except Exception as e:
    print(f"::error::POSTPROCESS JSON_INVALID: {e}")
    sys.exit(1)

# Masque des chemins non-autorité
if ignore_re:
    issues = [i for i in issues if not (isinstance(i.get("path"), str) and ignore_re.search(i["path"]))]

# Downgrade en WARN pour chemins autorisés
for i in issues:
    p = i.get("path","")
    if allow_re and isinstance(p, str) and allow_re.search(p):
        i["severity"] = "WARN"

codes, warns, hard_hit = {}, 0, False
for i in issues:
    c = i.get("code","UNKNOWN")
    codes[c] = codes.get(c,0) + 1
    if i.get("severity") == "WARN": warns += 1
    if HARDLIST and c in HARDLIST: hard_hit = True

total = len(issues); errors = total - warns
print(f"[INFO] total={total} warn={warns} error={errors}")
print(f"[INFO] codes={codes}")

only_codes = set(codes.keys())
soft_pass = False
if soft_re and total > 0 and all(soft_re.search(c or "") for c in only_codes):
    soft_pass = True

with open("diag_report.json","w") as f:
    json.dump({"issues": issues}, f, indent=2)

if hard_hit and not soft_pass:
    print("::error::HARD_FAIL triggered")
    sys.exit(1)

print("[INFO] Postprocess exit=0")
sys.exit(0)
