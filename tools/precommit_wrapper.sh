#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. .ci-helpers/guard.sh

# Ignore et désindexe .ci-out/
git rm -r --cached --ignore-unmatch .ci-out >/dev/null 2>&1 || true

echo "==> pre-commit (all files)"
pre-commit run --all-files || true

echo "==> pre-commit (staged seulement)"
pre-commit run || true

echo "Done."
