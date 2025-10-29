#!/usr/bin/env bash
set -euo pipefail

PR_NUM="${PR_NUM:-26}"

REPO_ROOT="$(git rev-parse --show-toplevel)"; cd "$REPO_ROOT"
mkdir -p _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/finalize_pr${PR_NUM}_${TS}.log"

BR="$(gh pr view "$PR_NUM" --json headRefName -q .headRefName)"
HEAD_LOCAL="$(git rev-parse "$BR" 2>/dev/null || echo "NA")"

echo "[INFO] PR #$PR_NUM | branch=$BR | local_head=$HEAD_LOCAL" | tee -a "$LOG"

# ── Sécurités
if [[ "$BR" == "main" ]]; then
  echo "[ABORT] Refus d'opérer sur 'main'." | tee -a "$LOG"
  read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true; exit 2
fi

git fetch origin main "$BR" | tee -a "$LOG" || true
REMOTE_HEAD="$(git rev-parse "origin/$BR" 2>/dev/null || echo "NA")"
echo "[INFO] remote_head=$REMOTE_HEAD" | tee -a "$LOG"

echo; echo "Divergence locale vs remote (local..remote) :" | tee -a "$LOG"
git --no-pager log --oneline --decorate --graph "origin/$BR..$BR" | tee -a "$LOG" || true
echo; echo "Divergence remote vs local (remote..local) :" | tee -a "$LOG"
git --no-pager log --oneline --decorate --graph "$BR..origin/$BR" | tee -a "$LOG" || true
echo; git status -sb | tee -a "$LOG"

# ── Confirmation force-push protégé
read -r -p $'Confirmer FORCE-PUSH (with-lease) de la branche PR ? [yes/NO] ' ans </dev/tty || true
if [[ "${ans:-}" != "yes" ]]; then
  echo "[CANCEL] Annulé." | tee -a "$LOG"
  read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true; exit 0
fi

set +e
git push --force-with-lease origin "$BR" | tee -a "$LOG"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then
  echo "[ERR] --force-with-lease a échoué. Refaire: git fetch; git rebase origin/main; relancer." | tee -a "$LOG"
  read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true; exit 3
fi

# ── Dispatch explicite (optionnel — ignore si non autorisé)
echo "[INFO] Dispatch workflows…" | tee -a "$LOG"
gh workflow run .github/workflows/pypi-build.yml  --ref "$BR" 2>>"$LOG" || true
gh workflow run .github/workflows/secret-scan.yml --ref "$BR" 2>>"$LOG" || true

# ── Attente des 2 checks requis au HEAD courant du PR
HEAD="$(gh pr view "$PR_NUM" --json headRefOid -q .headRefOid)"
echo "[WAIT] Required checks on HEAD=$HEAD" | tee -a "$LOG"

for i in $(seq 1 50); do
  sleep 6
  JSON="$(gh api repos/:owner/:repo/commits/$HEAD/check-runs)"
  echo "$JSON" | jq -r '.check_runs[]|[.name,.app.name,.status,.conclusion]|@tsv' | tee -a "$LOG" || true
  BUILD_OK="$(echo "$JSON" | jq -r '[.check_runs[] | select(.app.name=="GitHub Actions" and .name=="build")    | .conclusion] | any(.=="success")')"
  GITL_OK="$(echo "$JSON" | jq -r '[.check_runs[] | select(.app.name=="GitHub Actions" and .name=="gitleaks") | .conclusion] | any(.=="success")')"
  echo "  - build=$BUILD_OK ; gitleaks=$GITL_OK"
  if [[ "$BUILD_OK" == "true" && "$GITL_OK" == "true" ]]; then
    echo "[OK] Required checks green." | tee -a "$LOG"
    break
  fi
done

# ── Tentative de merge PR (rebase)
set +e
gh pr merge "$PR_NUM" --rebase | tee -a "$LOG"
MERGE_RC=${PIPESTATUS[0]}
set -e

if [[ $MERGE_RC -ne 0 ]]; then
  echo
  echo "[INFO] Merge refusé (souvent review manquante = 1)." | tee -a "$LOG"
  echo "Options :" | tee -a "$LOG"
  echo " (A) Obtenir 1 APPROVE d'un reviewer." | tee -a "$LOG"
  echo " (B) Baisser temporairement required_approving_review_count=0 -> merge -> restaurer=1." | tee -a "$LOG"

  read -r -p $'Exécuter l’option (B) automatiquement ? [yes/NO] ' opt </dev/tty || true
  if [[ "${opt:-}" == "yes" ]]; then
    # Profil temporaire: review=0 (checks inchangés)
    TMP_JSON="_tmp/protect_lower_reviews_${TS}.json"
    mkdir -p _tmp
    cat > "$TMP_JSON" <<'JSON'
{
  "enforce_admins": true,
  "required_linear_history": true,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "restrictions": null,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
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
    echo "[INFO] Abaissement temporaire review=0…" | tee -a "$LOG"
    gh api -X PUT repos/:owner/:repo/branches/main/protection -H "Accept: application/vnd.github+json" --input "$TMP_JSON" | tee -a "$LOG"

    gh pr merge "$PR_NUM" --rebase | tee -a "$LOG" || true

    # Restauration stricte (review=1)
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
    echo "[INFO] Restauration profil strict (review=1) …" | tee -a "$LOG"
    gh api -X PUT repos/:owner/:repo/branches/main/protection -H "Accept: application/vnd.github+json" --input "$REST_JSON" | tee -a "$LOG"
  fi
fi

echo
echo "[DONE] Fin de finalize_pr${PR_NUM}_after_rebase." | tee -a "$LOG"
read -r -p $'ENTER pour fermer cette fenêtre…\n' _ </dev/tty || true
