#!/usr/bin/env bash
set -euo pipefail

DAYS_LOGS="${1:-7}"
DAYS_ARCH="${2:-30}"

echo "[purge] .ci-logs/* plus vieux que ${DAYS_LOGS} jours"
find .ci-logs -type f -mtime +"${DAYS_LOGS}" -print -delete 2>/dev/null || true
find .ci-logs -type d -empty -delete 2>/dev/null || true

echo "[purge] .ci-archive/* plus vieux que ${DAYS_ARCH} jours"
find .ci-archive -mindepth 1 -maxdepth 1 -mtime +"${DAYS_ARCH}" -print -exec rm -rf {} \; 2>/dev/null || true

echo "[purge] DONE"
