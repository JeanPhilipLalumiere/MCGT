#!/usr/bin/env python3
from pathlib import Path
import json

AUDIT = Path("zz-manifests/audit_sweep.json")
TRIGS_SAFE_TOP = (
    "import ", "from ", "def ", "class ",
    "parser.add_argument(", "parser.set_defaults(", "args = parser.parse_args(", "parser = argparse.ArgumentParser("
)

def prev_nonempty(lines, i):
    j = i - 1
    while j >= 0 and lines[j].strip() == "":
        j -= 1
    return j

def line_opens_block(s: str) -> bool:
    s = s.rstrip()
    return s.endswith(":") and not s.lstrip().startswith("#")

def dedent_if_safe(lines, i) -> bool:
    raw = lines[i]
    if not raw[:1].isspace():
        return False
    j = prev_nonempty(lines, i)
    prev = lines[j] if j >= 0 else ""
    if line_opens_block(prev):   # ne pas casser une suite de bloc
        return False
    if raw.lstrip().startswith("@"):  # ne touche pas aux décorateurs
        return False
    ls = raw.lstrip()
    if ls != raw:
        lines[i] = ls
        return True
    return False

def prepass_toplevel(lines) -> int:
    changed = 0
    cap = min(len(lines), 140)  # zone "header"
    for i in range(cap):
        raw = lines[i]
        if raw[:1].isspace():
            ls = raw.lstrip()
            if any(ls.startswith(t) for t in TRIGS_SAFE_TOP):
                j = prev_nonempty(lines, i)
                prev = lines[j] if j >= 0 else ""
                if not line_opens_block(prev):
                    if ls != raw:
                        lines[i] = ls
                        changed += 1
    return changed

def heal_file(p: Path, lineno: int|None) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)
    changed = False
    changed |= prepass_toplevel(lines) > 0
    if lineno and 1 <= lineno <= len(lines):
        changed |= dedent_if_safe(lines, lineno - 1)
    if changed:
        p.with_suffix(p.suffix + ".bak_healindent2").write_text(txt, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
    return changed

def main():
    if not AUDIT.exists():
        print("[ERR] audit_sweep.json manquant. Lance d'abord mcgt_sweeper.py.")
        return
    data = json.loads(AUDIT.read_text(encoding="utf-8"))
    first_errors = data.get("first_errors") or []
    touched = 0
    for err in first_errors:
        msg = (err.get("msg") or "").lower()
        if "unexpected indent" not in msg:
            continue
        path = err.get("path")
        lineno = err.get("lineno")
        p = Path(path) if path else None
        if not p or p.suffix != ".py" or not p.exists():
            continue
        if heal_file(p, lineno):
            print(f"[FIX] {p}:{lineno}")
            touched += 1
    print(f"[OK] healed {touched} file(s)")
if __name__ == "__main__":
    main()
