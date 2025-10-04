import argparse
import fnmatch
import pathlib
import re
import sys

import yaml

p = pathlib.Path("config/defaults.yml")
cfg = yaml.safe_load(p.read_text(encoding="utf-8")) if p.exists() else {}
wanted = cfg.get("yaml_key") or {}

parser = argparse.ArgumentParser()
parser.add_argument("--paths", nargs="*", default=[".github/workflows/sanity-main.yml"])
parser.add_argument("--keys", nargs="*", default=["timeout-minutes", "python-version"])
parser.add_argument("--include-archive", action="store_true")
parser.add_argument("--apply", action="store_true")
args = parser.parse_args()

ignore_globs = [] if args.include_archive else [".ci-archive/**"]


def skip(path: pathlib.Path) -> bool:
    pos = path.as_posix()
    return any(fnmatch.fnmatch(pos, pat) for pat in ignore_globs)


def yamlify_scalar(v):
    if isinstance(v, int):
        return str(v)
    s = str(v).replace('"', '\\"')
    return f'"{s}"'


def process_file(path: pathlib.Path):
    if skip(path):
        return False, []
    orig = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    changed, diffs = False, []
    pat = re.compile(r"^(\s*)([A-Za-z_][\w-]*)(\s*:\s*)([^#]*?)(\s*(#.*)?)$")
    lines = orig[:]
    for i, line in enumerate(lines):
        m = pat.match(line)
        if not m:
            continue
        indent, key, sep, val_raw, tail = m.group(1, 2, 3, 4, 5)
        if key not in args.keys or key not in wanted:
            continue
        if any(tok in val_raw for tok in ("|", ">", "{", "[", "${{")):
            continue
        try:
            v_file = yaml.safe_load(val_raw.strip())
        except Exception:
            v_file = val_raw.strip().strip("'\"")
        v_def = wanted[key]
        if key == "python-version":
            v_file, v_def = str(v_file), str(v_def)
        if key == "timeout-minutes":
            try:
                v_file = int(v_file)
            except:
                pass
            try:
                v_def = int(v_def)
            except:
                pass
        if v_file == v_def:
            continue
        new_line = f"{indent}{key}{sep}{yamlify_scalar(v_def)}{tail or ''}"
        lines[i] = new_line
        changed = True
        diffs.append((i + 1, key, v_file, v_def))
    if diffs:
        print(f"[PATCH] {path}")
        for ln, k, vf, vd in diffs:
            print(f"  - L{ln}: {k}: {vf!r} -> {vd!r}")
        if args.apply:
            path.write_text(
                "\n".join(lines) + ("\n" if orig and orig[-1] == "" else ""),
                encoding="utf-8",
            )
    return changed, diffs


targets = [pathlib.Path(p) for p in args.paths]
any_change = False
for t in targets:
    if t.is_dir():
        for f in t.rglob("*.yml"):
            c, _ = process_file(f)
            any_change |= c
        for f in t.rglob("*.yaml"):
            c, _ = process_file(f)
            any_change |= c
    else:
        c, _ = process_file(t)
        any_change |= c
sys.exit(0)
