#!/usr/bin/env bash
set -euo pipefail

TAG="v4.0.0-GOLD"
MESSAGE="Final Academic Version v4.0.0"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[fail] not inside a git worktree" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "[fail] worktree is dirty; commit or stash changes before tagging" >&2
  exit 1
fi

if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
  echo "[fail] local tag ${TAG} already exists; archival tags are immutable" >&2
  exit 1
fi

if git ls-remote --exit-code --tags origin "${TAG}" >/dev/null 2>&1; then
  echo "[fail] remote tag ${TAG} already exists; force-push is forbidden" >&2
  exit 1
fi

git tag -a "${TAG}" -m "${MESSAGE}"
echo "[ok] created annotated tag ${TAG}"
echo "[next] push with: git push origin main --tags"
