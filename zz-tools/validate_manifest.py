#!/usr/bin/env python3
import json, sys, os

def issue(code, path, severity="ERROR", message=""):
    return {"code": str(code), "path": str(path), "severity": str(severity), "message": str(message)}

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"issues":[issue("MANIFEST_MISSING", "zz-manifests", "ERROR", "no path provided")]}))
        return
    p = sys.argv[1]
    try:
        data = json.load(open(p, "rb"))
    except Exception as e:
        print(json.dumps({"issues":[issue("JSON_INVALID", p, "ERROR", str(e))]}))
        return

    issues = []
    files = data.get("files")
    if files is None:
        issues.append(issue("SCHEMA_INVALID", p, "WARN", "missing 'files' list; soft schema"))
    elif not isinstance(files, list):
        issues.append(issue("SCHEMA_INVALID", p, "ERROR", "'files' must be a list"))
    else:
        for i, f in enumerate(files):
            if not isinstance(f, dict):
                issues.append(issue("SCHEMA_INVALID", f"files[{i}]", "ERROR", "entry must be an object"))
                continue
            path = f.get("path")
            if not path or not isinstance(path, str):
                issues.append(issue("SCHEMA_INVALID", f"files[{i}]", "ERROR", "missing 'path' string"))
                continue
            if not os.path.exists(path):
                issues.append(issue("FILE_MISSING", path, "ERROR", "not found"))

    print(json.dumps({"issues": issues}, ensure_ascii=False))
    # Toujours exit 0. Le gating se fait dans le post-process.
if __name__ == "__main__":
    main()
