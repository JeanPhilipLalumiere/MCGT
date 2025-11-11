# zz-tools/manifest_postprocess.py
#!/usr/bin/env python3
import json, os, re, sys

REPORT_PATH = os.environ.get("REPORT_PATH", "diag_report.json")
IGNORE_PATHS_REGEX = os.environ.get("IGNORE_PATHS_REGEX", "")
SOFT_PASS_IF_ONLY_CODES_REGEX = os.environ.get("SOFT_PASS_IF_ONLY_CODES_REGEX", r"^(FILE_MISSING|MANIFEST_MISSING|SCHEMA_INVALID)$")
HARD_FAIL_CODES = os.environ.get("HARD_FAIL_CODES", r"^(JSON_INVALID)$")

ignore_re = re.compile(IGNORE_PATHS_REGEX) if IGNORE_PATHS_REGEX else None
soft_codes_re = re.compile(SOFT_PASS_IF_ONLY_CODES_REGEX) if SOFT_PASS_IF_ONLY_CODES_REGEX else None
hard_codes_re = re.compile(HARD_FAIL_CODES) if HARD_FAIL_CODES else None

def gh_annot(kind, msg, path=None):
    # kind: "error" or "warning"
    if path:
        print(f"::{kind} file={path}::{msg}")
    else:
        print(f"::{kind}::{msg}")

def set_output(key, value):
    out = os.environ.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a", encoding="utf-8") as f:
            f.write(f"{key}={value}\n")

def main():
    if not os.path.exists(REPORT_PATH):
        gh_annot("error", f"{REPORT_PATH} not found")
        set_output("hard_fail", "1")
        return

    try:
        data = json.load(open(REPORT_PATH, "rb"))
    except Exception as e:
        gh_annot("error", f"Invalid JSON in {REPORT_PATH}: {e}")
        set_output("hard_fail", "1")
        return

    raw = data.get("issues", []) or []
    # Filter ignored paths
    kept = []
    for it in raw:
        p = it.get("path") or ""
        if ignore_re and p and ignore_re.search(p):
            continue
        kept.append(it)

    total = len(kept)
    errors = [i for i in kept if (i.get("severity") or "").upper() == "ERROR"]
    warns  = [i for i in kept if (i.get("severity") or "").upper() != "ERROR"]

    # Annotations
    for w in warns:
        gh_annot("warning", f"{w.get('code','')} : {w.get('message','')}", w.get("path"))
    for e in errors:
        gh_annot("error", f"{e.get('code','')} : {e.get('message','')}", e.get("path"))

    # Decide hard_fail
    hard = 0
    if any(hard_codes_re and hard_codes_re.search(i.get("code","")) for i in kept):
        hard = 1
    else:
        if errors:
            only_soft = all(soft_codes_re and soft_codes_re.search(i.get("code","")) for i in errors)
            if not only_soft:
                hard = 1

    # Summary to stdout (step summary is handled in workflow)
    print(f"[INFO] total={total} warn={len(warns)} error={len(errors)}")
    codes = {}
    for i in kept:
        codes[i.get("code","UNKNOWN")] = codes.get(i.get("code","UNKNOWN"), 0) + 1
    print(f"[INFO] codes={codes}")

    set_output("hard_fail", "1" if hard else "0")

if __name__ == "__main__":
    main()
