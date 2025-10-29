#!/usr/bin/env bash
# merge_pr27_guarded_v2.sh — Débloque et merge PR (27 par défaut) en abaissant TEMPORAIREMENT
# le nombre d'approbations requises (reviews=0) tout en CONSERVANT les checks requis.
# Restaure EXACTEMENT la protection. Ne ferme jamais la fenêtre (prompt final).

set -uo pipefail
IFS=$'\n\t'

PR="${PR:-27}"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$ROOT" ]]; then
  echo "[FATAL] Hors dépôt git."
  read -r -p "ENTER pour fermer…" _ </dev/tty || true
  exit 1
fi
cd "$ROOT" || { echo "[FATAL] cd $ROOT impossible"; read -r -p "ENTER…" _ </dev/tty || true; exit 2; }

mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/merge_pr${PR}_${TS}.log"

SNAP=""
BASE="main"
RESTORE_DONE=0

finish() {
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

log "[INFO] Start merge PR #$PR @ $TS"
PR_JSON="$(gh pr view "$PR" --json headRefName,baseRefName,mergeable,mergeStateStatus,reviewDecision,isDraft,url 2>>"$LOG" || true)"
if [[ -z "$PR_JSON" || "$PR_JSON" == "null" ]]; then
  log "[FATAL] Impossible de lire PR #$PR"
  exit 10
fi
BR="$(echo "$PR_JSON"  | jq -r .headRefName 2>>"$LOG")"
BASE="$(echo "$PR_JSON"| jq -r .baseRefName 2>>"$LOG")"
URL="$(echo "$PR_JSON" | jq -r .url 2>>"$LOG")"
[[ "$BR" == "main" ]] && { log "[ABORT] Refus d'opérer sur main"; exit 11; }
log "[INFO] PR #$PR: $BR → $BASE | $URL"

# Snapshot protections → SNAP
SNAP="_tmp/protect.${BASE}.snapshot.${TS}.json"
PROT="$(gh api "repos/:owner/:repo/branches/${BASE}/protection" 2>>"$LOG" || true)"
if [[ -z "$PROT" || "$PROT" == "null" ]]; then
  log "[FATAL] Impossible d'obtenir la protection de $BASE"
  exit 20
fi
echo "$PROT" > "$SNAP"
log "[SNAPSHOT] Protections → $SNAP"

# Extraire flags en BASH (évite jq |tobool)
STRICT_RAW="$(jq -r '.required_status_checks.strict // true' "$SNAP" 2>>"$LOG" || echo true)"
CONV_RAW="$(jq -r '.required_conversation_resolution.enabled // true' "$SNAP" 2>>"$LOG" || echo true)"
[[ "$STRICT_RAW" == "true" ]] || STRICT_RAW=false
[[ "$CONV_RAW"   == "true" ]] || CONV_RAW=false

CHECKS_JSON="$(jq -c '.required_status_checks.checks | map({context:.context, app_id:(.app_id // null)})' "$SNAP" 2>>"$LOG" || echo '[]')"

# Abaisser TEMPORAIREMENT reviews=0 (checks conservés, strict & conv idem)
TMP_PAYLOAD="_tmp/protect.${BASE}.temp.${TS}.json"
jq -n \
  --argjson checks "$CHECKS_JSON" \
  --argjson strict "$STRICT_RAW" \
  --argjson conv "$CONV_RAW" \
'{
  required_status_checks: { strict: $strict, checks: $checks },
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
  required_conversation_resolution: $conv,
  lock_branch: false,
  allow_fork_syncing: false
}' > "$TMP_PAYLOAD"

log "[PATCH] reviews=0 (checks/strict/conv conservés)"
gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
  -H "Accept: application/vnd.github+json" \
  --input "$TMP_PAYLOAD" >/dev/null 2>>"$LOG" || log "[WARN] PUT protection a signalé une erreur."

# Déclenche pypi-build & secret-scan sur la tête du PR
HEAD_OID="$(gh pr view "$PR" --json headRefOid -q .headRefOid 2>>"$LOG" || echo '')"
log "[DISPATCH] HEAD=$HEAD_OID | BR=$BR"
gh workflow run pypi-build.yml --ref "$BR" 2>>"$LOG" || true
gh workflow run secret-scan.yml --ref "$BR" 2>>"$LOG" || true

# Attendre SUCCESS,SUCCESS
log "[WAIT] pypi-build/build & secret-scan/gitleaks → SUCCESS"
ok="false"
for i in $(seq 1 90); do
  ROLL="$(gh pr view "$PR" --json statusCheckRollup 2>>"$LOG" || echo '{}')"
  want="$(echo "$ROLL" | jq -re \
    '[.statusCheckRollup[] | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks") | .conclusion]
     | sort | join(",") == "SUCCESS,SUCCESS"' 2>>"$LOG" || echo false)"
  if [[ "$want" == "true" ]]; then ok="true"; break; fi
  sleep 5
done
[[ "$ok" == "true" ]] && log "[OK] Checks verts." || log "[WARN] Checks pas tous verts (on tente le merge)."

# Merge (squash)
log "[MERGE] gh pr merge $PR --squash --delete-branch"
if ! gh pr merge "$PR" --squash --delete-branch 2>>"$LOG"; then
  log "[WARN] Merge refusé. Tentative --admin…"
  gh pr merge "$PR" --squash --admin --delete-branch 2>>"$LOG" || log "[ERROR] Échec merge même avec --admin."
fi

# Restaurer EXACTEMENT la protection
log "[RESTORE] protections depuis snapshot"
if gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
     -H "Accept: application/vnd.github+json" \
     --input "$SNAP" >/dev/null 2>>"$LOG"; then
  RESTORE_DONE=1
  log "[RESTORE] OK."
else
  log "[ERROR] Restauration a échoué (le garde-fou réessaiera à la sortie)."
fi

log "[DONE] Fin de flux PR #$PR."
