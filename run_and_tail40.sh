#!/usr/bin/env bash
set -Eeuo pipefail
BR="${1:-release/zz-tools-0.3.1}"
WF=".github/workflows/manifest-guard.yml"
NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "[INFO] REPO=$NWO BR=$BR"

num(){ [[ "$1" =~ ^[0-9]+$ ]]; }
latest_id(){ gh api repos/$NWO/actions/workflows/manifest-guard.yml/runs -F branch="$BR" -F per_page=1 -q '.workflow_runs[0].id' 2>/dev/null || true; }

OLD="$(latest_id)"; echo "[INFO] OLD_RUN=${OLD:-<none>}"
gh workflow run "$WF" --ref "$BR" >/dev/null || true

for i in {1..60}; do
  sleep 2
  NEW="$(latest_id)"
  if num "${NEW:-}"; [[ -z "${OLD:-}" || "$NEW" != "$OLD" ]]; then echo "[INFO] NEW_RUN=$NEW"; RID="$NEW"; break; fi
  echo "[WAIT] poll $i… (old=${OLD:-Ø} new=${NEW:-Ø})"
done
[[ -z "${RID:-}" ]] && echo "[WARN] Nouveau run non observé." && exit 1

# Jobs → errors + tail 40 (fallback résumé si 0 job)
OUT=".ci-out"; mkdir -p "$OUT"
gh api repos/$NWO/actions/runs/"$RID"/jobs --paginate -q '.jobs[] | "\(.id)\t\(.name)\t\(.status)\t\(.conclusion)"' > "$OUT/manifest_guard_jobs.tsv" || true

if ! [[ -s "$OUT/manifest_guard_jobs.tsv" ]]; then
  echo "[WARN] 0 job → résumé run-level :"
  gh run view "$RID" --json name,displayTitle,status,conclusion,event,headBranch,headSha,createdAt,updatedAt,url \
    -q '"name=\(.name) | title=\(.displayTitle) | status=\(.status) | conclusion=\(.conclusion) | event=\(.event) | branch=\(.headBranch) | sha=\(.headSha) | created=\(.createdAt) | updated=\(.updatedAt) | url=\(.url)"'
  exit 0
fi

JID="$(awk -F'\t' 'NR==1{print $1}' "$OUT/manifest_guard_jobs.tsv")"
LOG="$OUT/manifest_guard_JOB_${JID}.log"
gh run view "$RID" --job "$JID" --log | tee "$LOG" >/dev/null

echo "===== ::error:: ====="
sed -n 's/.*::error::\(.*\)$/\1/p' "$LOG" | tee "$OUT/manifest_guard_ERRORS.txt"

echo "===== LAST 40 LINES ====="
tail -n 40 "$LOG" | sed 's/\r$//'
