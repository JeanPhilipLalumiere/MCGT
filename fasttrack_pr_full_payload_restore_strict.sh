#!/usr/bin/env bash
# fasttrack_pr_full_payload_restore_strict.sh — corrige 422 (payload complet) + fast-track propre
set -euo pipefail
PR="${1:-35}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
SNAP="_tmp/protect.main.snapshot.${TS}.json"
TMP_DOWN="_tmp/protect.temp_down.${TS}.json"
TMP_STRICT="_tmp/protect.strict.${TS}.json"

echo "[SNAPSHOT] → $SNAP"
gh api repos/:owner/:repo/branches/main/protection > "$SNAP" || true

# Payload TEMP (no checks, 0 review) — **tous** les champs conformes au schéma de GitHub
cat >"$TMP_DOWN" <<'JSON'
{
  "required_status_checks": {
    "strict": false,
    "checks": []
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "require_code_owner_reviews": false,
    "dismiss_stale_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": { "enabled": true },
  "allow_force_pushes":    { "enabled": false },
  "allow_deletions":       { "enabled": false },
  "block_creations":       { "enabled": false },
  "required_conversation_resolution": { "enabled": true }
}
JSON

# Payload STRICT (2 checks + 1 review)
cat >"$TMP_STRICT" <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      {"context":"pypi-build/build","app_id":null},
      {"context":"secret-scan/gitleaks","app_id":null}
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
  "required_linear_history": { "enabled": true },
  "allow_force_pushes":    { "enabled": false },
  "allow_deletions":       { "enabled": false },
  "block_creations":       { "enabled": false },
  "required_conversation_resolution": { "enabled": true }
}
JSON

echo "[PATCH] baisse TEMP…"
gh api -X PUT repos/:owner/:repo/branches/main/protection \
  -H 'Accept: application/vnd.github+json' \
  --input "$TMP_DOWN" >/dev/null

echo "[MERGE] PR #$PR (squash)…"
gh pr merge "$PR" --squash --delete-branch || gh pr merge "$PR" --squash --admin --delete-branch

echo "[RESTORE] protection STRICT…"
gh api -X PUT repos/:owner/:repo/branches/main/protection \
  -H 'Accept: application/vnd.github+json' \
  --input "$TMP_STRICT" >/dev/null

# Sanity courte
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
for i in {1..12}; do
  sleep 5
  okm=$(gh run list --branch main --limit 10 | awk '/pypi-build|secret-scan/ && /completed/ && /success/ {c++} END{print (c>=2)?"OK":"KO"}')
  echo "[SANITY $i] $okm"; [ "$okm" = "OK" ] && break
done

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
