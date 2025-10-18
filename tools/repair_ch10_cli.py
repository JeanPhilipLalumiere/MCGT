#!/usr/bin/env python3
from pathlib import Path
import re
import sys

# --- files to repair (extend if needed)
TARGETS = [
    Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
    Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
]

# --- what each file must support as CLI flags and sane defaults
REQUIREMENTS = {
    "plot_fig03b_bootstrap_coverage_vs_n.py": {
        "add_args": [
            ("--p95-col", "p95_col", None),
        ],
        "postparse_fill": [
            ("p95_col", "None"),
        ],
    },
    "plot_fig06_residual_map.py": {
        "add_args": [
            ("--m1-col", "m1_col", "phi0"),
            ("--m2-col", "m2_col", "phi_ref_fpeak"),
        ],
        "postparse_fill": [
            ("m1_col", "'phi0'"),
            ("m2_col", "'phi_ref_fpeak'"),
        ],
    },
}

ARGPARSE_CRE = re.compile(
    r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*[^=\n]*\bArgumentParser\s*\(',
    re.M
)

def find_parser_var(text: str) -> str|None:
    m = ARGPARSE_CRE.search(text)
    return m.group(1) if m else None

def last_add_argument_index(lines, parser_var: str) -> int|None:
    last = None
    pat = re.compile(rf'^\s*{re.escape(parser_var)}\.add_argument\s*\(')
    for i, line in enumerate(lines):
        if pat.match(line):
            last = i
    return last

def parser_decl_index(lines) -> int|None:
    for i, line in enumerate(lines):
        if ARGPARSE_CRE.match(line):
            return i
    return None

def find_parse_call(lines, parser_var: str):
    """
    returns (idx, args_var_name, kind) where kind in {"parse_args","parse_known_args"}
    """
    # parse_args:     args = parser.parse_args(...)
    re_args = re.compile(rf'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*{re.escape(parser_var)}\.parse_args\s*\(')
    # parse_known:    args, unknown = parser.parse_known_args(...)
    re_known = re.compile(rf'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*[A-Za-z_][A-Za-z0-9_]*\s*=\s*{re.escape(parser_var)}\.parse_known_args\s*\(')
    for i, line in enumerate(lines):
        m = re_args.match(line)
        if m:
            return i, m.group(1), "parse_args"
        m = re_known.match(line)
        if m:
            return i, m.group(1), "parse_known_args"
    return None, None, None

def ensure_add_arguments(lines, parser_var: str, add_args):
    """
    add_args: list of tuples (flag, dest, default_py_value_or_None)
    inserts after last add_argument for that parser, or after parser creation line if none
    """
    inserted = 0
    decl_i = parser_decl_index(lines)
    if decl_i is None:
        return inserted  # nothing to do

    last_add_i = last_add_argument_index(lines, parser_var)
    insert_at = (last_add_i if last_add_i is not None else decl_i) + 1

    snippets = []
    for flag, dest, default_val in add_args:
        # idempotency check: flag already present?
        flag_pat = re.compile(rf'^\s*{re.escape(parser_var)}\.add_argument\([^)]*\b{re.escape(flag)}\b')
        if any(flag_pat.match(l) for l in lines):
            continue
        default_kw = f", default={default_val}" if default_val is not None else ""
        snippets.append(f"{parser_var}.add_argument('{flag}', dest='{dest}'{default_kw})\n")

    if snippets:
        lines[insert_at:insert_at] = snippets
        inserted = len(snippets)
    return inserted

def ensure_postparse_fill(lines, args_var: str, fills, parse_idx: int):
    """
    fills: list of (attr, py_value_str)
    inserts block right after parse_idx
    """
    start_tag = "# --- cli post-parse backfill (auto) ---\n"
    end_tag   = "# --- end cli post-parse backfill (auto) ---\n"
    # if already there, skip
    if any(start_tag in l for l in lines):
        return 0
    block = [start_tag]
    for attr, pyval in fills:
        block.append(f"if not hasattr({args_var}, '{attr}'):\n    setattr({args_var}, '{attr}', {pyval})\n")
    block.append(end_tag)
    lines[parse_idx+1:parse_idx+1] = block
    return 1

def strip_residual_shims(lines):
    """
    Remove any previous compat shims to avoid surprises.
    """
    START = re.compile(r'^\s*#\s*--- compat: argparse (?:post-parse|parse-hook).*---\s*$')
    END   = re.compile(r'^\s*#\s*--- end compat: argparse (?:post-parse|parse-hook).*---\s*$')
    out, i, changed = [], 0, False
    while i < len(lines):
        if START.match(lines[i]):
            j = i + 1
            while j < len(lines) and not END.match(lines[j]):
                j += 1
            if j < len(lines):  # drop [i..j]
                i = j + 1
                changed = True
                continue
        out.append(lines[i]); i += 1
    return out, changed

def process_file(p: Path):
    name = p.name
    req = REQUIREMENTS.get(name)
    if not req:
        print(f"[SKIP] no requirements for {p}")
        return

    text = p.read_text(encoding="utf-8")
    parser_var = find_parser_var(text)
    if not parser_var:
        print(f"[WARN] no ArgumentParser found in {p} — nothing changed")
        return

    lines = text.splitlines(True)
    # 1) strip legacy shims (optional, safer)
    lines, _ = strip_residual_shims(lines)

    # 2) ensure missing add_argument(...)
    added = ensure_add_arguments(lines, parser_var, req["add_args"])

    # 3) locate parse_* call and inject post-parse fill
    parse_i, args_var, kind = find_parse_call(lines, parser_var)
    filled = 0
    if parse_i is not None and args_var:
        filled = ensure_postparse_fill(lines, args_var, req["postparse_fill"], parse_i)

    if added or filled:
        bak = p.with_suffix(p.suffix + ".bak_cli")
        if not bak.exists():
            bak.write_text(text, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
        print(f"[PATCH] {p}: add_args +{added}, postparse_fill +{filled}")
    else:
        print(f"[OK] {p}: already compliant")

def main():
    for f in TARGETS:
        if not f.exists():
            print(f"[MISS] {f} not found")
            continue
        process_file(f)

if __name__ == "__main__":
    main()
