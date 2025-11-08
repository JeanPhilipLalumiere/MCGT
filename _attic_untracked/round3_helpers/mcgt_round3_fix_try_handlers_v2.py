#!/usr/bin/env python3
from __future__ import annotations
import os, re, time
from pathlib import Path

ROOT = Path.cwd()
TS   = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
EXCLUDE = {".git", "__pycache__", ".ci-out", ".mypy_cache", ".tox", "_attic_untracked", "release_zenodo_codeonly"}

def iter_py():
    for p in ROOT.rglob("*.py"):
        parts = set(p.parts)
        if parts & EXCLUDE: 
            continue
        if not p.is_file():
            continue
        yield p

def detab(s: str, tabsize: int = 4) -> str:
    return s.expandtabs(tabsize)

def indent_width(line: str) -> int:
    # Compte l'indentation en traitant TAB→4 espaces
    lead = line[:len(line) - len(line.lstrip(" \t"))]
    return len(detab(lead))

def is_handler_line(s: str) -> bool:
    t = s.lstrip()
    return t.startswith("except ") or t.startswith("except:") or t.startswith("finally:")

def is_blank_or_comment(s: str) -> bool:
    t = s.strip()
    return (t == "") or t.startswith("#")

def backup_and_write(p: Path, new: str):
    bak = p.with_suffix(p.suffix + f".bak.{TS}")
    old = p.read_text(encoding="utf-8", errors="ignore")
    bak.write_text(old, encoding="utf-8")
    p.write_text(new, encoding="utf-8")

def fix_orphan_try(src: str) -> tuple[str, int]:
    """
    Pour chaque 'try:' : si aucun handler (except/finally) n'existe au même indent
    avant la première dé-indentation <= indent_try (ou EOF), insère un handler.
    Si le bloc 'try' est vide (ligne suivante non indentée), insère un 'pass' comme corps.
    """
    lines = src.splitlines(True)
    i = 0
    fixes = 0

    while i < len(lines):
        li = lines[i]
        if li.lstrip().startswith("try:"):
            base = indent_width(li)
            j = i + 1
            saw_body = False
            insert_at = None
            has_handler = False

            # scanner jusqu'à la première dé-indentation stricte (< base) OU EOF
            while j < len(lines):
                lj = lines[j]
                if is_blank_or_comment(lj):
                    j += 1
                    continue
                ind = indent_width(lj)

                # corps valide si strictement plus indenté que 'try:'
                if ind > base:
                    saw_body = True
                    j += 1
                    continue

                # on est revenu à indent <= base → fin du bloc 'try'
                # handler valide s'il est au même indent et commence par except/finally
                if ind == base and is_handler_line(lj):
                    has_handler = True
                insert_at = j
                break

            if j >= len(lines):
                # EOF : pas de handler rencontré
                insert_at = len(lines)

            if not has_handler:
                body_fix = []
                if not saw_body:
                    # bloc vide → ajoute un 'pass' indenté d'un cran
                    body_fix = [(" " * (base + 4)) + "pass\n"]
                handler = [(" " * base) + "except Exception:\n", (" " * (base + 4)) + "pass\n"]
                # insère le body_fix juste après 'try:' si nécessaire
                if body_fix:
                    lines[i+1:i+1] = body_fix
                    insert_at = (insert_at or (i+1)) + len(body_fix)
                # insère le handler juste avant la dé-indentation/EOF
                lines[insert_at:insert_at] = handler
                fixes += 1
                # avance après le handler pour éviter boucles infinies
                i = insert_at + len(handler)
                continue
        i += 1

    return "".join(lines), fixes

def main():
    total_fixed = 0
    patched = 0
    for p in iter_py():
        try:
            src = p.read_text(encoding="utf-8", errors="ignore")
        new, nfix = fix_orphan_try(src)
        if nfix > 0:
            backup_and_write(p, new)
            total_fixed += nfix
            patched += 1
    print(f"[fix-try] files patched: {patched}, handlers inserted: +{total_fixed}")

if __name__ == "__main__":
    main()
