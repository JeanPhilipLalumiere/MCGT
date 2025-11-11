# zz-tools/guard_runner.py
#!/usr/bin/env python3
import json, os, sys, subprocess

def validate_one(p: str):
    try:
        out = subprocess.check_output(
            [sys.executable, "zz-tools/validate_manifest.py", p],
            stderr=subprocess.STDOUT,
        )
        return json.loads(out.decode("utf-8", "replace")).get("issues", [])
    except subprocess.CalledProcessError as e:
        try:
            return json.loads(e.output.decode("utf-8", "replace")).get("issues", [])
        except Exception:
            return [{
                "code": "JSON_INVALID",
                "path": p,
                "severity": "ERROR",
                "message": "validator crashed"
            }]
    except Exception as e:
        return [{
            "code": "JSON_INVALID",
            "path": p,
            "severity": "ERROR",
            "message": str(e)
        }]

manifs = [
    m for m in [
        "zz-manifests/manifest_master.json",
        "zz-manifests/manifest_publication.json",
    ] if os.path.isfile(m)
]

issues = []
for m in manifs:
    issues.extend(validate_one(m))

with open("diag_report.json", "w", encoding="utf-8") as f:
    json.dump({"issues": issues}, f, indent=2)

print(f"[guard_runner] manifests={len(manifs)} issues={len(issues)}")
