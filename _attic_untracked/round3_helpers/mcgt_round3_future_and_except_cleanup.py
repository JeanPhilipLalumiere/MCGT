#!/usr/bin/env python3
from __future__ import annotations
import re, time
from pathlib import Path

ROOT = Path.cwd()
TS   = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
EXCLUDE = {".git", "__pycache__", ".ci-out", ".mypy_cache", ".tox",
           "_attic_untracked", "release_zenodo_codeonly"}

TRIPLE = re.compile(r'^\s*(?:[rubfRUBF]?){0,2}("""|\'\'\')')
FUTURE = re.compile(r'^\s*from\s+__future__\s+import\s+(.+)$')
ENCOD  = re.compile(r'^\s*#\s*-\*-\s*coding:\s*.*-\*-\s*$')

def detab(s: str, tabsize: int = 4) -> str:
    return s.expandtabs(tabsize)

def indent(line: str) -> int:
    lead = line[:len(line) - len(line.lstrip(" \t"))]
    return len(detab(lead))

def move_future_to_top(lines: list[str]) -> tuple[list[str], int]:
    """Collecte toutes les lignes from __future__..., les retire,
    puis les réinsère au tout début (après shebang/encoding + docstring module)."""
    futures: list[str] = []
    out: list[str] = []
    for s in lines:
        m = FUTURE.match(s)
        if m:
            futures.append(s.strip() + ("\n" if not s.endswith("\n") else ""))
        else:
            out.append(s)

    if not futures:
        return lines, 0

    # Déterminer point d’insertion
    i = 0
    n = len(out)
    # shebang
    if i < n and out[i].startswith("#!"):
        i += 1
    # encoding
    if i < n and ENCOD.match(out[i] or ""):
        i += 1
    # docstring module
    if i < n and TRIPLE.match(out[i] or ""):
        q = out[i][out[i].find(TRIPLE.match(out[i]).group(1))]  # just to use group
        # avancer jusqu'à fermeture
        i += 1
        while i < n and not TRIPLE.search(out[i]):
            i += 1
        if i < n:
            i += 1

    # Nettoyage doublons et ordre stable (conserver annotations en tête si présent)
    uniq = []
    seen = set()
    for f in futures:
        if f not in seen:
            seen.add(f); uniq.append(f)
    uniq.sort(key=lambda s: (0 if "annotations" in s else 1, s))

    # Insérer futures, puis s’assurer que *tous* les imports (ex. contextlib) restent après
    new_lines = out[:i] + uniq + out[i:]
    return new_lines, len(uniq)

def prune_stray_handlers(lines: list[str]) -> tuple[list[str], int]:
    """Supprime tout bloc 'except|finally' au même indent qui ne suit pas un 'try:'
       OU qui suit un 'with contextlib.suppress(Exception):' (cas des seeds transformés)."""
    i = 0
    removed = 0
    n = len(lines)
    while i < n:
        s = lines[i]
        t = s.lstrip()
        if t.startswith("except") or t.startswith("finally:"):
            base = indent(s)
            # remonter au précédent non vide/non comment au même indent
            j = i - 1
            prev = None
            while j >= 0:
                sj = lines[j]
                if sj.strip() == "" or sj.lstrip().startswith("#"):
                    j -= 1; continue
                if indent(sj) == base:
                    prev = sj.lstrip()
                break
            stray = True
            if prev is not None:
                if prev.startswith("try:"):
                    stray = False
                if prev.startswith("with contextlib.suppress("):
                    stray = True
            # Si handler orphelin → supprimer le bloc (ligne + suite indentée)
            if stray:
                k = i + 1
                while k < n:
                    if lines[k].strip() == "": 
                        k += 1; continue
                    if indent(lines[k]) > base:
                        k += 1; continue
                    break
                del lines[i:k]
                n = len(lines)
                removed += 1
                continue  # ne pas avancer i, on est déjà sur la ligne suivante
        i += 1
    return lines, removed

def process_file(p: Path) -> tuple[int,int]:
    try:
        src = p.read_text(encoding="utf-8", errors="ignore")
    lines = src.splitlines(True)
    lines1, nf = move_future_to_top(lines)
    lines2, rm = prune_stray_handlers(lines1)
    if nf or rm:
        bak = p.with_suffix(p.suffix + f".bak.{TS}")
        try:
            bak.write_text("".join(lines), encoding="utf-8")
            p.write_text("".join(lines2), encoding="utf-8")
    return (nf, rm)

def main():
    total_nf = 0
    total_rm = 0
    scanned = 0
    for p in ROOT.rglob("*.py"):
        parts = set(p.parts)
        if parts & EXCLUDE: 
            continue
        if not p.is_file():
            continue
        scanned += 1
        nf, rm = process_file(p)
        total_nf += nf
        total_rm += rm
    print(f"[future+except] scanned={scanned}, moved_future={total_nf}, pruned_handlers={total_rm}")

if __name__ == "__main__":
    main()
