#!/usr/bin/env bash
# CH05 – Wrapper canonique vers _tools/run_ch05_pipeline_minimal.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

TARGET="_tools/run_ch05_pipeline_minimal.sh"

if [ ! -x "$TARGET" ]; then
  echo "[CH05][ERREUR] Script interne manquant ou non exécutable: $TARGET" >&2
  exit 1
fi

exec "$TARGET" "$@"
