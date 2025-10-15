
#!/usr/bin/env bash
set -euo pipefail
ver="${1:-}"; [[ -n "$ver" ]] || { echo "Usage: $0 <new-version>"; exit 2; }

# bump
perl -0777 -pe "s/^version\\s*=\\s*\".*?\"/version = \"$ver\"/m" -i pyproject.toml

# build
rm -rf dist build *.egg-info .pytest_cache
python -m build

# garde-fou
./scripts/check_metadata_clean.sh

# upload
twine check dist/*
twine upload --skip-existing dist/*

# tag = version
if git rev-parse "v$ver" >/dev/null 2>&1; then
  echo "(info) tag v$ver existe déjà"
else
  git tag "v$ver"
fi
git push origin "v$ver" || echo "(info) tag déjà poussé"
