#!/usr/bin/env python3
from __future__ import annotations
import ast
import hashlib
import io
import sys
import time
from pathlib import Path
from typing import Any

ROOT = Path.cwd()
COMMON_DIR = ROOT / "zz-scripts" / "_common"
FILES = [
    "__init__.py",
    "cli.py",
    "style.py",
    "validate.py",
    "logging.py",
    "profiles.py",
]

REPORT_MD = ROOT / "_reports" / "common_summary.md"
SRC_DIR = ROOT / "_reports" / "common_sources"
SRC_DIR.mkdir(parents=True, exist_ok=True)


def sha256_file(p: Path, chunk: int = 8 * 1024 * 1024) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def read_text_safely(p: Path) -> str:
    with p.open("rb") as f:
        raw = f.read()
    # crude encoding detection fallback
    for enc in ("utf-8", "utf-8-sig", "latin-1"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("utf-8", errors="replace")


def nl_numbered(s: str) -> str:
    out = io.StringIO()
    for i, line in enumerate(s.splitlines(), 1):
        out.write(f"{i:04d}: {line}\n")
    return out.getvalue()


def list_imports(tree: ast.AST) -> list[str]:
    res: list[str] = []
    for n in ast.walk(tree):
        if isinstance(n, ast.Import):
            for a in n.names:
                res.append(a.name)
        elif isinstance(n, ast.ImportFrom):
            mod = n.module or ""
            for a in n.names:
                res.append(f"{mod}.{a.name}")
    return sorted(set(res))


def func_sig(fn: ast.FunctionDef | ast.AsyncFunctionDef) -> str:
    args = []
    for a in fn.args.args:
        args.append(a.arg)
    if fn.args.vararg:
        args.append("*" + fn.args.vararg.arg)
    for a in fn.args.kwonlyargs:
        args.append(a.arg + "=")
    if fn.args.kwarg:
        args.append("**" + fn.args.kwarg.arg)
    return f"{fn.name}({', '.join(args)})"


def extract_defs(tree: ast.AST) -> dict[str, Any]:
    funcs, classes = [], []
    for n in tree.body if isinstance(tree, ast.Module) else []:
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)):
            doc = ast.get_docstring(n) or ""
            funcs.append(
                {
                    "name": n.name,
                    "sig": func_sig(n),
                    "lineno": n.lineno,
                    "doc": doc.strip()[:200],
                }
            )
        elif isinstance(n, ast.ClassDef):
            doc = ast.get_docstring(n) or ""
            classes.append(
                {"name": n.name, "lineno": n.lineno, "doc": doc.strip()[:200]}
            )
    return {"functions": funcs, "classes": classes}


def find_symbols(tree: ast.AST, names: list[str]) -> dict[str, int]:
    hits: dict[str, int] = {}
    for n in ast.walk(tree):
        if isinstance(n, ast.FunctionDef):
            if n.name in names:
                hits[n.name] = getattr(n, "lineno", -1)
        if isinstance(n, ast.Assign):
            for t in n.targets:
                if isinstance(t, ast.Name) and t.id in names:
                    hits[t.id] = getattr(n, "lineno", -1)
    return hits


def main() -> int:
    ts = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    REPORT_MD.parent.mkdir(parents=True, exist_ok=True)
    with REPORT_MD.open("w", encoding="utf-8") as rep:
        rep.write("# MCGT — Noyaux communs (_common) — Synthèse\n\n")
        rep.write(f"_Généré le {ts}_\n\n")
        for fname in FILES:
            p = COMMON_DIR / fname
            rep.write(f"## {p.as_posix()}\n\n")
            if not p.exists():
                rep.write("**ABSENT**\n\n")
                continue
            text = read_text_safely(p)
            size = p.stat().st_size
            mtime = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(p.stat().st_mtime))
            digest = sha256_file(p)
            rep.write(
                f"- **taille**: {size} bytes\n- **mtime**: {mtime}\n- **sha256**: `{digest}`\n\n"
            )

            try:
                tree = ast.parse(text)
            except SyntaxError as e:
                rep.write(f"**ERREUR AST**: {e}\n\n")
                numbered = nl_numbered(text)
                (SRC_DIR / f"{fname}.txt").write_text(numbered, encoding="utf-8")
                continue

            # imports / defs
            imports = list_imports(tree)
            defs = extract_defs(tree)
            hits = find_symbols(
                tree,
                [
                    "add_common_cli",
                    "parse_common_args",
                    "resolve_style",
                    "validate_phase",
                    "validate_posterior",
                    "make_logger",
                    "audit_abs_outdir",
                ],
            )

            rep.write("**Imports**:\n\n")
            if imports:
                rep.write("```\n" + "\n".join(imports) + "\n```\n\n")
            else:
                rep.write("_aucun import détecté_\n\n")

            rep.write("**Fonctions (top-level)**:\n\n")
            if defs["functions"]:
                rep.write("```\n")
                for f in defs["functions"]:
                    rep.write(f"{f['lineno']:04d}  {f['sig']}\n")
                rep.write("```\n\n")
            else:
                rep.write("_aucune fonction top-level_\n\n")

            rep.write("**Classes (top-level)**:\n\n")
            if defs["classes"]:
                rep.write("```\n")
                for c in defs["classes"]:
                    rep.write(f"{c['lineno']:04d}  class {c['name']}\n")
                rep.write("```\n\n")
            else:
                rep.write("_aucune classe top-level_\n\n")

            if hits:
                rep.write("**Symboles clés (lignes)**:\n\n```\n")
                for k, v in hits.items():
                    rep.write(f"{k}: {v}\n")
                rep.write("```\n\n")

            # dump sources numérotées
            numbered = nl_numbered(text)
            (SRC_DIR / f"{fname}.txt").write_text(numbered, encoding="utf-8")
            rep.write(
                f"_Sources numérotées sauvegardées_: `_reports/common_sources/{fname}.txt`\n\n"
            )
    print(f"[OK] Rapport: {REPORT_MD}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
