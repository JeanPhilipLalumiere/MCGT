#!/usr/bin/env bash
# enforce_protection_and_sanity_now.sh
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"; cd "$REPO_ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/enforce_and_sanity_${TS}.log"
SNAP="_tmp/protect.main.snapshot.${TS}.json"
PATCH="_tmp/protect.main.strict.${TS}.json"

say(){ echo -e "$*" | tee -a "$LOG"; }
finish(){ read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true; }
trap finish EXIT

say "[STEP] Snapshot protections → $SNAP"
if ! gh api repos/:owner/:repo/branches/main/protection > "$SNAP" 2>>"$LOG"; then
  say "[WARN] Lecture protection a échoué (auth/permissions ?). On continue avec patch canonique."
fi

say "[STEP] Construire payload STRICT (2 checks, 1 review, conv, linear, admins)"
cat > "$PATCH" <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      {"context": "pypi-build/build", "app_id": null},
      {"context": "secret-scan/gitleaks", "app_id": null}
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

say "[APPLY] PUT protection stricte (main)"
if ! gh api -X PUT repos/:owner/:repo/branches/main/protection \
      -H "Accept: application/vnd.github+json" --input "$PATCH" >>"$LOG" 2>&1; then
  say "[ERROR] Échec PUT protection. Vérifie droits Admin Branch Protection."
fi

say "[VERIFY] Lecture protection post-apply (robuste)"
VERIFY_JSON="$(gh api repos/:owner/:repo/branches/main/protection 2>>"$LOG" || true)"
echo "$VERIFY_JSON" | jq '{
  strict:(.required_status_checks?.strict // false),
  checks:((.required_status_checks?.checks // [])|map(.context) // []),
  reviews:(.required_pull_request_reviews?.required_approving_review_count // 0),
  conv:(.required_conversation_resolution?.enabled // false)
}' | tee "_tmp/protect.verify.${TS}.json"

say "[DISPATCH] pypi-build.yml & secret-scan.yml sur ref=main"
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
sleep 5

say "[POLL] ≤ 60s pour SUCCESS des 2 contexts"
ok=0
for i in $(seq 1 12); do
  stat="$(gh run list --branch main --limit 20 2>/dev/null \
        | awk '/pypi-build|secret-scan/ {print $2}' | paste -sd, -)"
  echo "[POLL $i] ${stat:-'(no runs yet)'}" | tee -a "$LOG"
  succ=$(echo "${stat}" | grep -c success || true)
  if [[ "$succ" -ge 2 ]]; then ok=1; break; fi
  sleep 5
done

[[ "$ok" -eq 1 ]] && say "[OK] Deux checks verts sur main." || say "[WARN] Les deux checks ne sont pas tous verts (à reconsidérer)."
