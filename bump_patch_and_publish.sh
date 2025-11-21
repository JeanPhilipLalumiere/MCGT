#!/usr/bin/env bash
set -Eeuo pipefail

info(){ printf "[INFO] %s\n" "$*"; }
warn(){ printf "[WARN] %s\n" "$*" >&2; }
die(){ printf "[ERR ] %s\n" "$*" >&2; exit 1; }

command -v python3 >/dev/null || die "python3 requis"
command -v git      >/dev/null || die "git requis"
command -v twine    >/dev/null || die "twine requis (pip install twine)"
python3 -m pip show build >/dev/null 2>&1 || python3 -m pip install -U build >/devnull

cur_ver="$(python3 - <<'PY'
import sys, re, pathlib
p = pathlib.Path("pyproject.toml")
if not p.exists(): sys.exit(0)
txt = p.read_text(encoding="utf-8")
try:
    import tomllib
    v = tomllib.loads(txt).get("project", {}).get("version", "")
    print(v, end="")
except Exception:
    m = re.search(r'(?m)^\s*version\s*=\s*"([^"]+)"\s*$', txt)
    print(m.group(1) if m else "", end="")
PY
)"
[[ -n "${cur_ver}" ]] || die "Version introuvable dans pyproject.toml"
info "zz-tools current=${cur_ver}"

next_ver="$(python3 - <<PY
import re
cur="${cur_ver}"
m=re.search(r'^(\d+)\.(\d+)\.(\d+)', cur)
if not m: print("", end="")
else:
    M,mn,p = map(int, m.groups())
    print(f"{M}.{mn}.{p+1}", end="")
PY
)"
[[ -n "${next_ver}" ]] || die "Impossible de calculer le patch suivant pour ${cur_ver}"
info "new=${next_ver}"

export NEW_VER="${next_ver}"

python3 - <<'PY'
import os, pathlib, re, io
new = os.environ["NEW_VER"]
pp = pathlib.Path("pyproject.toml")
txt = pp.read_text(encoding="utf-8")
out, inside, replaced = io.StringIO(), False, False
for line in txt.splitlines(True):
    if line.strip() == "[project]":
        inside = True; out.write(line); continue
    if line.startswith("[") and inside:
        inside = False
    if inside and re.match(r'^\s*version\s*=\s*["\'].*["\']\s*$', line):
        indent = re.match(r'^(\s*)', line).group(1)
        out.write(f'{indent}version = "{new}"\n'); replaced = True
    else:
        out.write(line)
new_txt = out.getvalue()
if not replaced:
    new_txt = re.sub(r'(?ms)(^\[project\]\s*)', r'\1version = "'+new+'"\n', txt, count=1)
pp.write_text(new_txt, encoding="utf-8")
print("[INFO] pyproject.toml mis à jour ->", new)
PY

if [[ -f "zz_tools/__init__.py" ]]; then
python3 - <<'PY'
import os, pathlib, re
new = os.environ["NEW_VER"]
p = pathlib.Path("zz_tools/__init__.py")
s = p.read_text(encoding="utf-8")
if re.search(r'__version__\s*=\s*["\']', s):
    s = re.sub(r'(?m)^(\s*__version__\s*=\s*)["\'][^"\']*["\']', lambda m: f'{m.group(1)}"{new}"', s)
else:
    s += f'\n__version__ = "{new}"\n'
p.write_text(s, encoding="utf-8")
print("[INFO] __init__.py synchronisé ->", new)
PY
fi

git add pyproject.toml zz_tools/__init__.py 2>/dev/null || true
git -c commit.gpgsign=false commit -m "release(zz-tools): bump to ${next_ver}" || warn "commit vide"
git tag -a "v${next_ver}" -m "zz-tools ${next_ver}" 2>/dev/null || warn "tag déjà existant ?"
git push --follow-tags

python3 -m build
twine check "dist/zz_tools-${next_ver}-"*
twine upload ${TWINE_REPOSITORY:+--repository "$TWINE_REPOSITORY"} \
             ${TWINE_REPOSITORY_URL:+--repository-url "$TWINE_REPOSITORY_URL"} \
             "dist/zz_tools-${next_ver}-"*

info "Publié ${next_ver}."
