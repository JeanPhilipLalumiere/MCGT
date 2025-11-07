#!/usr/bin/env bash
set -euo pipefail
if [[ $# -ne 1 ]]; then echo "Usage: $0 X.Y.Z"; exit 2; fi
VER="$1"

# maj pyproject
sed -i -E "s/^(\s*version\s*=\s*\")[0-9]+\.[0-9]+\.[0-9]+(\")/\1${VER}\2/" pyproject.toml

# maj __init__
python - <<PY
from pathlib import Path, re
p = Path("mcgt/__init__.py")
t = p.read_text(encoding="utf-8")
t = re.sub(r'(__version__\s*=\s*["\']).*?(["\'])', r'\g<1>${VER}\2', t, count=1)
p.write_text(t, encoding="utf-8")
print("set __version__ -> ${VER}")
PY

git add pyproject.toml mcgt/__init__.py
git commit -m "release: bump version ${VER}"
git tag -a "v${VER}" -m "mcgt_core ${VER}"
git push && git push --tags
