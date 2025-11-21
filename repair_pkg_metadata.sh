#!/usr/bin/env bash
set -Eeuo pipefail

echo "== Fix PKG-INFO metadata fields (license-expression / license-file) =="

root="$(pwd)"
ts="$(date +%Y%m%dT%H%M%S)"
backup_dir=".bkp_pkgmeta_${ts}"
mkdir -p "$backup_dir"

# --- 0) Snapshot current files
for f in pyproject.toml setup.cfg; do
  if [[ -f "$f" ]]; then
    cp -a "$f" "$backup_dir/$f"
  fi
done
echo "Backup saved to: $backup_dir"

# --- 1) Remove non-standard keys from pyproject.toml and ensure [project].license is present
if [[ -f pyproject.toml ]]; then
  python3 - <<'PY'
import re, sys, io, os

path = "pyproject.toml"
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

def section_ranges(lines):
    # yields (name, start_idx, end_idx_exclusive)
    name = None
    start = None
    for i, line in enumerate(lines):
        m = re.match(r'\s*\[(.+?)\]\s*$', line)
        if m:
            if name is not None:
                yield name, start, i
            name = m.group(1).strip()
            start = i
    if name is not None:
        yield name, start, len(lines)

# 1a) Drop any 'license-expression' / 'license-file' / 'license-files' (any case/hyphen/underscore) anywhere
bad_key = re.compile(r'^\s*(license[\-_]?(expression|file|files))\s*=', re.I)
lines = [ln for ln in lines if not bad_key.match(ln)]

# 1b) Ensure [project] has a valid 'license = "MIT"' if no license is present
has_project = False
project_start = project_end = None
for name, s, e in section_ranges(lines):
    if name == "project":
        has_project = True
        project_start, project_end = s, e
        break

def has_key_in_block(lines, start, end, key_regex):
    return any(re.match(key_regex, lines[i], re.I) for i in range(start+1, end))

if has_project:
    if not has_key_in_block(lines, project_start, project_end, r'^\s*license\s*='):
        insert_at = project_start + 1
        lines.insert(insert_at, 'license = "MIT"\n')
else:
    # Minimal [project] block with license if entirely missing (unlikely in a modern project)
    prepend = [
        "[project]\n",
        'name = "zz_tools"\n',
        'version = "0.0.0"\n',
        'license = "MIT"\n',
    ]
    lines = prepend + ["\n"] + lines

with open(path, "w", encoding="utf-8") as f:
    f.writelines(lines)
print("pyproject.toml normalized.")
PY
else
  echo "pyproject.toml not found, skipping TOML edit."
fi

# --- 2) Normalize setup.cfg to use supported fields
if [[ -f setup.cfg ]]; then
  python3 - <<'PY'
import configparser, io, os, sys

cfg_path = "setup.cfg"
cp = configparser.ConfigParser()
with open(cfg_path, "r", encoding="utf-8") as f:
    cp.read_file(f)

if not cp.has_section("metadata"):
    cp.add_section("metadata")

cp.set("metadata", "license", "MIT")
# Include extra license files in source distribution without adding exotic metadata fields
cp.set("metadata", "license_files", "LICENSE, LICENSE-data")

with open(cfg_path, "w", encoding="utf-8") as f:
    cp.write(f)
print("setup.cfg normalized.")
PY
else
  echo "setup.cfg not found, skipping setup.cfg edit."
fi

# --- 3) Rebuild sdist
python3 -m build --sdist

SDIST="$(ls -1t dist/*.tar.gz | head -n1)"
echo
echo "sdist: ${SDIST}"

# --- 4) Inspect where PKG-INFO actually is and show its head
echo
echo "=== Inspect PKG-INFO (head) ==="
if tar -tf "$SDIST" | grep -Eq '(^|/)(PKG-INFO)$'; then
  # PKG-INFO at top-level of the sdist root dir
  tar -xOf "$SDIST" */PKG-INFO | sed -n '1,120p'
elif tar -tf "$SDIST" | grep -Eq 'egg-info/PKG-INFO$'; then
  # Fallback: occasionally under egg-info in some backends (rare for sdist)
  path="$(tar -tf "$SDIST" | grep -E 'egg-info/PKG-INFO$' | head -n1)"
  tar -xOf "$SDIST" "$path" | sed -n '1,120p'
else
  echo "PKG-INFO not found in archive listing — unexpected."
fi

# --- 5) Twine check
echo
echo "=== Run twine check ==="
python3 - <<'PY'
import sys, subprocess, os
sdists = sorted((os.path.join("dist", p) for p in os.listdir("dist") if p.endswith(".tar.gz")), key=os.path.getmtime, reverse=True)
if not sdists:
    print("No sdist found under dist/", file=sys.stderr); sys.exit(2)
cmd = ["twine", "check", sdists[0]]
ret = subprocess.call(cmd)
if ret == 0:
    print("Twine check: OK")
else:
    print("Twine check failed with exit code", ret)
    sys.exit(ret)
PY

# --- 6) Helpful next steps if still failing
cat <<'MSG'

Done. If 'twine check' still flags unknown fields:
  - Search the generated PKG-INFO to confirm fields:
      tar -xOf "$SDIST" */PKG-INFO | grep -nEi '^(License|Classifier|Metadata-Version|Name|Version|Summary|Home-page|Author|License-File|License)'
  - Then grep your project for lingering keys:
      grep -RinEI 'license[-_](file|files|expression)' pyproject.toml setup.cfg setup.py zz_tools.egg-info || true

If needed, paste the first ~120 lines of PKG-INFO here and we’ll tailor the fix.
MSG
