#!/usr/bin/env bash
# enforce_protection_strict_now.sh — Verrouille protections strictes (2 checks, 1 review) + sanity courte
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/enforce_protection_${TS}.log"
SNAP="_tmp/protect.main.snapshot.${TS}.json"
READ="_tmp/protect.main.read.${TS}.json"

echo "[SNAP] lecture protection actuelle" | tee -a "$LOG"
gh api repos/:owner/:repo/branches/main/protection > "$SNAP"

echo "[APPLY] protection stricte (2 checks, 1 review)" | tee -a "$LOG"
cat > _tmp/protect.main.strict.${TS}.json <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      {"context":"pypi-build/build","app_id": null},
      {"context":"secret-scan/gitleaks","app_id": null}
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
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
JSON

if ! gh api -X PUT repos/:owner/:repo/branches/main/protection \
  -H "Accept: application/vnd.github+json" \
  --input "_tmp/protect.main.strict.${TS}.json" >/dev/null 2>&1; then
  echo "[WARN] PUT a échoué (422 fréquent). Nouvelle lecture et vérification…" | tee -a "$LOG"
fi

gh api repos/:owner/:repo/branches/main/protection > "$READ"
jq -r '{
  strict: (.required_status_checks.strict),
  checks: (.required_status_checks.checks | map(.context)),
  reviews: (.required_pull_request_reviews.required_approving_review_count),
  conv: (.required_conversation_resolution.enabled)
}' "$READ" | tee -a "$LOG"

echo "[SANITY] déclenche best-effort sur main (si dispatch dispo) + poll court" | tee -a "$LOG"
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
for i in {1..12}; do
  runs="$(gh run list --branch main --limit 10 | grep -E 'pypi-build|secret-scan' || true)"
  echo "[POLL $i] $(echo "$runs" | awk 'NR==1{print $0;exit}')" | tee -a "$LOG"
  echo "$runs" | grep -qi success && { echo "[OK] sanity" | tee -a "$LOG"; break; }
  sleep 5
done

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
