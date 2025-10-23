#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="${1:-$(pwd)}"
cd "$REPO_DIR"

mkdir -p _tmp
git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' 2>/dev/null \
  | awk '$1=="blob" {print $3"\t"$2"\t"substr($0,index($0,$4))}' \
  | sort -nr > _tmp/git_blob_by_size.tsv

awk '$1>5000000{print $0}' _tmp/git_blob_by_size.tsv > _tmp/git_blobs_gt5MB.tsv || true
find . -type f -not -path "./.git/*" -size +5M -print > _tmp/large_files_in_worktree.txt || true
find . -type l -print0 | xargs -0 -n1 -I{} sh -c 'echo "{} -> $(readlink "{}")"' > _tmp/symlinks_list.txt || true

echo "Wrote _tmp/git_blob_by_size.tsv, _tmp/git_blobs_gt5MB.tsv, _tmp/large_files_in_worktree.txt, _tmp/symlinks_list.txt"
