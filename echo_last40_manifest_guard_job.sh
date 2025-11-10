#!/usr/bin/env bash
# Usage: ./echo_last40_manifest_guard_job.sh release/zz-tools-0.3.1
set -u
BR="${1:-release/zz-tools-0.3.1}"
OUT=".ci-out"
mkdir -p "$OUT"

echo "[STEP] Locate latest run id for manifest-guard on $BR"
RID="$(gh run list --workflow=manifest-guard.yml --branch "$BR" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
echo "[INFO] RUN ID: ${RID:-<none>}"
if [[ -z "${RID:-}" ]]; then
  echo "[ERROR] No run id found for branch '$BR'." >&2
  exit 2
fi

NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "[INFO] REPO: $NWO"

echo "[STEP] List jobs for run $RID"
gh api repos/$NWO/actions/runs/"$RID"/jobs --paginate -q '.jobs[] | "\(.id)\t\(.name)\t\(.status)\t\(.conclusion)"' \
  | tee "$OUT/manifest_guard_jobs.tsv" >/dev/null

JID="$(awk -F'\t' 'NR==1{print $1}' "$OUT/manifest_guard_jobs.tsv")"
JNAME="$(awk -F'\t' 'NR==1{print $2}' "$OUT/manifest_guard_jobs.tsv")"
echo "[INFO] JOB ID: ${JID:-<none>} — NAME: ${JNAME:-<unknown>}"
if [[ -z "${JID:-}" ]]; then
  echo "[ERROR] No job found for run $RID." >&2
  exit 3
fi

JOBLOG="$OUT/manifest_guard_JOB_${JID}.log"
echo "[STEP] Fetch job log → $JOBLOG"
if ! gh run view "$RID" --job "$JID" --log > "$JOBLOG" 2>"$OUT/manifest_guard_JOB_${JID}.err"; then
  echo "[WARN] gh run view failed. See $OUT/manifest_guard_JOB_${JID}.err" >&2
  echo "[HINT] Falling back to run-level log if present."
  RUNLOG="$OUT/manifest-guard_${RID}.log"
  if [[ -f "$RUNLOG" ]]; then
    JOBLOG="$RUNLOG"
    echo "[INFO] Using fallback: $RUNLOG"
  else
    echo "[ERROR] No job or run log available." >&2
    exit 4
  fi
fi

echo "===== ::error:: lines (if any) ====="
sed -n 's/.*::error::\(.*\)$/\1/p' "$JOBLOG" | tee "$OUT/manifest_guard_LAST_remote_errors.txt"

echo "===== LAST 40 LINES ($JOBLOG) ====="
tail -n 40 "$JOBLOG" | tee "$OUT/manifest_guard_LAST_remote_tail40.txt"
