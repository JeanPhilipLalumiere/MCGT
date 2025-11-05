#!/usr/bin/env python3
from __future__ import annotations
import re, time
from pathlib import Path

ROOT = Path.cwd()
TS   = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
EXCLUDE = {".git", "__pycache__", ".ci-out", ".mypy_cache", ".tox",
           "_attic_untracked", "release_zenodo_codeonly"}

ANCHORS = (
    "MCGT_OUTDIR", "args.outdir",
    "matplotlib", "mpl.rcParams",
    "ArgumentParser(", "add_argument(", "logging.basicConfig("
)

def detab(s: str, tabsize: int = 4) -> str:
    return s.expandtabs(tabsize)

def indent_width(line: str) -> int:
    lead = line[:len(line) - len(line.lstrip(" \t"))]
    return len(detab(lead))

def is_handler_line(s: str) -> bool:
    t = s.lstrip()
    return t.startswith("except ") or t.startswith("except:") or t.startswith("finally:")

def ensure_import_contextlib(lines: list[str]) -> None:
    txt = "".join(lines)
    if re.search(r'(^|\n)\s*import\s+contextlib(\s|$)', txt): return
    if re.search(r'(^|\n)\s*from\s+contextlib\s+import\s+suppress(\s|,|$)', txt): return
    i = 0
    n = len(lines)
    # skip shebang/encoding
    while i < n and (lines[i].startswith("#!") or lines[i].lower().startswith("# -*- coding")):
        i += 1
    # docstring module ?
    if i < n and re.match(r'^\s*(?:[rubf]?["\']){3}', lines[i]):
        i += 1
        while i < n and not re.search(r'"""|\'\'\'', lines[i]):
            i += 1
        if i < n: i += 1
    # blocs from __future__
    while i < n and re.match(r'^\s*from\s+__future__\s+import\s+', lines[i]):
        i += 1
    lines.insert(i, "import contextlib\n")

def patch_cli_try_blocks(text: str) -> tuple[str, int, int]:
    lines = text.splitlines(True)
    n     = len(lines)
    changed = 0
    removed_handlers = 0

    # repérer des ancres CLI
    anchor_idx = []
    for i, s in enumerate(lines):
        if any(a in s for a in ANCHORS):
            anchor_idx.append(i)
    if not anchor_idx:
        return text, 0, 0

    # sur chaque ancre, chercher un try: dans la fenêtre [i-8, i]
    for a in anchor_idx:
        start = max(0, a - 8)
        end   = a
        # cherche le dernier "try:" avant l'ancre
        try_i = None
        for j in range(end, start - 1, -1):
            if lines[j].lstrip().startswith("try:"):
                try_i = j
                break
        if try_i is None:
            continue

        base = indent_width(lines[try_i])

        # remplace le try: par un contexte sûr
        if not lines[try_i].lstrip().startswith("with contextlib.suppress(Exception):"):
            lines[try_i] = (" " * base) + "with contextlib.suppress(Exception):\n"
            changed += 1

        # supprimer un handler mal positionné après le bloc
        k = try_i + 1
        # avancer tant que l'indent > base ou lignes vides/commentées
        while k < n:
            if lines[k].strip() == "" or lines[k].lstrip().startswith("#"):
                k += 1; continue
            ind = indent_width(lines[k])
            if ind > base:
                k += 1; continue
            # on a dé-indenté (fin logique du bloc)
            break

        # à partir de k, s'il y a un except au même indent → supprime except + pass indenté
        if k < n and indent_width(lines[k]) == base and lines[k].lstrip().startswith("except Exception:"):
            del lines[k]
            # supprimer un "pass" immédiatement sous-jacent (ind > base)
            if k < len(lines) and indent_width(lines[k]) > base and lines[k].lstrip().startswith("pass"):
                del lines[k]
            removed_handlers += 1
            n = len(lines)

    if changed or removed_handlers:
        ensure_import_contextlib(lines)
    return "".join(lines), changed, removed_handlers

def main():
    patched_files = 0
    removed = 0
    scanned = 0
    for p in ROOT.rglob("*.py"):
        parts = set(p.parts)
        if parts & EXCLUDE: 
            continue
        if not p.is_file():
            continue
        scanned += 1
        try:
            src = p.read_text(encoding="utf-8", errors="ignore")
        new, chg, rem = patch_cli_try_blocks(src)
        if chg or rem:
            bak = p.with_suffix(p.suffix + f".bak.{TS}")
            bak.write_text(src, encoding="utf-8")
            p.write_text(new, encoding="utf-8")
            patched_files += 1
            removed += rem
    print(f"[cli-fix] scanned={scanned}, patched_files={patched_files}, removed_stray_handlers={removed}")

if __name__ == "__main__":
    main()
