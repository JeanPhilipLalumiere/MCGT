#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUD  = ROOT / "zz-manifests/audit_sweep.json"
OUT1 = ROOT / "zz-manifests/compile_fail_context.md"
OUT2 = ROOT / "zz-manifests/args_missing_context.md"

def read_lines(p: Path):
    try:
        return p.read_text(encoding="utf-8", errors="ignore").splitlines()
    except Exception:
        return []

def snippet(lines, lineno, radius=5):
    i = max(1, lineno - radius); j = min(len(lines), lineno + radius)
    out = []
    for k in range(i, j+1):
        prefix = ">>" if k == lineno else "  "
        body = lines[k-1] if 1 <= k <= len(lines) else ""
        out.append(f"{prefix} {k:5d}: {body}")
    return "\n".join(out)

def main():
    rep = json.loads(AUD.read_text(encoding="utf-8"))
    files = rep.get("files", [])

    # 1) Compile fails
    buf1 = ["# Compile failures: contexte par fichier\n"]
    for f in files:
        if f.get("compile") == "OK":
            continue
        path = ROOT / f["path"]
        err  = f.get("error", {})
        ln   = err.get("lineno")
        kind = err.get("type")
        msg  = err.get("msg")
        buf1.append(f"\n## {f['path']} :: {kind} L{ln}: {msg}")
        lines = read_lines(path)
        if ln:
            buf1.append("```text")
            buf1.append(snippet(lines, ln, radius=6))
            buf1.append("```")
    OUT1.write_text("\n".join(buf1) + "\n", encoding="utf-8")
    print(f"[OK] wrote {OUT1}")

    # 2) Args missing
    buf2 = ["# Arguments utilisés mais non définis: occurrences\n"]
    for f in files:
        miss = f.get("args_missing") or []
        if not miss:
            continue
        path = ROOT / f["path"]
        lines = read_lines(path)
        where_used = f.get("where_used") or {}
        buf2.append(f"\n## {f['path']}")
        for name in miss:
            buf2.append(f"- `{name}`:")
            for ln in sorted(where_used.get(name, [])):
                buf2.append(f"  - L{ln}")
                buf2.append("  ```text")
                buf2.append(snippet(lines, ln, radius=3))
                buf2.append("  ```")
    OUT2.write_text("\n".join(buf2) + "\n", encoding="utf-8")
    print(f"[OK] wrote {OUT2}")

if __name__ == "__main__":
    main()
