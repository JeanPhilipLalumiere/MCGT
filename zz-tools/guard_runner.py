# zz-tools/guard_runner.py
#!/usr/bin/env python3
import json, os, re, sys

AUTH = os.environ.get("AUTHORITY_MANIFESTS", "zz-manifests/manifest_master.json,zz-manifests/manifest_publication.json")
OUTPUT = os.environ.get("OUTPUT", "diag_report.json")
IGNORE_RGX = os.environ.get("IGNORE_PATHS_REGEX", "")

ignore_re = re.compile(IGNORE_RGX) if IGNORE_RGX else None

def issue(code, path, severity="ERROR", message=""):
    return {"code": code, "path": path, "severity": severity, "message": message}

def load_manifest(p):
    try:
        with open(p, "rb") as f:
            return json.load(f), None
    except FileNotFoundError:
        return None, issue("MANIFEST_MISSING", p, "ERROR", "manifest file not found")
    except Exception as e:
        return None, issue("JSON_INVALID", p, "ERROR", str(e))

def scan_manifest(path, data):
    issues = []
    files = data.get("files")
    if files is None:
        issues.append(issue("SCHEMA_INVALID", path, "WARN", "missing 'files' list"))
        return issues
    if not isinstance(files, list):
        issues.append(issue("SCHEMA_INVALID", path, "ERROR", "'files' must be a list"))
        return issues
    for i, entry in enumerate(files):
        if not isinstance(entry, dict):
            issues.append(issue("SCHEMA_INVALID", f"{path}#files[{i}]", "ERROR", "entry must be an object"))
            continue
        p = entry.get("path")
        if not isinstance(p, str) or not p:
            issues.append(issue("SCHEMA_INVALID", f"{path}#files[{i}]", "ERROR", "missing 'path' string"))
            continue
        if ignore_re and ignore_re.search(p):
            # Note: we only mark; postprocess may drop completely
            issues.append(issue("PATH_IGNORED", p, "WARN", "matches IGNORE_PATHS_REGEX"))
            continue
        if not os.path.exists(p):
            issues.append(issue("FILE_MISSING", p, "ERROR", "not found"))
    return issues

def main():
    issues = []
    for mpath in [s.strip() for s in AUTH.split(",") if s.strip()]:
        data, err = load_manifest(mpath)
        if err:
            issues.append(err)
            continue
        issues.extend(scan_manifest(mpath, data))
    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump({"issues": issues}, f, ensure_ascii=False, indent=2)
    print(f"[INFO] wrote {OUTPUT} with {len(issues)} issues")

if __name__ == "__main__":
    main()
