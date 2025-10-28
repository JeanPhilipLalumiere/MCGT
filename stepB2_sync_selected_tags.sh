#!/usr/bin/env bash
# File: stepB2_sync_selected_tags.sh
# Usage:
#   ./stepB2_sync_selected_tags.sh v0.2.75 v0.2.76 ...
set -euo pipefail
[[ $# -ge 1 ]] || { echo "[ERR] préciser au moins 1 tag à resynchroniser"; exit 2; }

need(){ command -v "$1" >/dev/null || { echo "[ERR] $1 manquant"; exit 2; }; }
need git

echo "[INFO] Fetch ciblé des tags demandés (métadonnées)…"
git fetch --tags --prune --no-write-fetch-head origin || true

for tag in "$@"; do
  echo "[STEP] $tag"
  local_sha="$(git rev-parse -q --verify "refs/tags/$tag^{})" 2>/dev/null || true)"
  remote_sha="$(git ls-remote --tags origin "$tag" | grep -v '\^{}' | awk '{print $1}' || true)"

  if [[ -z "$remote_sha" ]]; then
    echo "  [WARN] $tag absent sur origin → skip"
    continue
  fi

  if [[ -n "$local_sha" && "$local_sha" == "$remote_sha" ]]; then
    echo "  [OK] déjà aligné ($local_sha)"
    continue
  fi

  if [[ -n "$local_sha" ]]; then
    echo "  [INFO] supprime tag local divergent ($local_sha) → $remote_sha"
    git tag -d "$tag"
  fi

  echo "  [INFO] récupère tag distant exact"
  git fetch origin "refs/tags/$tag:refs/tags/$tag"
  echo "  [OK] $tag aligné sur $remote_sha"
done

echo "[DONE] Tags sélectionnés alignés local←origin. Aucun push effectué."
