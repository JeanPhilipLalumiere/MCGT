import argparse
import fnmatch
import pathlib
import re
import sys

import yaml

parser = argparse.ArgumentParser()
parser.add_argument(
    "--include-archive", action="store_true", help="ne pas ignorer .ci-archive/**"
)
args = parser.parse_args()

root = pathlib.Path(".")
cfg = yaml.safe_load(open("config/defaults.yml", encoding="utf-8"))

ignore_globs = [] if args.include_archive else [".ci-archive/**"]


def skip(p: pathlib.Path) -> bool:
    pos = p.as_posix()
    return any(fnmatch.fnmatch(pos, pat) for pat in ignore_globs)


def strip_quotes(s: str):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ("'", '"'):
        return s[1:-1]
    return s


def parse_scalar(s: str):
    s = re.sub(r"\s+#.*", "", s).strip()
    try:
        return yaml.safe_load(s)
    except Exception:
        return strip_quotes(s)


def canon_default(kind: str, k: str, v):
    # impose des canons utiles
    if kind == "yaml_key" and k == "python-version":
        return str(v)
    if kind == "yaml_key" and k == "timeout-minutes":
        try:
            return int(v)
        except Exception:
            return v
    # générique
    return v


wanted_yaml = {
    k: canon_default("yaml_key", k, v) for k, v in (cfg.get("yaml_key") or {}).items()
}
wanted_fm = {
    k: canon_default("frontmatter_key", k, v)
    for k, v in (cfg.get("frontmatter_key") or {}).items()
}

bad = []


def check_yaml_file(p: pathlib.Path, wanted: dict):
    if skip(p):
        return
    for i, line in enumerate(
        p.read_text(encoding="utf-8", errors="ignore").splitlines(), 1
    ):
        m = re.match(r"\s*([A-Za-z_][\w-]*)\s*:\s*(.+)", line)
        if not m:
            continue
        k, vraw = m.group(1), m.group(2)
        if k not in wanted:
            continue
        vfile = parse_scalar(vraw)
        vdef = wanted[k]
        # harmonise types pour comparaison
        if k == "python-version":
            vfile = str(vfile)
        if k == "timeout-minutes":
            try:
                vfile = int(vfile)
            except Exception:
                pass
        if vfile != vdef:
            bad.append((str(p), i, k, vfile, vdef))


def check_front_matter(p: pathlib.Path, wanted: dict):
    if skip(p):
        return
    txt = p.read_text(encoding="utf-8", errors="ignore").splitlines()
    if not txt or not re.match(r"^---\s*$", txt[0]):
        return
    for i, line in enumerate(txt[1:], 2):
        if re.match(r"^---\s*$", line):
            break
        m = re.match(r"\s*([A-Za-z_][\w-]*)\s*:\s*(.+)", line)
        if not m:
            continue
        k, vraw = m.group(1), m.group(2)
        if k not in wanted:
            continue
        vfile = parse_scalar(vraw)
        vdef = wanted[k]
        if vfile != vdef:
            bad.append((str(p), i, f"(front) {k}", vfile, vdef))


for p in list(root.rglob("*.yml")) + list(root.rglob("*.yaml")):
    check_yaml_file(p, wanted_yaml)

for p in root.rglob("*.md"):
    check_front_matter(p, wanted_fm)

if bad:
    for f, i, k, v, w in bad:
        print(f"[DRIFT] {f}:{i} {k}: {v!r} != {w!r}")
    sys.exit(1)
print("[DRIFT] OK")
