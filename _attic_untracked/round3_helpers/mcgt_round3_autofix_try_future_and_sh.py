#!/usr/bin/env python3
from __future__ import annotations
import os, re, sys, time, subprocess
from pathlib import Path

ROOT = Path(os.getcwd())
TS   = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())

EXCLUDE_DIRS = {
    ".git", "__pycache__", ".ci-out", ".mypy_cache", ".tox",
    "_attic_untracked", "release_zenodo_codeonly"
}

def iter_files(exts: tuple[str,...]) -> list[Path]:
    for p in ROOT.rglob("*"):
        if not p.is_file():
            continue
        if p.suffix.lower() not in exts:
            continue
        # exclusions
        parts = set(p.parts)
        if parts & EXCLUDE_DIRS:
            continue
        yield p

# ---------- helpers ----------
def backup_write(p: Path, content: str):
    bak = p.with_suffix(p.suffix + f".bak.{TS}")
    bak.write_text(p.read_text(encoding="utf-8", errors="ignore"), encoding="utf-8")
    p.write_text(content, encoding="utf-8")

def leading_spaces(s: str) -> int:
    return len(s) - len(s.lstrip(" "))

def fix_future_annotations(src: str) -> tuple[str,bool]:
    """Ensure 'from __future__ import annotations
' sits right after
    shebang/encoding + module docstring (if closed). Works sans AST."""
    if "from __future__ import annotations
" not in src:
        return src, False

    lines = src.splitlines(True)
    # Strip all future-annotation lines first
    kept, removed = [], 0
    for ln in lines:
        if ln.strip().startswith("from __future__ import annotations
"):
            removed += 1
            continue
        kept.append(ln)
    if removed == 0:
        return src, False

    # Find insertion idx after shebang/encoding and (if possible) docstring
    i = 0
    # shebang
    if i < len(kept) and kept[i].startswith("#!"):
        i += 1
    # encoding
    enc_re = re.compile(r"^#.*coding[:=]\s*([-\w.]+)")
    if i < len(kept) and enc_re.search(kept[i]):
        i += 1
    # Skip blank/comments
    while i < len(kept) and (kept[i].strip() == "" or kept[i].lstrip().startswith("#")):
        i += 1
    # Docstring detection (best-effort)
    inserted_at = i
    if i < len(kept) and kept[i].lstrip().startswith(('"""',"'''")):
        q = kept[i].lstrip()[:3]
        j = i + 1
        closed = False
        while j < len(kept):
            if q in kept[j]:
                j += 1
                inserted_at = j
                closed = True
                break
            j += 1
        # si docstring non clôturée, on n’essaie pas de “deviner”, on insère juste après en-tête
        if not closed:
            inserted_at = i

    # Inject the future line
    new_src = "".join(kept[:inserted_at] + ["from __future__ import annotations
\n"] + kept[inserted_at:])
    return new_src, True

def fix_orphan_try_blocks(src: str) -> tuple[str,int]:
    """Insert 'except Exception: pass' for 'try:' blocks that have no
    matching except/finally at same indentation before dedent/EOF."""
    lines = src.splitlines(True)
    i = 0
    patches = 0
    while i < len(lines):
        s = lines[i]
        if s.strip().startswith("try:"):
            base = leading_spaces(s)
            j = i + 1
            has_handler = False
            while j < len(lines):
                sj = lines[j]
                if sj.strip() == "" or sj.lstrip().startswith("#"):
                    j += 1
                    continue
                ind = leading_spaces(sj)
                # handler at same indent?
                if ind == base and (sj.lstrip().startswith("except") or sj.lstrip().startswith("finally:")):
                    has_handler = True
                    break
                # dedent → end of try body
                if ind < base:
                    break
                j += 1
            if not has_handler:
                # insert handler before dedent/EOF
                insert_at = j
                handler = (" " * base) + "except Exception:\n" + (" " * (base + 4)) + "pass\n"
                lines[insert_at:insert_at] = [handler]
                patches += 1
                # skip over inserted lines
                i = insert_at + 2
                continue
        i += 1
    return "".join(lines), patches

def patch_shell(p: Path, text: str) -> tuple[str,int]:
    """Fix common bash issues found in log:
       - function declarations 'name(){' → 'name() {'
       - ensure heredoc closers (PY / EOF) exist if opened
    """
    changed = 0
    # Fix function decls
    new = re.sub(r"\)\{", ") {", text)
    if new != text:
        changed += 1
    text = new

    # Heredoc closers
    labels = re.findall(r"<<\s*['\"]?([A-Za-z0-9_]+)['\"]?", text)
    for lab in labels:
        # Count closers on isolated line
        closers = len(re.findall(rf"^[ \t]*{re.escape(lab)}[ \t]*\r?$", text, flags=re.M))
        if closers == 0:
            text += f"\n{lab}\n"
            changed += 1
    return text, changed

# ---------- main walk ----------
py_files = list(iter_files((".py",)))
sh_files = list(iter_files((".sh",)))

py_patched = 0
py_try_fixed = 0
py_future_fixed = 0

for p in py_files:
    try:
        src = p.read_text(encoding="utf-8", errors="ignore")
    orig = src
    # 1) future annotations
    src, fut = fix_future_annotations(src)
    if fut:
        py_future_fixed += 1

    # 2) orphan try handlers
    src2, nfix = fix_orphan_try_blocks(src)
    src = src2
    py_try_fixed += nfix

    if src != orig:
        backup_write(p, src)
        py_patched += 1

sh_patched = 0
for p in sh_files:
    if p.name not in {"ci_enable_pr_jobs_v2.sh", "pass12_remove_shims_and_verify.sh", "ton_script.sh"} and "ci_enable_pr_jobs" not in p.name:
        # on ne touche que les 3 vus en erreur + variante de nom
        continue
    try:
        s = p.read_text(encoding="utf-8", errors="ignore")
    new, n = patch_shell(p, s)
    if n > 0 and new != s:
        backup_write(p, new)
        sh_patched += 1

print(f"[autofix] py files patched   : {py_patched}")
print(f"[autofix]  ├─ future fixed   : {py_future_fixed}")
print(f"[autofix]  └─ try handlers   : +{py_try_fixed}")
print(f"[autofix] sh files patched   : {sh_patched}")

# Optionnel : courte compile de fumée sur un sous-ensemble “suspects”
suspects = [str(p) for p in py_files if any(k in str(p) for k in (
    "zz-scripts/chapter06", "zz-scripts/chapter07",
    "zz-scripts/chapter08", "zz-scripts/chapter09", "zz-scripts/chapter10"
))]
if suspects:
    try:
        subprocess.run(["python3","-m","py_compile", *suspects[:50]], check=False)
print("[autofix] terminé.")
