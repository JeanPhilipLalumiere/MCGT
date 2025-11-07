#!/usr/bin/env bash
set -euo pipefail

PR_NUM="${PR_NUM:-26}"
REPO_ROOT="$(git rev-parse --show-toplevel)"; cd "$REPO_ROOT"
mkdir -p _logs _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/merge_conv_guard_${PR_NUM}_${TS}.log"

BR="$(gh pr view "$PR_NUM" --json headRefName -q .headRefName)"
[[ "$BR" == "main" ]] && { echo "[ABORT] Refus d'opérer sur main" | tee -a "$LOG"; read -r -p $'ENTER…\n' _ </dev/tty || true; exit 2; }

echo "[INFO] Inspect PR #$PR_NUM (branch=$BR)" | tee -a "$LOG"

# 1) Récupère threads de review et filtre non résolus
JSON="$(gh pr view "$PR_NUM" --json reviewThreads,number,url)"
COUNT="$(echo "$JSON" | jq '[.reviewThreads[] | select(.isResolved==false)] | length')"
echo "[INFO] Unresolved review threads: $COUNT" | tee -a "$LOG"

if [[ "$COUNT" -gt 0 ]]; then
  echo "[LIST] Non-resolved threads:" | tee -a "$LOG"
  echo "$JSON" | jq -r '
    .reviewThreads[]
    | select(.isResolved==false)
    | "- " + (.comments[0].url // .id|tostring) + "  (" + (.comments[0].author.login // "unknown") + ")"
  ' | tee -a "$LOG" || true

  echo
  echo "Options :" | tee -a "$LOG"
  echo " (A) Ouvrir la PR dans le navigateur et résoudre manuellement chaque conversation" | tee -a "$LOG"
  echo " (B) Désactiver TEMPORAIREMENT required_conversation_resolution -> merge -> RESTAURER" | tee -a "$LOG"
  read -r -p $'Choix ? [A/B/abort] ' choice </dev/tty || true
  case "${choice:-abort}" in
    A|a)
      URL="$(echo "$JSON" | jq -r '.url')"
      echo "[HINT] Ouvre et résous tout: $URL" | tee -a "$LOG"
      read -r -p $'Quand tout est résolu, relance ce script. ENTER pour fermer…\n' _ </dev/tty || true
      exit 0
      ;;
    B|b)
      echo "[INFO] Bascule temporaire: disable conversation resolution" | tee -a "$LOG"
      TMP_JSON="_tmp/protect_lower_conv_${TS}.json"
      cat > "$TMP_JSON" <<'JSON'
{
  "enforce_admins": true,
  "required_linear_history": true,
  "required_conversation_resolution": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "restrictions": null,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": false,
    "dismiss_stale_reviews": false,
    "require_last_push_approval": false
  },
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "pypi-build/build" },
      { "context": "secret-scan/gitleaks" }
    ]
  }
}
JSON
      gh api -X PUT repos/:owner/:repo/branches/main/protection -H "Accept: application/vnd.github+json" --input "$TMP_JSON" | tee -a "$LOG"
      ;;
    *)
      echo "[CANCEL] Abandon." | tee -a "$LOG"
      read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true
      exit 0
      ;;
  esac
else
  echo "[OK] Aucun thread non résolu." | tee -a "$LOG"
fi

# 2) Merge (rebase) maintenant que tout est conforme
set +e
gh pr merge "$PR_NUM" --rebase | tee -a "$LOG"
RC=${PIPESTATUS[0]}
set -e

# 3) Si on a désactivé la conversation resolution, restaurer le profil strict
CUR="$(gh api repos/:owner/:repo/branches/main/protection)"
NEED_RESTORE="$(echo "$CUR" | jq -r '.required_conversation_resolution.enabled | not')"
if [[ "$NEED_RESTORE" == "true" ]]; then
  echo "[INFO] Restauration profil strict (conversation resolution = true)" | tee -a "$LOG"
  REST_JSON="_tmp/protect_restore_strict_${TS}.json"
  cat > "$REST_JSON" <<'JSON'
{
  "enforce_admins": true,
  "required_linear_history": true,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "restrictions": null,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": false,
    "dismiss_stale_reviews": false,
    "require_last_push_approval": false
  },
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "pypi-build/build" },
      { "context": "secret-scan/gitleaks" }
    ]
  }
}
JSON
  gh api -X PUT repos/:owner/:repo/branches/main/protection -H "Accept: application/vnd.github+json" --input "$REST_JSON" | tee -a "$LOG"
fi

if [[ $RC -ne 0 ]]; then
  echo "[WARN] Merge refusé (autre cause). Vérifie le message ci-dessus (ex. merge method interdite, conflits, etc.)." | tee -a "$LOG"
else
  echo "[DONE] Merge réussi." | tee -a "$LOG"
fi

read -r -p $'Fin. ENTER pour fermer…\n' _ </dev/tty || true
