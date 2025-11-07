#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse
import csv
import io
import re
import tokenize
from pathlib import Path

CALLS = {
    "add_argument",
    "add_mutually_exclusive_group",
    "add_subparsers",
    "ArgumentParser",
    "annotate",
}


def read_never_closed_files(csv_path: Path):
    out = set()
    with csv_path.open(newline="", encoding="utf-8") as f:
        r = csv.reader(f)
        next(r, None)
        for row in r:
            if not row or len(row) < 3:
                continue
            reason = ",".join(row[2:-3]) if len(row) >= 6 else row[2]
            if "SyntaxError: '(' was never closed" in reason:
                out.add(row[0])
    return sorted(out)


def line_indent(line: str) -> int:
    return len(line) - len(line.lstrip(" \t"))


def has_match(tokens, open_idx: int) -> bool:
    depth = 1
    j = open_idx + 1
    while j < len(tokens):
        t = tokens[j]
        if t.type == tokenize.OP and t.string in ("(", ")"):
            depth += 1 if t.string == "(" else -1
            if depth == 0:
                return True
        j += 1
    return False


def find_unclosed(code: str):
    toks = list(tokenize.generate_tokens(io.StringIO(code).readline))
    lines = code.splitlines(True)
    res = []
    i = 0

    def peek(k):
        return toks[i + k] if i + k < len(toks) else None

    while i < len(toks):
        t = toks[i]
        if t.type == tokenize.NAME:
            t1 = peek(1)
            t2 = peek(2)
            t3 = peek(3)
            # X . name (
            if (
                t1
                and t1.type == tokenize.OP
                and t1.string == "."
                and t2
                and t2.type == tokenize.NAME
                and t2.string in CALLS
                and t3
                and t3.type == tokenize.OP
                and t3.string == "("
            ):
                if not has_match(toks, i + 3):
                    ln, _ = t3.start
                    ind = line_indent(lines[ln - 1])
                    res.append(("." + t2.string, ln, ind, i + 3))
                i += 4
                continue
            # name (
            if t1 and t1.type == tokenize.OP and t1.string == "(" and t.string in CALLS:
                if not has_match(toks, i + 1):
                    ln, _ = t1.start
                    ind = line_indent(lines[ln - 1])
                    res.append((t.string, ln, ind, i + 1))
                i += 2
                continue
            # argparse . ArgumentParser (
            if (
                t.string == "argparse"
                and t1
                and t1.type == tokenize.OP
                and t1.string == "."
                and t2
                and t2.type == tokenize.NAME
                and t2.string == "ArgumentParser"
                and t3
                and t3.type == tokenize.OP
                and t3.string == "("
            ):
                if not has_match(toks, i + 3):
                    ln, _ = t3.start
                    ind = line_indent(lines[ln - 1])
                    res.append(("ArgumentParser", ln, ind, i + 3))
                i += 4
                continue
        i += 1
    return res


def insert_pos_by_dedent(code: str, open_line: int, base_indent: int) -> int:
    lines = code.splitlines(True)
    L = open_line + 1
    while L <= len(lines):
        s = lines[L - 1]
        strip = s.lstrip()
        if strip.startswith("#") or strip == "" or strip == "\n":
            L += 1
            continue
        if line_indent(s) <= base_indent:
            # début de la ligne
            # offset = index du début de L
            off = 0
            cur = 1
            for idx, ch in enumerate(code):
                if ch == "\n":
                    cur += 1
                if cur == L:
                    off = idx + 1
                    break
            return off
        L += 1
    return len(code)


def patch_rr(text: str):
    text = re.sub(r"\b(rf|fr)(\"\"\"|\'\'\'|\"|\')", r"r\2", text)
    text = text.replace("f_{ RR}", "f_{RR}")
    return text


def patch_once(code: str):
    changed = False
    add_arg = grp = sub = subp = ap = 0
    rr = 0
    try:
        unclosed = find_unclosed(code)
        inserts = []
        for name, ln, ind, _ in unclosed:
            pos = insert_pos_by_dedent(code, ln, ind)
            inserts.append((pos, ")\n", name))
        inserts.sort(key=lambda x: x[0], reverse=True)
        for pos, ins, name in inserts:
            code = code[:pos] + ins + code[pos:]
            changed = True
            if name.endswith("add_argument"):
                add_arg += 1
            elif name.endswith("add_mutually_exclusive_group"):
                grp += 1
            elif name.endswith("add_subparsers"):
                subp += 1
            elif name == "ArgumentParser":
                ap += 1
    except tokenize.TokenError:
        # Fallback: si on détecte un appel non refermé à la dure, on ferme en fin de fichier
        if re.search(r"add_argument\s*\(", code) and code.count("(") > code.count(")"):
            code = code.rstrip() + "\n)\n"
            changed = True
            add_arg += 1
        elif re.search(r"(?:^|\W)ArgumentParser\s*\(", code) and code.count(
            "("
        ) > code.count(")"):
            code = code.rstrip() + "\n)\n"
            changed = True
            ap += 1
    new = patch_rr(code)
    if new != code:
        rr = 1
        changed = True
        code = new
    return (
        changed,
        code,
        {
            "add_argument": add_arg,
            "groups": grp,
            "subparsers": subp,
            "argumentparser": ap,
            "rr_fixed": rr,
        },
    )


def patch_until_stable(code: str, max_iter=5):
    total = {
        "add_argument": 0,
        "groups": 0,
        "subparsers": 0,
        "argumentparser": 0,
        "rr_fixed": 0,
    }
    changed_any = False
    for _ in range(max_iter):
        ch, code, st = patch_once(code)
        for k in total:
            total[k] += st[k]
        if not ch:
            break
        changed_any = True
    return changed_any, code, total


def try_compile(code: str, filename: str):
    try:
        compile(code, filename, "exec")
        return True, ""
    except SyntaxError as e:
        return False, f"{filename}: {e.msg} (line {e.lineno})"
    except Exception:
        return True, ""


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--csv", default="zz-out/homog_smoke_pass14.csv")
    p.add_argument("--root", default=".")
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args()
    root = Path(a.root).resolve()
    csv_path = (root / a.csv).resolve()
    files = read_never_closed_files(csv_path)
    if not files:
        print("[INFO] Aucun fichier 'was never closed'")
        return
    print(f"[INFO] {len(files)} fichier(s) avec 'was never closed'")

    changed_files = 0
    still = []
    agg = {
        "add_argument": 0,
        "groups": 0,
        "subparsers": 0,
        "argumentparser": 0,
        "rr_fixed": 0,
    }
    for rel in files:
        f = (root / rel).resolve()
        if not f.exists():
            print("[WARN] Manquant:", f)
            continue
        src = f.read_text(encoding="utf-8")
        ch, new, st = patch_until_stable(src)
        if ch and not a.dry_run:
            bak = f.with_suffix(f.suffix + ".bak")
            if not bak.exists():
                bak.write_text(src, encoding="utf-8")
            f.write_text(new, encoding="utf-8")
            changed_files += 1
        for k in agg:
            agg[k] += st[k]
        ok, msg = try_compile(new, str(f))
        if not ok:
            still.append(msg)
    print(f"[INFO] Modifiés: {changed_files}")
    print(f"[INFO]   - add_argument(): {agg['add_argument']}")
    print(f"[INFO]   - add_mutually_exclusive_group(): {agg['groups']}")
    print(f"[INFO]   - add_subparsers(): {agg['subparsers']}")
    print(f"[INFO]   - ArgumentParser(): {agg['argumentparser']}")
    print(f"[INFO]   - RR LaTeX fix: {agg['rr_fixed']}")
    if still:
        print("[WARN] Non compilables:")
        for m in still:
            print("  -", m)
    else:
        print("[OK] Tous les fichiers patchés se compilent.")


if __name__ == "__main__":
    main()
