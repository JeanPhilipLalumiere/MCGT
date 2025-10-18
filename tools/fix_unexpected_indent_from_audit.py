#!/usr/bin/env python3
from pathlib import Path
import json

AUDIT = Path("zz-manifests/audit_sweep.json")
TRIGS = (
    "parser.add_argument(",
    "parser.set_defaults(",
    "args = parser.parse_args(",
)
SAFE_TOPLEVEL = ("def ", "class ", "import ", "from ", "if __name__" )

def prev_nonempty(lines, i):
    j = i-1
    while j >= 0 and lines[j].strip() == "":
        j -= 1
    return j

def is_block_opener(line: str) -> bool:
    s = line.rstrip()
    return s.endswith(":") and not s.strip().startswith("#")

def dedent_block(lines, start):
    i = start
    changed = False
    while i < len(lines):
        raw = lines[i]
        s = raw.lstrip()
        if raw.strip()=="":
            break
        if not raw[0].isspace():
            break
        if not (s.startswith(TRIGS) or s.startswith(SAFE_TOPLEVEL)):
            break
        # dé-dente totalement cette ligne
        if raw != s:
            lines[i] = s
            changed = True
        i += 1
    return changed

def process_file(path: Path, lineno: int) -> bool:
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    idx = max(0, min(len(lines)-1, lineno-1))
    ln = lines[idx]
    if not ln or not ln[0].isspace():
        return False  # pas indenté finalement
    s = ln.lstrip()

    # vérifie le contexte : si la ligne précédente non vide n'ouvre pas de bloc, on peut dé-denter
    j = prev_nonempty(lines, idx)
    prev = lines[j] if j >= 0 else ""
    if is_block_opener(prev):
        return False  # on est bien dans un bloc : ne pas tripoter

    # cible : argparse ou constructions toplevel évidentes
    if s.startswith(TRIGS) or s.startswith(SAFE_TOPLEVEL):
        changed = dedent_block(lines, idx)
        if changed:
            path.write_text("".join(lines), encoding="utf-8")
        return changed
    return False

def main():
    d = json.loads(AUDIT.read_text(encoding="utf-8"))
    changed = 0
    for f in d.get("files", []):
        e = f.get("error") or {}
        if f.get("compile") != "OK" and e.get("type") == "SyntaxError" and "unexpected indent" in (e.get("msg") or ""):
            p = Path(f["path"])
            if p.exists():
                if process_file(p, int(e.get("lineno") or 1)):
                    changed += 1
    print(f"[OK] dedented {changed} file(s)")

if __name__ == "__main__":
    main()
