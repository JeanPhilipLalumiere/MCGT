#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path

ROOT = Path(".")

RX_DEF_BUILD = re.compile(r'^(\s*)def\s+build_parser\s*\(\s*\)\s*->\s*argparse\.ArgumentParser\s*:\s*$', re.M)
RX_DEF_BUILD_ANY = re.compile(r'^(\s*)def\s+build_parser\s*\([^)]*\)\s*:\s*$', re.M)
RX_NEXT_DEF_OR_MAIN = re.compile(r'^\s*def\s+\w+\s*\(|^\s*if\s+__name__\s*==\s*["\']__main__["\']\s*:', re.M)
RX_ADDARG = re.compile(r'^\s*(p|_p)\.add_argument\s*\(', re.M)
RX_COMMON = re.compile(r'^\s*C\.add_common_plot_args\s*\(\s*(p|_p)\s*\)\s*$', re.M)
RX_PARSE_ARGS_LINE = re.compile(r'^\s*args\s*=\s*\w+\s*\.parse_args\s*\(\s*\)\s*$', re.M)
RX_ARGPARSE_SPLIT = re.compile(r'^\s*(p|_p)\s*=\s*argparse\s*$', re.M)
RX_ARGPARSE_DOT = re.compile(r'^\s*\.ArgumentParser\s*\(', re.M)
RX_DESC_LINE = re.compile(r'\bdescription\s*=\s*([^)\n]+)\)?')

def find_block(s: str):
    m = RX_DEF_BUILD_ANY.search(s)
    if not m:
        return None
    start = m.start()
    indent = m.group(1)
    m2 = RX_NEXT_DEF_OR_MAIN.search(s, m.end())
    end = m2.start() if m2 else len(s)
    return start, end, indent

def rebuild_block(block_src: str, indent: str, fname: str) -> str:
    # 1) Collect description
    desc = None
    mdesc = RX_DESC_LINE.search(block_src)
    if mdesc:
        desc = mdesc.group(1).strip()
        # garde tel quel: "description=..." déjà capturé sans le préfixe
        if not desc.startswith("description"):
            desc = f"description={desc}"
        else:
            # si on a capturé déjà "description=..." (rare), on garde
            pass
    else:
        # fallback depuis le nom de fichier
        title = Path(fname).stem.replace("_", " ")
        desc = f'description="{title}"'
    # 2) Détecter add_common_plot_args
    has_common = bool(RX_COMMON.search(block_src))
    # 3) Récupérer toutes les lignes p.add_argument(...) avec leurs continuations parenthèses
    lines = block_src.splitlines()
    add_lines = []
    i = 0
    while i < len(lines):
        if RX_ADDARG.match(lines[i]):
            chunk = [lines[i]]
            # capturer continuation jusqu'à fermeture paren équilibrée
            paren = lines[i].count("(") - lines[i].count(")")
            j = i + 1
            while j < len(lines) and paren > 0:
                chunk.append(lines[j])
                paren += lines[j].count("(") - lines[j].count(")")
                j += 1
            add_lines.append("\n".join(chunk))
            i = j
        else:
            i += 1
    # 4) Construire bloc propre
    IND = indent + "    "
    pieces = []
    pieces.append(f"{indent}def build_parser() -> argparse.ArgumentParser:")
    pieces.append(f"{IND}p = argparse.ArgumentParser({desc})")
    if has_common:
        pieces.append(f"{IND}C.add_common_plot_args(p)")
    for L in add_lines:
        # re-indent chaque ligne sur IND
        L2 = "\n".join(IND + l.lstrip() for l in L.splitlines())
        pieces.append(L2)
    pieces.append(f"{IND}return p")
    return "\n".join(pieces) + "\n"

def patch_file(path: Path) -> tuple[bool, str]:
    s = path.read_text(encoding="utf-8", errors="replace")
    changed = False

    # Supprimer les 'args = p.parse_args()' dans tout le fichier (ils appartiennent à main, pas build_parser)
    s2, n_rm = RX_PARSE_ARGS_LINE.subn("", s)
    if n_rm:
        changed = True
        s = s2

    blk = find_block(s)
    if not blk:
        return changed, "NO_BUILD_PARSER"

    start, end, indent = blk
    block_src = s[start:end]

    # Si on voit le split 'p = argparse' puis '.ArgumentParser(' sur deux lignes → on reconstruit
    needs_rebuild = bool(RX_ARGPARSE_SPLIT.search(block_src) and RX_ARGPARSE_DOT.search(block_src))
    # Ou si la signature n'est pas typée → on homogénéise quand même (et on corrige indentations)
    needs_rebuild = needs_rebuild or not RX_DEF_BUILD.search(block_src)

    if needs_rebuild:
        new_block = rebuild_block(block_src, indent, str(path))
        s = s[:start] + new_block + s[end:]
        changed = True

    if changed:
        path.write_text(s, encoding="utf-8")
    return changed, "OK" if changed else "UNCHANGED"

def main():
    targets = []
    for p in ROOT.rglob("zz-scripts/**/*.py"):
        targets.append(p)
    changed = 0
    for p in sorted(targets):
        c, msg = patch_file(p)
        if c:
            changed += 1
            print(f"[fixed] {p}")
        elif msg not in ("NO_BUILD_PARSER","UNCHANGED"):
            print(f"[warn ] {p}: {msg}")
    print(f"Done. Files changed: {changed}")

if __name__ == "__main__":
    main()
