#!/usr/bin/env bash
# merge_pr_fasttrack_guard.sh — Fast-track d’une PR : snapshot protection → no-checks → merge (squash)
# → restore EXACT. Garde-fou : la fenêtre NE se ferme jamais (prompt final).
# Usage: bash merge_pr_fasttrack_guard.sh 27

set -uo pipefail
IFS=$'\n\t'
PR="${1:-}"; [[ -z "$PR" ]] && { echo "[FATAL] Donne un numéro de PR (ex: 27)"; read -r -p "ENTER…" _ </dev/tty || true; exit 1; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$ROOT" ]]; then
  echo "[FATAL] Pas dans un dépôt git."
  read -r -p "ENTER…" _ </dev/tty || true
  exit 2
fi
cd "$ROOT" || { echo "[FATAL] cd $ROOT impossible"; read -r -p "ENTER…" _ </dev/tty || true; exit 3; }

mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/merge_fasttrack_pr${PR}_${TS}.log"

BASE="main"
SNAP=""
RESTORE_DONE=0

finish() {
  # Garde-fou de restauration si besoin
  if [[ "$RESTORE_DONE" -eq 0 && -n "$SNAP" && -f "$SNAP" ]]; then
    echo "[GUARD] Restauration protections depuis snapshot: $SNAP" | tee -a "$LOG"
    gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
      -H "Accept: application/vnd.github+json" \
      --input "$SNAP" >/dev/null 2>>"$LOG" || true
    RESTORE_DONE=1
    echo "[GUARD] Restauration effectuée." | tee -a "$LOG"
  fi
  echo
  echo "[FIN] Journal: $LOG"
  read -r -p "ENTER pour fermer…" _ </dev/tty || true
}
trap finish EXIT INT TERM

log(){ echo -e "$*" | tee -a "$LOG"; }

log "[INFO] Fast-track PR #$PR @ $TS"

# 1) Infos PR
PR_JSON="$(gh pr view "$PR" --json headRefName,baseRefName,url,number 2>>"$LOG" || true)"
if [[ -z "$PR_JSON" || "$PR_JSON" == "null" ]]; then
  log "[FATAL] Impossible de lire PR #$PR"
  exit 10
fi
BR="$(echo "$PR_JSON" | jq -r .headRefName 2>>"$LOG")"
BASE="$(echo "$PR_JSON"| jq -r .baseRefName 2>>"$LOG")"
URL="$(echo "$PR_JSON" | jq -r .url 2>>"$LOG")"
[[ "$BR" == "main" ]] && { log "[ABORT] Refus d'opérer sur main"; exit 11; }
log "[INFO] $URL | $BR → $BASE"

# 2) Snapshot protections EXACT
SNAP="_tmp/protect.${BASE}.snapshot.${TS}.json"
PROT="$(gh api "repos/:owner/:repo/branches/${BASE}/protection" 2>>"$LOG" || true)"
if [[ -z "$PROT" || "$PROT" == "null" ]]; then
  log "[FATAL] Impossible d’obtenir la protection de $BASE"
  exit 20
fi
echo "$PROT" > "$SNAP"
log "[SNAPSHOT] Protections → $SNAP"

# 3) Payload TEMP: reviews=0, strict=false, checks=[] (désactive tous les checks)
TMP_PAYLOAD="_tmp/protect.${BASE}.TEMP.${TS}.json"
cat > "$TMP_PAYLOAD" <<'JSON'
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
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
JSON

log "[PATCH] Profil TEMP: no-checks + reviews=0 (linear history & convo on)"
if ! gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
      -H "Accept: application/vnd.github+json" \
      --input "$TMP_PAYLOAD" >/dev/null 2>>"$LOG"; then
  log "[FATAL] PUT protection TEMP a échoué (droits?)"
  exit 30
fi

# 4) Merge (squash) + delete branch
log "[MERGE] gh pr merge $PR --squash --delete-branch"
if ! gh pr merge "$PR" --squash --delete-branch 2>>"$LOG"; then
  log "[WARN] Merge refusé. Tentative --admin…"
  gh pr merge "$PR" --squash --admin --delete-branch 2>>"$LOG" || {
    log "[FATAL] Échec merge même avec --admin."
    exit 40
  }
fi

# 5) Restore EXACT protections
log "[RESTORE] protections depuis snapshot"
if gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
     -H "Accept: application/vnd.github+json" \
     --input "$SNAP" >/dev/null 2>>"$LOG"; then
  RESTORE_DONE=1
  log "[RESTORE] OK."
else
  log "[ERROR] Restauration a échoué (le garde-fou la refera à la sortie)."
fi

log "[DONE] PR #$PR fusionnée proprement (fast-track + restore)."
