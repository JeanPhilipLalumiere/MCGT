#!/usr/bin/env bash
# tools/clean-steps/run-all-steps.sh
# Wrapper to run step-00 .. step-13 created earlier.
# - Dry-run by default (no destructive action unless --apply)
# - Keeps the terminal open at the end by launching an interactive shell
#   unless --noninteractive is passed.
#
# Usage:
#   bash tools/clean-steps/run-all-steps.sh
#   bash tools/clean-steps/run-all-steps.sh --apply
#   bash tools/clean-steps/run-all-steps.sh --apply --noninteractive
#   bash tools/clean-steps/run-all-steps.sh --start 3 --end 7
set -euo pipefail

# --- locate repo root and cd there if possible
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "${ROOT}" ]]; then cd "${ROOT}"; fi

SCRIPTDIR="tools/clean-steps"
LOGDIR=".tmp-cleanup-logs"
mkdir -p "${LOGDIR}"
AGGLOG="${LOGDIR}/run-all.log"

# Defaults
DO_APPLY=0
NONINTERACTIVE=0
START=0
END=13
STOP_ON_ERROR=0

usage() {
  cat <<EOF
Usage: $0 [--apply] [--noninteractive] [--start N] [--end N] [--stop-on-error]
  --apply           : actually apply deletions (default: dry-run)
  --noninteractive  : don't drop into interactive shells / don't prompt
  --start N         : start at step N (default 0)
  --end N           : end at step N (default 13)
  --stop-on-error   : stop if a step exits non-zero
  --help
EOF
  exit 1
}

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) DO_APPLY=1; shift ;;
    --noninteractive) NONINTERACTIVE=1; shift ;;
    --start) START="$2"; shift 2 ;;
    --end) END="$2"; shift 2 ;;
    --stop-on-error) STOP_ON_ERROR=1; shift ;;
    --help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

# Safety: refuse if there are staged changes
if ! git diff --quiet --cached; then
  echo "ERROR: you have staged changes; commit or unstage before running." | tee -a "${AGGLOG}" >&2
  if [[ "${NONINTERACTIVE}" -eq 0 ]]; then
    echo "Press Enter to keep session open for inspection..."
    read -r _
    /bin/bash -i
  fi
  exit 1
fi

# Trap for unexpected errors: drop to shell for debugging (unless noninteractive)
on_err() {
  local lineno="$1"; local rc=${2:-1}
  echo "" | tee -a "${AGGLOG}"
  echo "=== ERROR: script failed at line ${lineno} (rc=${rc}) ===" | tee -a "${AGGLOG}" >&2
  echo "Aggregate log: ${AGGLOG}" | tee -a "${AGGLOG}"
  if [[ "${NONINTERACTIVE}" -eq 0 ]]; then
    echo ""
    echo "Dropping to an interactive shell for inspection. Type 'exit' to close it."
    /bin/bash -i
  fi
  exit "${rc}"
}
trap 'on_err "${LINENO}" "$?"' ERR

# Build ordered list of step scripts (step-00 .. step-13)
steps=()
for i in $(seq -w 0 13); do
  # pick the first matching step file for index i
  mapfile -t found < <(ls "${SCRIPTDIR}/step-$(printf "%02d" "$i")-*.sh" 2>/dev/null || true)
  if [[ ${#found[@]} -gt 0 ]]; then
    steps+=("${found[0]}")
  fi
done

if [[ ${#steps[@]} -eq 0 ]]; then
  echo "No step scripts found in ${SCRIPTDIR}; nothing to run." | tee -a "${AGGLOG}"
  if [[ "${NONINTERACTIVE}" -eq 0 ]]; then
    echo "Dropping to interactive shell for inspection..."
    /bin/bash -i
  fi
  exit 1
fi

echo "Run-all starting at $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee "${AGGLOG}"
echo "Options: APPLY=${DO_APPLY} NONINTERACTIVE=${NONINTERACTIVE} START=${START} END=${END} STOP_ON_ERROR=${STOP_ON_ERROR}" | tee -a "${AGGLOG}"
echo "Steps discovered: ${#steps[@]}" | tee -a "${AGGLOG}"
echo "" | tee -a "${AGGLOG}"

index=0
for step in "${steps[@]}"; do
  base="$(basename "${step}")"
  num="${base:5:2}"   # extract "##" from step-##-...
  # handle leading zero
  num=$((10#$num))

  if (( num < START )) || (( num > END )); then
    ((index++))
    continue
  fi

  echo "------------------------------------------------------------" | tee -a "${AGGLOG}"
  printf "STEP %02d: %s\n" "${num}" "${step}" | tee -a "${AGGLOG}"
  echo "Started at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "${AGGLOG}"

  export APPLY="${DO_APPLY}"
  export NONINTERACTIVE="${NONINTERACTIVE}"

  start_ts=$(date +%s)
  rc=0

  if [[ "${NONINTERACTIVE}" -eq 1 ]]; then
    # Noninteractive: run quietly and append both stdout/stderr to agglog
    bash "${step}" >> "${AGGLOG}" 2>&1 || rc=$?
  else
    # Interactive: stream output in real time to console AND log (tee)
    # Use a subshell so that any 'exit' inside step doesn't kill this wrapper
    ( bash "${step}" 2>&1 | tee -a "${AGGLOG}" ) || rc=$?
  fi

  dur=$(( $(date +%s) - start_ts ))
  printf "STEP %02d EXIT CODE: %d (duration: %ds)\n" "${num}" "${rc}" "${dur}" | tee -a "${AGGLOG}"
  echo "Ended at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "${AGGLOG}"

  if [[ "${rc}" -ne 0 ]]; then
    echo "WARNING: step ${step} exited with code ${rc}" | tee -a "${AGGLOG}" >&2
    if [[ "${STOP_ON_ERROR}" -eq 1 ]]; then
      echo "Stopping due to --stop-on-error. See ${AGGLOG} for details." | tee -a "${AGGLOG}"
      if [[ "${NONINTERACTIVE}" -eq 0 ]]; then
        echo "Dropping to interactive shell for inspection..."
        /bin/bash -i
      fi
      exit "${rc}"
    else
      # if not stopping, allow interactive inspection (unless noninteractive)
      if [[ "${NONINTERACTIVE}" -eq 0 ]]; then
        echo ""
        echo "Step failed but --stop-on-error not set. You can inspect and then continue."
        echo "Press Enter to continue to next step or Ctrl-C to abort..."
        read -r _
      fi
    fi
  else
    # success
    if [[ "${NONINTERACTIVE}" -eq 0 ]]; then
      echo ""
      echo "STEP ${num} completed successfully. Press Enter to continue..."
      read -r _
    fi
  fi

  ((index++))
done

echo ""
echo "All requested steps completed at $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee -a "${AGGLOG}"
echo "Aggregate log: ${AGGLOG}" | tee -a "${AGGLOG}"

# Keep the terminal open for inspection unless user explicitly asked noninteractive.
if [[ "${NONINTERACTIVE}" -eq 0 ]]; then
  echo ""
  echo "Opening an interactive shell so the window remains open."
  echo "Type 'exit' to return to your original shell (or close the window)."
  # exec replaces this process with interactive shell so the terminal stays alive here.
  exec /bin/bash -i
else
  echo "Noninteractive mode: exiting normally."
  exit 0
fi
