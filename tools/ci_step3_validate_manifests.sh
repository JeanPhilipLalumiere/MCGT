#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
mkdir -p .ci-out
NEW=".ci-out/manifest_publication.sha256sum.new"
trap 'rm -f "$NEW"' EXIT
git ls-files 'zz-figures/**/*.png' 'zz-figures/**/*.jpg' 'zz-figures/**/*.jpeg' 'zz-figures/**/*.svg' |
  LC_ALL=C sort | xargs -r sha256sum >"$NEW"
if ! diff -u zz-manifests/manifest_publication.sha256sum "$NEW"; then
  echo "❌ manifest_publication.sha256sum désynchronisé."
  echo "   Recalcule: tools/rebuild_figures_sha256.sh puis commit."
  exit 1
fi
echo "✅ Manifests OK"
