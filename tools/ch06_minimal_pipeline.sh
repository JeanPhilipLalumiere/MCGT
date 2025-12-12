#!/usr/bin/env bash
# CH06 – Wrapper canonique vers _tools/run_ch06_pipeline_minimal.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

TARGET="_tools/run_ch06_pipeline_minimal.sh"

if [ ! -x "$TARGET" ]; then
  echo "[CH06][ERREUR] Script interne manquant ou non exécutable: $TARGET" >&2
  exit 1
fi

exec "$TARGET" "$@"
