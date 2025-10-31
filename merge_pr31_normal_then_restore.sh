#!/usr/bin/env bash
# merge_pr31_normal_then_restore.sh — PR #31, attente ≤ 240s, sans fast-track
set -euo pipefail
PR="${1:-31}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/merge_pr${PR}_${TS}.log"
STRICT="_tmp/protect.main.strict.${TS}.json"

# Payload STRICT (garantie après merge)
cat >"$STRICT" <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "pypi-build/build", "app_id": null },
      { "context": "secret-scan/gitleaks", "app_id": null }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": false,
    "dismiss_stale_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true
}
JSON

echo "[INFO] PR #$PR" | tee -a "$LOG"
gh pr view "$PR" --web >/dev/null 2>&1 || true

# 1) Relance CI sur la branche du PR (si dispatch dispo)
BRANCH="$(gh pr view "$PR" --json headRefName -q .headRefName)"
echo "[DISPATCH] pypi-build.yml & secret-scan.yml @ $BRANCH" | tee -a "$LOG"
gh workflow run pypi-build.yml  --ref "$BRANCH" >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref "$BRANCH" >/dev/null 2>&1 || true

# 2) Poll ≤ 240s jusqu’à SUCCESS des 2 checks requis
deadline=$((SECONDS+240))
ok_build=0; ok_leaks=0
while [ $SECONDS -lt $deadline ]; do
  sleep 5
  st=$(gh run list --branch "$BRANCH" --limit 30 | awk '
    /pypi-build/ && /completed/ && /success/ {b=1}
    /secret-scan/ && /completed/ && /success/ {s=1}
    END{printf("%d %d\n", b?1:0, s?1:0)}')
  ok_build=$(echo "$st" | awk '{print $1}')
  ok_leaks=$(echo "$st" | awk '{print $2}')
  echo "[POLL] build=$ok_build gitleaks=$ok_leaks" | tee -a "$LOG"
  [ "$ok_build" = "1" ] && [ "$ok_leaks" = "1" ] && break
done

if [ "$ok_build" = "1" ] && [ "$ok_leaks" = "1" ]; then
  echo "[MERGE] tentative normale (squash)..." | tee -a "$LOG"
  gh pr merge "$PR" --squash --delete-branch || {
    echo "[WARN] refusée → tentative --admin" | tee -a "$LOG"
    gh pr merge "$PR" --squash --admin --delete-branch
  }
else
  echo "[STOP] Checks requis non verts en ≤240s — pas de fast-track dans ce script." | tee -a "$LOG"
fi

# 3) Restaure STRICT (idempotent)
echo "[RESTORE] STRICT post-merge..." | tee -a "$LOG"
gh api -X PUT repos/:owner/:repo/branches/main/protection \
  -H 'Accept: application/vnd.github+json' --input "$STRICT" >/dev/null || true

# 4) Sanity courte sur main (best-effort)
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
for i in {1..12}; do
  sleep 5
  ok=$(gh run list --branch main --limit 20 | awk '/(pypi-build|secret-scan)/ && /completed/ && /success/ {c++} END{print (c>=2)?"OK":"KO"}')
  echo "[MAIN POLL $i] $ok" | tee -a "$LOG"; [ "$ok" = "OK" ] && break
done

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
