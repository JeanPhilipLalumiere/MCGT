#!/usr/bin/env python3
import ast, json, subprocess, sys
from pathlib import Path

OUT = Path(".ci-out/scan/ast_scan_summary.json")
OUT.parent.mkdir(parents=True, exist_ok=True)

def git_ls_py():
    try:
        out = subprocess.check_output(["git", "ls-files", "*.py"], text=True)
        return [Path(p) for p in out.splitlines() if p.strip()]
    except Exception as e:
        print("git ls-files failed:", e, file=sys.stderr)
        return []

def analyze(path: Path):
    src = path.read_text(encoding="utf-8", errors="replace")
    try:
        tree = ast.parse(src, filename=str(path))
    except Exception:
        return None
    imports, froms, defs = [], [], []
    has_main, shebang = False, None
    if src.startswith("#!"):
        shebang = src.splitlines()[0].strip()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for n in node.names:
                if n.name:
                    imports.append(n.name)
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                froms.append(node.module)
        elif isinstance(node, ast.FunctionDef):
            defs.append(node.name)
        elif isinstance(node, ast.If):
            # detect "if __name__ == '__main__':"
            test = ast.get_source_segment(src, node.test) or ""
            if "__name__" in test and "__main__" in test:
                has_main = True
    return {
        "path": str(path),
        "imports": imports,
        "froms": froms,
        "defs": defs,
        "has_main": has_main,
        "shebang": shebang,
        "size": path.stat().st_size if path.exists() else 0,
    }

files = git_ls_py()
rows = []
for p in files:
    r = analyze(p)
    if r: rows.append(r)

data = {"repo_root": str(Path(".").resolve()), "num_py": len(files), "files": rows}
OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Wrote {OUT} (git-tracked only: {len(files)} files)")
