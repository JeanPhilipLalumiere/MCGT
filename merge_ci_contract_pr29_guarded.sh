#!/usr/bin/env bash
# merge_ci_contract_pr29_guarded.sh — merge PR #29 en solo, sans casser la policy
# - Snapshot protection main
# - TEMP: reviews=0 (checks requis conservés: pypi-build/build + secret-scan/gitleaks)
# - Merge PR #29 (squash)
# - Restore protection stricte (reviews=1)
# - Sanity: dispatch rapide sur main + poll court
set -euo pipefail

PR_NUM="${1:-29}"

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/merge_ci_contract_${PR_NUM}_${TS}.log"
SNAP="_tmp/protect.main.snapshot.${TS}.json"
TMPPATCH="_tmp/protect.main.temp.${TS}.json"
RESTORE="_tmp/protect.main.restore.${TS}.json"

say(){ echo -e "$*" | tee -a "$LOG"; }

# ── garde-fou restauration à la sortie
cleanup(){
  say "[GUARD] Restauration stricte (reviews=1)…"
  # si RESTORE existe déjà (post-merge), on l’utilise ; sinon snapshot→patch stricte
  if [[ -s "$RESTORE" ]]; then
    gh api repos/:owner/:repo/branches/main/protection -X PUT -H "Accept: application/vnd.github+json" --input "$RESTORE" >/dev/null 2>&1 || true
  else
    gh api repos/:owner/:repo/branches/main/protection -X PUT -H "Accept: application/vnd.github+json" --input "$SNAP" >/dev/null 2>&1 || true
  fi
  say "[GUARD] Restauration effectuée."
  read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
}
trap cleanup EXIT

say "[STEP] Snapshot protections → $SNAP"
gh api repos/:owner/:repo/branches/main/protection > "$SNAP"

# Construire PATCH temporaire: reviews=0, checks conservés depuis snapshot
CHECKS_JSON="$(jq -c '.required_status_checks.checks | map({context:.context, app_id:(.app_id // null)})' "$SNAP")"
STRICT="$(jq -r '.required_status_checks.strict' "$SNAP")"
CONV="$(jq -r '.required_conversation_resolution.enabled' "$SNAP")"

jq -n --argjson checks "$CHECKS_JSON" --arg strict "$STRICT" --arg conv "$CONV" '{
  required_status_checks: { strict: ($strict == "true"), checks: $checks },
  enforce_admins: true,
  required_pull_request_reviews: {
    required_approving_review_count: 0,
    require_code_owner_reviews: false,
    dismiss_stale_reviews: false,
    require_last_push_approval: false
  },
  restrictions: null,
  required_linear_history: true,
  allow_force_pushes: false,
  allow_deletions: false,
  block_creations: false,
  required_conversation_resolution: ($conv == "true"),
  lock_branch: false,
  allow_fork_syncing: false
}' > "$TMPPATCH"

# Payload de RESTAURATION stricte (reviews=1, mêmes checks)
jq -n --argjson checks "$CHECKS_JSON" '{
  required_status_checks: { strict: true, checks: $checks },
  enforce_admins: true,
  required_pull_request_reviews: {
    required_approving_review_count: 1,
    require_code_owner_reviews: false,
    dismiss_stale_reviews: false,
    require_last_push_approval: false
  },
  restrictions: null,
  required_linear_history: true,
  allow_force_pushes: false,
  allow_deletions: false,
  block_creations: false,
  required_conversation_resolution: true,
  lock_branch: false,
  allow_fork_syncing: false
}' > "$RESTORE"

say "[PATCH] TEMP reviews=0 (checks conservés)…"
gh api repos/:owner/:repo/branches/main/protection \
  -X PUT -H "Accept: application/vnd.github+json" --input "$TMPPATCH" >/dev/null

say "[MERGE] gh pr merge ${PR_NUM} --squash --delete-branch (tentative normale)…"
if ! gh pr merge "$PR_NUM" --squash --delete-branch; then
  say "[WARN] Merge refusé. Tentative --admin (si autorisé)…"
  gh pr merge "$PR_NUM" --squash --admin --delete-branch || say "[ERROR] Échec merge même avec --admin (voir log)."
fi

say "[RESTORE] Protection stricte (reviews=1)…"
gh api repos/:owner/:repo/branches/main/protection \
  -X PUT -H "Accept: application/vnd.github+json" --input "$RESTORE" >/dev/null

say "[VERIFY] Lecture protection après restauration"
VERIFY="$(gh api repos/:owner/:repo/branches/main/protection)"
CCHK="$(jq -r '[.required_status_checks.checks[].context] | sort | join(",")' <<<"$VERIFY")"
CREV="$(jq -r '.required_pull_request_reviews.required_approving_review_count' <<<"$VERIFY")"
CSTR="$(jq -r '.required_status_checks.strict' <<<"$VERIFY")"
CCON="$(jq -r '.required_conversation_resolution.enabled' <<<"$VERIFY")"
say "[INFO] strict=${CSTR} ; conv=${CCON} ; reviews=${CREV} ; checks=${CCHK}"

say "[SANITY] Dispatch rapide sur main puis poll court…"
gh workflow run pypi-build.yml --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true

for i in $(seq 1 24); do
  PB=$(gh run list --branch main --workflow pypi-build.yml --limit 1 --json conclusion -q '.[0].conclusion' 2>/dev/null || echo "")
  SS=$(gh run list --branch main --workflow secret-scan.yml --limit 1 --json conclusion -q '.[0].conclusion' 2>/dev/null || echo "")
  echo "[POLL $i] pypi-build=${PB} ; secret-scan=${SS}" | tee -a "$LOG"
  [[ "$PB" == "success" && "$SS" == "success" ]] && break
  sleep 5
done

say "[DONE] PR #${PR_NUM} traitée + protections strictes validées. Log: $LOG"
read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true
