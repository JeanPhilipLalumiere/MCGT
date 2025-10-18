#!/usr/bin/env python3
import ast, json, traceback
from pathlib import Path

OUT = Path("zz-manifests/indent_failures.json")

def main():
    records = []
    for p in Path("zz-scripts").rglob("*.py"):
        try:
            src = p.read_text(encoding="utf-8", errors="ignore")
            ast.parse(src)
        except SyntaxError as e:
            records.append({
                "path": str(p),
                "type": "SyntaxError",
                "msg": e.msg,
                "lineno": e.lineno,
                "offset": e.offset,
                "line": (e.text or "").rstrip("\n"),
            })
        except Exception:
            # ignorer les runtime imports, on ne fait que la syntaxe
            pass
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(records, indent=2), encoding="utf-8")
    print(f"[OK] wrote {OUT} (items={len(records)})")
    # aperçu court
    for r in records[:10]:
        print(f"- {r['path']}:{r['lineno']}  {r['msg']}  :: {r['line']!r}")

if __name__ == "__main__":
    main()
