#!/usr/bin/env bash
set -euo pipefail
VER="${1:-}"
if [ -z "${VER}" ]; then
  echo "Usage: tools/release.sh <version like 0.1.0>" >&2
  exit 2
fi
TAG="v${VER}"
# Sanity: build & check
python3 -m build
python3 -m pip install -U twine >/dev/null
twine check dist/*

# Tag & push
git tag -a "${TAG}" -m "release ${TAG}"
git push --follow-tags

echo "Tag ${TAG} pushed. If GitHub secret PYPI_API_TOKEN is set, publish will run automatically."
