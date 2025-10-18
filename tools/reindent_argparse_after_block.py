#!/usr/bin/env python3
from pathlib import Path

ROOTS = ["zz-scripts"]
TRIGS = ("parser.add_argument(", "parser.set_defaults(", "args = parser.parse_args(", "parser = argparse.ArgumentParser(")

def leading(ws: str) -> str:
    return ws[:len(ws) - len(ws.lstrip('\t '))]

def next_indent(prev: str) -> str:
    # Ajoute 4 espaces si spaces, sinon 1 tab si tabs
    if prev.endswith("\t"): return prev + "\t"
    return prev + "    "

def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)
    changed = False

    def prev_nonempty(i):
        j = i-1
        while j >= 0 and lines[j].strip() == "":
            j -= 1
        return j

    for i, raw in enumerate(lines):
        ls = raw.lstrip()
        if ls.startswith(TRIGS) and not raw[:1].isspace():
            j = prev_nonempty(i)
            if j >= 0:
                prev = lines[j].rstrip("\n")
                if prev.rstrip().endswith(":"):
                    base = leading(prev)
                    lines[i] = next_indent(base) + ls  # ré-indente
                    if not lines[i].endswith("\n"): lines[i] += "\n"
                    changed = True

    if changed:
        bak = p.with_suffix(p.suffix + ".bak_reindent_argparse")
        if not bak.exists(): bak.write_text(txt, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
    return changed

def main():
    changed = 0
    for root in ROOTS:
        for p in Path(root).rglob("*.py"):
            try:
                if process(p): changed += 1
            except Exception:
                pass
    print(f"[OK] re-indented argparse lines after block openers in {changed} file(s)")

if __name__ == "__main__":
    main()
