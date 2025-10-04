#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
OUT="zz-manifests/manifest_publication.sha256sum"
tmp="$(mktemp)"
git ls-files 'zz-figures/**/*.png' 'zz-figures/**/*.jpg' 'zz-figures/**/*.jpeg' 'zz-figures/**/*.svg' |
  LC_ALL=C sort |
  xargs -r sha256sum >"$tmp"
mv "$tmp" "$OUT"
echo "Wrote $OUT with $(wc -l <"$OUT") entries"
