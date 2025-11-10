#!/usr/bin/env python3
import json, sys, os

def issue(code, path, severity="ERROR", message=""):
    return {"code": code, "path": path, "severity": severity, "message": message}

def main(p):
    try:
        data = json.load(open(p, "rb"))
    except Exception as e:
        print(json.dumps({"issues":[issue("JSON_INVALID", p, "ERROR", str(e))]}))
        return

    issues = []
    files = data.get("files")
    if not isinstance(files, list):
        issues.append(issue("SCHEMA_INVALID", p, "ERROR", "'files' must be a list"))
    else:
        for i, f in enumerate(files):
            path = (f or {}).get("path")
            if not path or not isinstance(path, str):
                issues.append(issue("SCHEMA_INVALID", f"files[{i}]", "ERROR", "missing 'path' string"))
                continue
            if not os.path.exists(path):
                issues.append(issue("FILE_MISSING", path, "ERROR", "not found"))

    print(json.dumps({"issues": issues}, ensure_ascii=False))

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "zz-manifests/manifest_master.json")
