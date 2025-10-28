# tools/why_merge_blocked_safe.sh
#!/usr/bin/env bash
# NE FERME PAS LA FENÊTRE — Diagnostique précisément ce qui empêche le merge d’une PR
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

PR="${1:-20}"
BASE="${2:-main}"
REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"

printf '\n\033[1m== WHY MERGE BLOCKED (NEVER-FAIL) ==\033[0m\n'
info "Repo=${REPO:-UNKNOWN} • Base=${BASE} • PR=#${PR}"

if ! command -v gh >/dev/null 2>&1; then
  err "gh introuvable — installe GitHub CLI pour un diagnostic précis."
  exit 0
fi

# 1) État PR
pr_json="$(gh pr view "$PR" --json \
  number,title,isDraft,mergeable,mergeStateStatus,reviewDecision,maintainerCanModify,headRefName,baseRefName,commits,updatedAt \
  2>/dev/null)" || pr_json=""
echo "$pr_json" | jq -C . || true

is_draft="$(echo "$pr_json" | jq -r '.isDraft // false')"
mergeable="$(echo "$pr_json" | jq -r '.mergeable // "UNKNOWN"')"
merge_state="$(echo "$pr_json" | jq -r '.mergeStateStatus // "UNKNOWN"')"
review_dec="$(echo "$pr_json" | jq -r '.reviewDecision // "UNKNOWN"')"
head_ref="$(echo "$pr_json" | jq -r '.headRefName // ""')"

echo
info "Synthèse PR:"
echo "  • Draft?              : $is_draft"
echo "  • mergeable           : $mergeable (GitHub calcule ça côté serveur)"
echo "  • mergeStateStatus    : $merge_state (BLOCKED/BEHIND/UNKNOWN/…)"
echo "  • reviewDecision      : $review_dec (APPROVED/CHANGES_REQUESTED/REVIEW_REQUIRED)"
echo "  • headRef             : $head_ref"
echo

# 2) Protection de branche
prot_json="$(gh api -H 'Accept: application/vnd.github+json' "/repos/$REPO/branches/$BASE/protection" 2>/dev/null)" || prot_json=""
if [ -z "$prot_json" ]; then
  warn "Protection introuvable (token/permissions)."
else
  echo "$prot_json" | jq -C '{
    required_status_checks: {
      strict: .required_status_checks.strict,
      contexts: (.required_status_checks.checks[]?.context // empty)
    },
    required_pull_request_reviews: {
      required_approving_review_count,
      require_code_owner_reviews,
      require_last_push_approval,
      dismiss_stale_reviews,
      require_review_thread_resolution
    },
    restrictions: .restrictions
  }' || true

  strict="$(echo "$prot_json" | jq -r '.required_status_checks.strict // false')"
  need_reviews="$(echo "$prot_json" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')"
  code_owners="$(echo "$prot_json" | jq -r '.required_pull_request_reviews.require_code_owner_reviews // false')"
  need_threads_resolved="$(echo "$prot_json" | jq -r '.required_pull_request_reviews.require_review_thread_resolution // false')"
  need_last_push_approval="$(echo "$prot_json" | jq -r '.required_pull_request_reviews.require_last_push_approval // false')"
  echo
  info "Exigences détectées:"
  echo "  • Require up-to-date (strict)         : $strict"
  echo "  • Required approving reviews          : $need_reviews"
  echo "  • Code owner reviews                  : $code_owners"
  echo "  • All review threads resolved         : $need_threads_resolved"
  echo "  • Last-push approval required         : $need_last_push_approval"
fi
echo

# 3) Checks requis vs PR (déjà vérifiés plus tôt) — informatif
req_ctx="$(echo "$prot_json" | jq -r '.required_status_checks.checks[]?.context' 2>/dev/null)"
if [ -n "$req_ctx" ]; then
  info "Contexts requis:"
  echo "$req_ctx" | sed 's/^/  - /'
fi
echo

# 4) Conseils actionnables selon les flags
echo "──────────────── ACTIONS PROPOSÉES ────────────────"
# Draft
if [ "$is_draft" = "true" ]; then
  warn "PR en mode Draft → enlève le brouillon."
  echo "  gh pr ready $PR"
fi
# Up-to-date
if [ "${strict:-false}" = "true" ] || echo "$merge_state" | grep -qi 'behind'; then
  warn "Branche PR possiblement en RETARD vs $BASE (Require up-to-date)."
  echo "  # Option GitHub:"
  echo "  gh pr update-branch $PR --merge    # ou --rebase si tu préfères"
  echo "  # Option Git classique:"
  echo "  git switch \"$head_ref\" && git fetch origin && git merge origin/$BASE && git push"
fi
# Reviews
if [ "${need_reviews:-0}" != "0" ] || echo "$review_dec" | grep -qi 'REVIEW_REQUIRED'; then
  warn "Approbations requises non satisfaites."
  echo "  # Demander/faire une review (selon ta politique):"
  echo "  gh pr reviewers add $PR --reviewer <user1>,<user2>"
  echo "  gh pr review $PR --approve   # si auto-approbation autorisée"
fi
# Code owners
if [ "$code_owners" = "true" ]; then
  warn "Code owner reviews requis → assure-toi que les CODEOWNERS ont approuvé."
  echo "  # Demande explicite aux code owners listés dans .github/CODEOWNERS"
fi
# Threads
if [ "$need_threads_resolved" = "true" ]; then
  warn "Conversations de review doivent être résolues."
  echo "  # Va dans l’onglet Conversations de la PR et clique 'Resolve conversation'."
fi
# Last push approval
if [ "$need_last_push_approval" = "true" ]; then
  warn "Dernier push requiert une approbation d’un reviewer éligible."
  echo "  gh pr review $PR --approve"
fi

echo
ok "Diagnostic terminé — lis les WARN ci-dessus et applique les commandes correspondantes."
