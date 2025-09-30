#!/usr/bin/env bash
# step-03-archive-single.sh <path>
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-03-archive-single.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-03 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-archive> [APPLY=1]" >&2
  status=2
  trap 'read -p "Press Enter to close..."' EXIT
  exit "$status"
fi
P="$1"
cd "$(git rev-parse --show-toplevel)"

if [[ ! -e "$P" ]]; then
  echo "Not found: $P"; status=3
else
  ARCHDIR=".tmp-cleanup-backup"; mkdir -p "$ARCHDIR"
  ARCHNAME="$(basename "$P")_$(date -u +%Y%m%dT%H%M%SZ).tar.zst"
  echo "Preview: $P"
  du -sh "$P" || true
  if [[ "${APPLY:-0}" != "1" ]]; then
    echo "Dry-run. To actually archive: APPLY=1 $0 $P"
    status=0
  else
    if command -v zstd >/dev/null 2>&1; then
      tar -C "$(dirname "$P")" -cf - "$(basename "$P")" | zstd -q -z -19 -o "${ARCHDIR}/${ARCHNAME}"
    else
      tar -C "$(dirname "$P")" -czf "${ARCHDIR}/${ARCHNAME%.zst}.tar.gz" "$(basename "$P")"
      ARCHNAME="${ARCHNAME%.zst}.tar.gz"
    fi
    echo "Archived to ${ARCHDIR}/${ARCHNAME}"
    status=0
  fi
fi

echo "END: step-03 (status=$status)"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-03 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
  exit "$status"
}
trap _on_exit EXIT
