#!/usr/bin/env bash
# tools/verify_inspect_entry.sh
set -euo pipefail
path="$1"

echo "=== VERIFY: $path ==="
echo "--- manifest entry (if any) ---"
jq -r --arg p "$path" '.entries[] | select(.path==$p) // "MISSING_IN_MANIFEST"' zz-manifests/manifest_master.json

echo
echo "--- fs info ---"
ls -l --full-time -- "$path" 2>/dev/null || echo "(not found on filesystem)"
stat -c 'size=%s mtime=%y mode=%f' -- "$path" 2>/dev/null || stat -f '%z %Sm %p' -- "$path" 2>/dev/null || true
file --brief --mime-type -- "$path" 2>/dev/null || file "$path" 2>/dev/null || true

echo
echo "--- symlink? target ---"
if [ -L "$path" ]; then
  readlink -f -- "$path" || readlink -- "$path"
else
  echo "not a symlink"
fi

echo
echo "--- head bytes (hex, up to 128 bytes) ---"
od -An -t x1 -N128 -- "$path" 2>/dev/null | sed -n '1p' || echo "(no hex preview)"

echo
echo "--- textual preview (first 60 lines) ---"
head -n 60 -- "$path" 2>/dev/null || echo "(no textual preview)"

echo
echo "--- checksum & git info ---"
sha256sum -- "$path" 2>/dev/null || shasum -a256 -- "$path" 2>/dev/null || true
wc -c < "$path" 2>/dev/null || true
echo "git tracked?"
git ls-files --error-unmatch -- "$path" >/dev/null 2>&1 && echo "YES (in index/HEAD)" || echo "NO (untracked or removed)"
echo "git ls-tree HEAD:"
git ls-tree -l HEAD -- "$path" 2>/dev/null || true
echo "git hash-object (working tree blob):"
git hash-object -- "$path" 2>/dev/null || true

echo
echo "=== END $path ==="
