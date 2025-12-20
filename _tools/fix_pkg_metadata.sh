#!/usr/bin/env bash
set -Eeuo pipefail

echo "== Fix packaging metadata (license fields) and rebuild sdist =="
echo "PWD=$(pwd)"
echo "Python: $(python3 -V || true)"
echo "Branch: $(git rev-parse --abbrev-ref HEAD || true)"
echo

# --- Safety backups -----------------------------------------------------------
ts="$(date +%Y%m%dT%H%M%S)"
bkp_dir=".bkp_pkgmeta_$ts"
mkdir -p "$bkp_dir"

for f in pyproject.toml setup.cfg; do
  if [[ -f "$f" ]]; then
    cp -a "$f" "$bkp_dir/$f"
    echo "Backup: $f -> $bkp_dir/$f"
  fi
done
echo

# --- Patch pyproject.toml (remove PEP 639 keys; ensure license file) ---------
if [[ -f pyproject.toml ]]; then
python3 - <<'PY'
import re, sys, pathlib
p = pathlib.Path("pyproject.toml")
s = p.read_text(encoding="utf-8")

# 1) Drop any 'license-expression' or 'license-file' keys (case-insensitive) anywhere
s = re.sub(r'(?im)^\s*(license[-_]expression|license[-_]file)\s*=\s*.*\n', '', s)

# 2) Inside [project], ensure a 'license =' entry exists (PEP 621) and is not "dynamic"
# Very light-weight block detector (doesn't fully parse TOML, but good enough)
def ensure_project_license(text: str) -> str:
    # Find [project] block
    m = re.search(r'(?ms)^\s*\[project\]\s*(.*?)^(?=\s*\[)', text+'\n[')  # sentinel [
    if not m:
        return text  # nothing to do
    block = m.group(1)
    start = m.start(1)
    end   = m.end(1)

    has_license = re.search(r'(?im)^\s*license\s*=', block) is not None

    # Remove 'license' from dynamic if present on a single-line list
    def clean_dynamic(b: str) -> str:
        # Try single-line dynamic = [ ... ]
        def _strip_item_list(lst: str) -> str:
            # remove 'license' items (with or without quotes), then tidy commas
            lst2 = re.sub(r'(?i)\s*"?license"?\s*,?', '', lst)
            # remove leading/trailing commas and collapse repeated commas
            lst2 = re.sub(r',\s*,+', ',', lst2)
            lst2 = re.sub(r'^\s*,\s*', '', lst2)
            lst2 = re.sub(r',\s*$','', lst2)
            return lst2

        b = re.sub(
            r'(?ims)^(\s*dynamic\s*=\s*\[)([^\]\n]*)(\]\s*)$',
            lambda m: m.group(1)+_strip_item_list(m.group(2))+m.group(3),
            b
        )
        return b

    new_block = clean_dynamic(block)

    if not has_license:
        # Insert a canonical license line near the top of the block
        insert_line = 'license = { file = "LICENSE" }\n'
        # place after the first non-comment line if possible, otherwise at start
        lines = new_block.splitlines(keepends=True)
        insert_at = 0
        for i, L in enumerate(lines):
            if L.strip().startswith("#") or not L.strip():
                continue
            insert_at = i+1
            break
        lines.insert(insert_at, insert_line)
        new_block = ''.join(lines)

    return text[:start] + new_block + text[end:]

s2 = ensure_project_license(s)

if s2 != s:
    pathlib.Path("pyproject.toml").write_text(s2, encoding="utf-8")
    print("Patched: pyproject.toml")
else:
    print("No change: pyproject.toml")
PY
else
  echo "No pyproject.toml — skipping."
fi
echo

# --- Patch setup.cfg ([metadata]) --------------------------------------------
if [[ -f setup.cfg ]]; then
python3 - <<'PY'
import re, pathlib

p = pathlib.Path("setup.cfg")
s = p.read_text(encoding="utf-8")

# Remove any license-expression / license-file (case-insensitive)
s = re.sub(r'(?im)^\s*(license[-_]expression|license[-_]file)\s*=\s*.*\n', '', s)

# Ensure we are inising inside [metadata] block
m = re.search(r'(?ms)^\s*\[metadata\]\s*(.*?)^(?=\s*\[|\Z)', s+'\n[')
if m:
    block = m.group(1)
    start = m.start(1)
    end   = m.end(1)

    has_license = re.search(r'(?im)^\s*license\s*=', block) is not None
    has_license_files = re.search(r'(?im)^\s*license[_ ]?files\s*=', block) is not None

    lines = block.splitlines(keepends=True)
    appended = False
    if not has_license:
        lines.append('license = MIT\n')
        appended = True
    if not has_license_files:
        # include data license file too so it lands in sdist
        lines.append('license_files = LICENSE, LICENSE-data\n')
        appended = True

    if appended:
        new_block = ''.join(lines)
        s = s[:start] + new_block + s[end:]
else:
    # No [metadata] section? Add a minimal one at end.
    s = s.rstrip() + '\n\n[metadata]\nlicense = MIT\nlicense_files = LICENSE, LICENSE-data\n'

pathlib.Path("setup.cfg").write_text(s, encoding="utf-8")
print("Patched: setup.cfg")
PY
else
  echo "No setup.cfg — skipping."
fi
echo

# --- Commit the changes (if any) --------------------------------------------
if ! git diff --quiet; then
  git add -A
  git -c commit.gpgsign=false commit -m "build(metadata): sanitize license fields for PyPI (PEP 621 / setuptools)"
  echo "Committed fixes."
else
  echo "No changes to commit."
fi
echo

# --- Rebuild sdist -----------------------------------------------------------
python3 - <<'PY'
import importlib.util, sys
if importlib.util.find_spec("build") is None:
    print("Installing 'build' module in the current environment...", flush=True)
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "build"])
PY

echo "Building sdist..."
python3 -m build --sdist

SDIST="$(ls -1t dist/*.tar.gz | head -n1)"
echo "sdist: $SDIST"
echo

# --- Inspect PKG-INFO headers ------------------------------------------------
echo "=== Inspect PKG-INFO (head) ==="
# PKG-INFO is at the root of the sdist dir: */PKG-INFO
if tar -tf "$SDIST" | grep -qE '.*/PKG-INFO$'; then
  tar -xOf "$SDIST" */PKG-INFO | sed -n '1,80p'
else
  echo "PKG-INFO not found in archive listing — unexpected."
fi
echo

# --- Twine check -------------------------------------------------------------
python3 - <<'PY'
import importlib.util, sys, subprocess
if importlib.util.find_spec("twine") is None:
    print("Installing 'twine' in the current environment...", flush=True)
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "twine"])
PY

echo "=== Run twine check ==="
python3 -m twine check "$SDIST" || true
echo

echo "Done. If 'twine check' still flags unknown fields, search them directly:"
echo "  tar -xOf \"$SDIST\" */PKG-INFO | grep -iE 'license|classifier' -n"
