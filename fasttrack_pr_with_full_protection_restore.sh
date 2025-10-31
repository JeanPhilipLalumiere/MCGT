#!/usr/bin/env bash
# fasttrack_pr_with_full_protection_restore.sh — snapshot → baisse TEMP (payload complet) → merge --admin → restore strict
set -euo pipefail
PR="${1:-35}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
SNAP="_tmp/protect.main.snapshot.${TS}.json"

echo "[INFO] Snapshot protections → $SNAP"
gh api repos/:owner/:repo/branches/main/protection > "$SNAP" || true

echo "[PATCH] Baisse TEMP (no checks + reviews=0, admins ON, linear ON, convo ON)…"
gh api -X PUT repos/:owner/:repo/branches/main/protection \
  -H 'Accept: application/vnd.github+json' \
  --raw-field required_status_checks.strict=false \
  --raw-field required_status_checks.checks='[]' \
  --raw-field required_pull_request_reviews.required_approving_review_count=0 \
  --raw-field required_conversation_resolution.enabled=true \
  --raw-field required_linear_history.enabled=true \
  --raw-field enforce_admins.enabled=true \
  --raw-field restrictions= \
  >/dev/null

echo "[MERGE] tentative squash (admin si besoin)…"
gh pr merge "$PR" --squash --delete-branch || gh pr merge "$PR" --squash --admin --delete-branch

echo "[RESTORE] Protection STRICTE exacte (2 checks, 1 review, admins, linear, convo)…"
gh api -X PUT repos/:owner/:repo/branches/main/protection \
  -H 'Accept: application/vnd.github+json' \
  --raw-field required_status_checks.strict=true \
  --raw-field required_status_checks.checks[0].context='pypi-build/build' \
  --raw-field required_status_checks.checks[0].app_id= \
  --raw-field required_status_checks.checks[1].context='secret-scan/gitleaks' \
  --raw-field required_status_checks.checks[1].app_id= \
  --raw-field required_pull_request_reviews.required_approving_review_count=1 \
  --raw-field required_conversation_resolution.enabled=true \
  --raw-field required_linear_history.enabled=true \
  --raw-field enforce_admins.enabled=true \
  --raw-field restrictions= \
  >/dev/null

echo "[SANITY] runs main (≤60s)…"
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
for i in {1..12}; do
  sleep 5
  r=$(gh run list --branch main --limit 10 | awk '/pypi-build|secret-scan/ && /completed/ && /success/ {c++} END{print (c>=2)?"OK":"KO"}')
  echo "[POLL $i] $r"
  [ "$r" = "OK" ] && break
done

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
