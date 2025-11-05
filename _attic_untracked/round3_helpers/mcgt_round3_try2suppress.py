#!/usr/bin/env python3
from __future__ import annotations
import time, re
from pathlib import Path

ROOT = Path.cwd()
TS   = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
EXCLUDE = {".git", "__pycache__", ".ci-out", ".mypy_cache", ".tox", "_attic_untracked", "release_zenodo_codeonly"}

def iter_py():
    for p in ROOT.rglob("*.py"):
        parts = set(p.parts)
        if parts & EXCLUDE: 
            continue
        if p.is_file():
            yield p

def detab(s: str, tabsize: int = 4) -> str:
    return s.expandtabs(tabsize)

def indent_width(line: str) -> int:
    lead = line[:len(line) - len(line.lstrip(" \t"))]
    return len(detab(lead))

def is_handler_line(s: str) -> bool:
    t = s.lstrip()
    return t.startswith("except ") or t.startswith("except:") or t.startswith("finally:")

def is_blank_or_comment(s: str) -> bool:
    t = s.strip()
    return (t == "") or t.startswith("#")

def ensure_import_contextlib(lines: list[str]) -> list[str]:
    text = "".join(lines)
    if re.search(r'(^|\n)\s*import\s+contextlib(\s|$)', text) or \
       re.search(r'(^|\n)\s*from\s+contextlib\s+import\s+suppress(\s|,|$)', text):
        return lines
    # repère bloc __future__ + éventuel docstring
    i = 0
    n = len(lines)
    # skip shebang/encoding
    while i < n and (lines[i].startswith("#!") or lines[i].lower().startswith("# -*- coding")):
        i += 1
    # docstring module ?
    if i < n and re.match(r'^\s*(?:[rubf]?["\']){3}', lines[i]):
        q = lines[i].strip()[0]
        # avance jusqu'à fin du docstring (naïf mais OK ici)
        i += 1
        while i < n and not re.search(r'"""|\'\'\'', lines[i]):
            i += 1
        if i < n:
            i += 1
    # blocs from __future__
    while i < n and re.match(r'^\s*from\s+__future__\s+import\s+', lines[i]):
        i += 1
    # insère
    lines[i:i] = ["import contextlib\n"]
    return lines

def fix_file(src: str) -> tuple[str, int, int]:
    lines = src.splitlines(True)
    i = 0
    changed = 0
    removed_handlers = 0

    while i < len(lines):
        li = lines[i]
        if li.lstrip().startswith("try:"):
            base = indent_width(li)
            j = i + 1
            saw_body = False
            handler_at = None
            # avance jusqu'à première dé-indentation <= base OU EOF
            while j < len(lines):
                lj = lines[j]
                if is_blank_or_comment(lj):
                    j += 1
                    continue
                ind = indent_width(lj)
                if ind > base:
                    saw_body = True
                    j += 1
                    continue
                # retour à indent <= base : possible fin de bloc
                if ind == base and is_handler_line(lj):
                    handler_at = j
                break
            # si pas de handler trouvé au même indent → orphelin
            if handler_at is None:
                # remplace le 'try:' par 'with contextlib.suppress(Exception):'
                lines[i] = (" " * base) + "with contextlib.suppress(Exception):\n"
                changed += 1
                # Si une passe précédente avait inséré un handler juste après le bloc,
                # on tente de le supprimer (pattern exact 'except Exception:' + 'pass').
                k = j
                # sauter blancs/commentaires
                while k < len(lines) and is_blank_or_comment(lines[k]):
                    k += 1
                if k < len(lines) and indent_width(lines[k]) == base and lines[k].lstrip().startswith("except Exception:"):
                    # remove 'except' + éventuel 'pass' indenté
                    del lines[k]
                    if k < len(lines) and indent_width(lines[k]) > base and lines[k].lstrip().startswith("pass"):
                        del lines[k]
                    removed_handlers += 1
                # avance prudemment
                i = j
                continue
        i += 1

    if changed:
        lines = ensure_import_contextlib(lines)
    return "".join(lines), changed, removed_handlers

def main():
    patched = 0
    removed = 0
    files = 0
    for p in iter_py():
        try:
            src = p.read_text(encoding="utf-8", errors="ignore")
        new, c, r = fix_file(src)
        if c or r:
            bak = p.with_suffix(p.suffix + f".bak.{TS}")
            bak.write_text(src, encoding="utf-8")
            p.write_text(new, encoding="utf-8")
            patched += (1 if c else 0)
            removed += r
        files += 1
    print(f"[suppress] scanned={files}, patched_files={patched}, removed_bad_handlers={removed}")

if __name__ == "__main__":
    main()
