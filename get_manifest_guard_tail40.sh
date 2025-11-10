#!/usr/bin/env bash
set -Eeuo pipefail
BR="${1:-release/zz-tools-0.3.1}"
OUT=".ci-out"; mkdir -p "$OUT"
NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "[INFO] REPO=$NWO BR=$BR"

num(){ [[ "$1" =~ ^[0-9]+$ ]]; }

RID="$(gh api repos/$NWO/actions/workflows/manifest-guard.yml/runs \
      -F branch="$BR" -F per_page=1 -q '.workflow_runs[0].id' 2>/dev/null || true)"
if ! num "${RID:-}"; then
  RID="$(gh run list --workflow=manifest-guard.yml --branch "$BR" --limit 1 \
        --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
fi
if ! num "${RID:-}"; then echo "[ERR] aucun run pour $BR"; exit 2; fi
echo "[INFO] RUN=$RID"

gh api repos/$NWO/actions/runs/"$RID"/jobs --paginate \
  -q '.jobs[] | "\(.id)\t\(.name)\t\(.status)\t\(.conclusion)"' \
  | tee "$OUT/manifest_guard_jobs.tsv" >/dev/null || true

if ! [[ -s "$OUT/manifest_guard_jobs.tsv" ]]; then
  echo "[WARN] 0 job → YAML court-circuité / concurrency / if."
  gh run view "$RID" --json name,displayTitle,status,conclusion,event,headBranch,headSha,createdAt,updatedAt,url \
    -q '"name=\(.name) | title=\(.displayTitle) | status=\(.status) | conclusion=\(.conclusion) | event=\(.event) | branch=\(.headBranch) | sha=\(.headSha) | created=\(.createdAt) | updated=\(.updatedAt) | url=\(.url)"'
  exit 0
fi

JID="$(awk -F'\t' 'NR==1{print $1}' "$OUT/manifest_guard_jobs.tsv")"
echo "[INFO] JOB=$JID"
LOG="$OUT/manifest_guard_JOB_${JID}.log"
gh run view "$RID" --job "$JID" --log | tee "$LOG" >/dev/null

echo "===== ::error:: (normalisées) ====="
sed -n 's/.*::error::\(.*\)$/\1/p' "$LOG" | tee "$OUT/manifest_guard_ERRORS.txt"

echo "===== LAST 40 LINES ====="
tail -n 40 "$LOG" | sed 's/\r$//'
