#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path

ROOT = Path("zz-scripts")

RX_GLUE = re.compile(
    r"(?m)^(?P<indent>\s*)(?P<var>\w+)\s*=\s*argparse\s*\r?\n\s*\.\s*ArgumentParser\s*\(")
# Ex.:    p = argparse
#         .ArgumentParser(     →   p = argparse.ArgumentParser(
#
# Marche pour p, _p, ap, parser…

RX_FUTURE = re.compile(r'^\s*from\s+__future__\s+import\s+[^\n]+$', re.M)

# description potentiellement ouverte sur plusieurs lignes → on la neutralise proprement
# On cible l’argument description= jusqu’à la prochaine parenthèse fermante OU fin de ligne
RX_DESC = re.compile(r'(\bArgumentParser\s*\([^)]*?)\bdescription\s*=\s*"([^"]*)"?', re.S)

def move_future_to_top(txt: str) -> str:
    # Conserve shebang/encoding, rassemble tous les imports __future__ au bon endroit (après eux)
    lines = txt.splitlines(True)
    shebang = []
    start = 0
    if lines and lines[0].startswith("#!"):
        shebang.append(lines[0]); start = 1
    if start < len(lines) and "coding" in lines[start][:40]:
        shebang.append(lines[start]); start += 1

    futures = RX_FUTURE.findall("".join(lines))
    if not futures:  # rien à déplacer
        return txt
    # retire toutes les lignes futuristes
    lines_wo = [l for l in lines if not RX_FUTURE.match(l)]
    # insère bloc future après entête
    insert = "".join(shebang) + "".join(set("from __future__ import " + f.split("import",1)[1].strip() + "\n" for f in futures))
    body = "".join(lines_wo[start:])
    return insert + body

def fix_file(p: Path) -> bool:
    s = p.read_text(encoding="utf-8", errors="replace")
    orig = s

    # 1) coller argparse + .ArgumentParser(
    s = RX_GLUE.sub(lambda m: f"{m.group('indent')}{m.group('var')} = argparse.ArgumentParser(", s)

    # 2) neutraliser descriptions possiblement cassées (on garde le reste des args)
    def _desc_sub(m):
        prefix = m.group(1)
        return prefix + 'description="(autofix)",'
    s = RX_DESC.sub(_desc_sub, s)

    # 3) remonter les imports __future__ tout en haut (après shebang/encoding)
    s = move_future_to_top(s)

    if s != orig:
        p.write_text(s, encoding="utf-8")
        return True
    return False

def main():
    changed = 0
    for p in ROOT.rglob("*.py"):
        if any(seg in p.parts for seg in ("_attic_untracked","_autofix_sandbox","_tmp",".bak")):
            continue
        try:
            if fix_file(p):
                changed += 1
                print("[glue-fixed]", p)
        except Exception as e:
            print("[skip-error]", p, e)
    print("Done. Files changed:", changed)

if __name__ == "__main__":
    main()
