#!/usr/bin/env bash
set -euo pipefail
tag="${1:-}"
msg="${2:-"release ${tag}"}"
[ -n "$tag" ] || { echo "usage: tools/retag.sh vX.Y.Z [message]"; exit 2; }

# delete local + remote if exist
git tag -d "$tag" 2>/dev/null || true
git push origin ":refs/tags/$tag" 2>/dev/null || true

# recreate + push
git tag -a "$tag" -m "$msg"
git push origin "$tag"
echo "✅ Retagged $tag"
