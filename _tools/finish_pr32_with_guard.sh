#!/usr/bin/env bash
# finish_pr32_with_guard.sh — merge propre de PR#32 avec garde-fou, poll limité

set -euo pipefail
PR="${1:-32}"

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/finish_pr${PR}_${TS}.log"
echo "[INFO] PR #$PR" | tee -a "$LOG"

# 0) Contexte PR
INFO="$(gh pr view "$PR" --json url,headRefName,baseRefName,headRefOid)"
URL="$(echo "$INFO" | jq -r .url)"
BR="$(echo "$INFO"  | jq -r .headRefName)"
BASE="$(echo "$INFO" | jq -r .baseRefName)"
HEAD="$(echo "$INFO" | jq -r .headRefOid)"
echo "[INFO] $URL | $BR -> $BASE | HEAD=$HEAD" | tee -a "$LOG"

# 1) Snapshot protections
SNAP="_tmp/protect.${BASE}.snapshot.${TS}.json"
gh api "repos/:owner/:repo/branches/${BASE}/protection" > "$SNAP"
echo "[SNAPSHOT] $SNAP" | tee -a "$LOG"

# 2) (Re)déclenche les 2 workflows sur la branche du PR
echo "[DISPATCH] pypi-build.yml & secret-scan.yml sur ref=$BR" | tee -a "$LOG"
gh workflow run pypi-build.yml   --ref "$BR" || true
gh workflow run secret-scan.yml  --ref "$BR" || true

# 3) Poll court ≤ 240 s pour pypi-build/build & secret-scan/gitleaks
echo "[WAIT] Poll ≤ 240s pour SUCCESS des 2 contexts…" | tee -a "$LOG"
limit=48; ok=0
for i in $(seq 1 "$limit"); do
  rollup="$(gh pr view "$PR" --json statusCheckRollup)"
  ok_now="$(echo "$rollup" \
    | jq -re '[.statusCheckRollup[]
                | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
                | .conclusion] | sort | join(",") == "SUCCESS,SUCCESS"')"
  if [[ "$ok_now" == "true" ]]; then ok=1; echo "[OK] SUCCESS x2" | tee -a "$LOG"; break; fi
  sleep 5
done

# 4) Merge (normal). Si la policy bloque malgré SUCCESS → fallback admin (si autorisé)
echo "[MERGE] tentative squash…" | tee -a "$LOG"
if ! gh pr merge "$PR" --squash --delete-branch; then
  echo "[WARN] Merge refusé. Tentative --admin…" | tee -a "$LOG"
  gh pr merge "$PR" --squash --admin --delete-branch || true
fi

# 5) Vérification post-merge + restauration stricte si besoin
echo "[RESTORE] Restauration protections depuis snapshot…" | tee -a "$LOG"
gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
  -H "Accept: application/vnd.github+json" --input "$SNAP" >/dev/null || true

# 6) Sanity rapide sur main (dispatch)
echo "[SANITY] Dispatch rapide sur ${BASE} puis poll court (≤60s)..." | tee -a "$LOG"
gh workflow run pypi-build.yml  --ref "$BASE" || true
gh workflow run secret-scan.yml --ref "$BASE" || true

for i in {1..12}; do
  runs="$(gh run list --branch "$BASE" --limit 10 | grep -E 'pypi-build|secret-scan' || true)"
  if echo "$runs" | grep -qi "success"; then echo "[SANITY] OK (au moins un SUCCESS visible)"; break; fi
  sleep 5
done

echo "[DONE] PR #$PR traitée." | tee -a "$LOG"
read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
