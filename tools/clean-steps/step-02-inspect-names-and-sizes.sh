#!/usr/bin/env bash
# step-02-inspect-names-and-sizes.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-02-inspect-names-and-sizes.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-02 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"

if [[ ! -f step-01-candidates.txt ]]; then
  echo "Please run step-01-list-candidates.sh first."
  status=1
else
  > step-02-details.txt
  while IFS= read -r p; do
    [[ -e "$p" ]] || continue
    printf "---- %s ----\n" "$p" | tee -a step-02-details.txt
    ls -lbn "$p" 2>/dev/null | tee -a step-02-details.txt || ls -ld -- "$p" 2>/dev/null | tee -a step-02-details.txt
    stat --printf='inode=%i size=%s bytes\n' "$p" 2>/dev/null | tee -a step-02-details.txt || true
    du -sh "$p" 2>/dev/null | tee -a step-02-details.txt || true
  done < step-01-candidates.txt
  echo "Wrote step-02-details.txt"
  # detect long names
  echo "Detecting very long paths (len>200) and non-printable names:"
  find . -maxdepth 2 -print0 | while IFS= read -r -d '' f; do
    n=${#f}
    if (( n > 200 )); then printf "LONG:%d:%s\n" "$n" "$f"; fi
    if printf '%s' "$(basename "$f")" | LC_ALL=C grep -q '[^ -~]' 2>/dev/null; then
      printf "NONPRINTABLE:%s\n" "$f"
    fi
  done | tee -a step-02-details.txt
  status=0
fi

echo "END: step-02 (status=$status)"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-02 finished (log: %s, details: step-02-details.txt) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
  exit "$status"
}
trap _on_exit EXIT
