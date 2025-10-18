#!/usr/bin/env python3
from pathlib import Path
import json

AUDIT = Path("zz-manifests/audit_sweep.json")
TRIGS = ("parser.add_argument(", "parser.set_defaults(", "args = parser.parse_args(")
SAFE_TOPLEVEL = ("def ", "class ", "import ", "from ", "if __name__")

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
        if raw.strip() == "":
            break
        s = raw.lstrip()
        # on ne touche que les lignes toplevel candidates
        if not raw[:1].isspace():  # déjà toplevel -> stop
            break
        if not (s.startswith(TRIGS) or s.startswith(SAFE_TOPLEVEL)):
            break
        if raw != s:
            lines[i] = s
            changed = True
        i += 1
    return changed

def fix_one(path: Path, lineno: int) -> bool:
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    idx = max(0, min(len(lines)-1, (lineno or 1)-1))
    raw = lines[idx]
    if not raw[:1].isspace():
        return False
    s = raw.lstrip()

    j = prev_nonempty(lines, idx)
    prev = lines[j] if j >= 0 else ""
    if is_block_opener(prev):
        return False  # réellement dans un bloc: on n'y touche pas

    if s.startswith(TRIGS) or s.startswith(SAFE_TOPLEVEL):
        changed = dedent_block(lines, idx)
        if changed:
            path.write_text("".join(lines), encoding="utf-8")
        return changed
    return False

def run_pass() -> int:
    d = json.loads(AUDIT.read_text(encoding="utf-8"))
    changed = 0
    for f in d.get("files", []):
        e = f.get("error") or {}
        if f.get("compile") != "OK" and e.get("type") == "SyntaxError" and "unexpected indent" in (e.get("msg") or ""):
            p = Path(f["path"])
            if p.exists() and fix_one(p, int(e.get("lineno") or 1)):
                changed += 1
    return changed

def main():
    total = 0
    for _ in range(6):  # jusqu'à 6 passes
        ch = run_pass()
        total += ch
        print(f"[pass] changed={ch}")
        if ch == 0:
            break
        # refresh audit entre les passes
        import subprocess
        subprocess.run(["python3", "tools/mcgt_sweeper.py"], check=False)
        subprocess.run(["python3", "tools/mcgt_blockers_extract.py"], check=False)
    print(f"[OK] total dedented {total} file(s)")

if __name__ == "__main__":
    main()
