#!/usr/bin/env bash
# tools/verify_batch.sh
set -euo pipefail
LIST="${1:-}"   # fichier avec chemins, ou stdin
OUT="_tmp/verify_report.$(date -u +%Y%m%dT%H%M%SZ).tsv"
echo -e "path\tin_manifest\tmanifest_sha256\tmanifest_size\tmanifest_mtime\tfs_exists\tfs_size\tfs_sha256\tis_symlink\tsymlink_target\tmime\texec_bit\tgit_tracked\tgit_ls_tree" > "$OUT"

process_path() {
  p="$1"
  if [ -z "$p" ]; then return; fi
  m=$(jq -r --arg p "$p" '.entries[] | select(.path==$p) | @tsv "\(.path)\t\(.sha256 // "")\t\(.size_bytes // "")\t\(.mtime_iso // "")"' zz-manifests/manifest_master.json | sed 's/\t/|/g' || true)
  in_manifest="no"
  manifest_sha256=""
  manifest_size=""
  manifest_mtime=""
  if [ -n "$m" ]; then
    in_manifest="yes"
    manifest_sha256=$(echo "$m" | awk -F'|' '{print $2}')
    manifest_size=$(echo "$m" | awk -F'|' '{print $3}')
    manifest_mtime=$(echo "$m" | awk -F'|' '{print $4}')
  fi
  fs_exists="no"
  fs_size=""
  fs_sha256=""
  is_symlink="no"
  symlink_target=""
  mime=""
  exec_bit="no"
  git_tracked="no"
  git_ls_tree_out=""
  if [ -e "$p" ] || [ -L "$p" ]; then
    fs_exists="yes"
    if [ -L "$p" ]; then
      is_symlink="yes"
      symlink_target=$(readlink -- "$p" || true)
    fi
    fs_size=$(stat -c '%s' -- "$p" 2>/dev/null || stat -f '%z' -- "$p" 2>/dev/null || echo "")
    if [ -f "$p" ]; then
      fs_sha256=$(sha256sum -- "$p" 2>/dev/null | awk '{print $1}' || shasum -a256 -- "$p" 2>/dev/null | awk '{print $1}' || echo "")
      mime=$(file --brief --mime-type -- "$p" 2>/dev/null || echo "")
      [ -x "$p" ] && exec_bit="yes"
    fi
    git ls-files --error-unmatch -- "$p" >/dev/null 2>&1 && git_tracked="yes" || git_tracked="no"
    git_ls_tree_out=$(git ls-tree -l HEAD -- "$p" 2>/dev/null | tr '\t' ' ' | tr '\n' ' ' || echo "")
  fi

  echo -e "$p\t$in_manifest\t$manifest_sha256\t$manifest_size\t$manifest_mtime\t$fs_exists\t$fs_size\t$fs_sha256\t$is_symlink\t$symlink_target\t$mime\t$exec_bit\t$git_tracked\t$git_ls_tree_out" >> "$OUT"
}

if [ -n "$LIST" ]; then
  while IFS= read -r ln; do process_path "$ln"; done < "$LIST"
else
  while IFS= read -r ln; do process_path "$ln"; done
fi

echo "Wrote report: $OUT"
