#!/usr/bin/env bash
# Usage: ./echo_last40_or_run_summary.sh release/zz-tools-0.3.1
set -Eeuo pipefail
BR="${1:-release/zz-tools-0.3.1}"
OUT=".ci-out"; mkdir -p "$OUT"

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
  | tee "$OUT/manifest_guard_jobs.tsv" >/dev/null || true

JID="$(awk -F'\t' 'NR==1{print $1}' "$OUT/manifest_guard_jobs.tsv" 2>/dev/null || true)"
JNAME="$(awk -F'\t' 'NR==1{print $2}' "$OUT/manifest_guard_jobs.tsv" 2>/dev/null || true)"
echo "[INFO] JOB ID: ${JID:-<none>} — NAME: ${JNAME:-<unknown>}"

if [[ -n "${JID:-}" ]]; then
  JOBLOG="$OUT/manifest_guard_JOB_${JID}.log"
  echo "[STEP] Fetch job log → $JOBLOG"
  if gh run view "$RID" --job "$JID" --log > "$JOBLOG" 2>"$OUT/manifest_guard_JOB_${JID}.err"; then
    echo "===== ::error:: lines (if any) ====="
    sed -n 's/.*::error::\(.*\)$/\1/p' "$JOBLOG" | tee "$OUT/manifest_guard_LAST_remote_errors.txt"
    echo "===== LAST 40 LINES ($JOBLOG) ====="
    tail -n 40 "$JOBLOG" | tee "$OUT/manifest_guard_LAST_remote_tail40.txt"
    exit 0
  else
    echo "[WARN] gh run view --job failed; stderr → $OUT/manifest_guard_JOB_${JID}.err"
  fi
fi

# Fallback: tenter le log du run (pas de job → souvent workflow invalid avant start)
RUNLOG="$OUT/manifest-guard_${RID}.log"
echo "[STEP] Try run-level log → $RUNLOG"
if gh run view "$RID" --log > "$RUNLOG" 2>"$OUT/manifest-guard_${RID}.err"; then
  echo "===== ::error:: lines (if any, run-level) ====="
  sed -n 's/.*::error::\(.*\)$/\1/p' "$RUNLOG" | tee "$OUT/manifest_guard_LAST_run_errors.txt"
  echo "===== LAST 40 LINES ($RUNLOG) ====="
  tail -n 40 "$RUNLOG" | tee "$OUT/manifest_guard_LAST_run_tail40.txt"
  exit 0
else
  echo "[WARN] No run-level log available; stderr → $OUT/manifest-guard_${RID}.err"
fi

# Dernier recours : résumé du run + lint local du workflow (pour détecter YAML invalid)
echo "[STEP] Run summary (why no jobs?)"
gh run view "$RID" --json name,displayTitle,status,conclusion,event,headBranch,headSha,createdAt,updatedAt,htmlURL \
  -q '"name=\(.name) | title=\(.displayTitle) | status=\(.status) | conclusion=\(.conclusion) | event=\(.event) | branch=\(.headBranch) | sha=\(.headSha) | created=\(.createdAt) | updated=\(.updatedAt) | url=\(.htmlURL)"' \
  | tee "$OUT/manifest_guard_RUN_summary.txt" || true

WF=".github/workflows/manifest-guard.yml"
echo "[STEP] Local YAML quick check → $WF"
if command -v actionlint >/dev/null 2>&1; then
  echo "===== actionlint (first 40 lines) ====="
  # Ne spécifie pas de format ; on tronque juste la sortie
  (actionlint || true) | head -n 40 | tee "$OUT/manifest_guard_actionlint_head40.txt"
else
  echo "[HINT] actionlint not installed. Minimal YAML check via python -c (pyyaml) if present."
  python3 - <<'PY' 2>&1 | head -n 40 | tee "$OUT/manifest_guard_yamlcheck_head40.txt" || true
try:
    import sys, yaml
    from yaml import Loader
    with open(".github/workflows/manifest-guard.yml","rb") as f:
        yaml.load(f, Loader=Loader)
    print("[OK] YAML parsed without exception.")
except Exception as e:
    print("[YAML-ERROR]", e)
PY
fi

echo "[DONE] No job log available; provided run summary and local lint."
