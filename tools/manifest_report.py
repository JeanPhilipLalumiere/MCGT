import datetime
import json
import os

src = "assets/zz-manifests/manifest_master.json"
dst = "assets/zz-manifests/manifest_report.md"
if not os.path.exists(src):
    print("SKIP:", src, "(missing)")
    raise SystemExit(0)
m = json.load(open(src, encoding="utf-8"))
ts = datetime.datetime.now(datetime.UTC).isoformat() + "Z"
hdr = ["# Manifest Report", f"- source: {src}", f"- generated: {ts}", ""]


def sec(title, items):
    out = [f"## {title}", ""]
    if not items:
        out.append("*none*")
        out.append("")
        return out
    for s in items:
        if isinstance(s, dict):
            line = "- " + str(s.get("path") or s.get("file") or s)
        else:
            line = "- " + str(s)
        out.append(line)
    out.append("")
    return out


body = []
body += sec("Files", m.get("files", []))
body += sec("Data", m.get("data", []))
body += sec("Artifacts", m.get("artifacts", []))
open(dst, "w", encoding="utf-8").write("\n".join(hdr + body))
print("Wrote", dst)
