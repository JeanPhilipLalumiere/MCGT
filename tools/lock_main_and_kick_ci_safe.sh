# tools/lock_main_and_kick_ci_safe.sh
#!/usr/bin/env bash
# Durcit main (best-effort) + relance CI + propose ménage branches + gère le stash.
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail(){ printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; }

OUT="_tmp/hardening_now"; mkdir -p "$OUT"

REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#' )"
BR_PROT="${1:-main}"

[ -z "$REPO" ] && fail "Impossible de détecter le repo GitHub (origin)"; REPO="${REPO:-UNKNOWN}"

info "Repo=$REPO • Branch protégée=$BR_PROT"

# 1) Lire protection actuelle (best-effort)
gh api -H 'Accept: application/vnd.github+json' "/repos/$REPO/branches/$BR_PROT/protection" \
  > "$OUT/protection_get.json" 2>/dev/null \
  && ok "Protection actuelle exportée: $OUT/protection_get.json" \
  || warn "Lecture protection via API impossible (permissions ?)."

# 2) Payload de protection (exige PR, requiert contexts *namespacés*, interdit push direct)
cat > "$OUT/branch_protection_payload.json" <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      {"context": "pypi-build/build"},
      {"context": "secret-scan/gitleaks"}
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0,
    "require_last_push_approval": false,
    "dismiss_stale_reviews": false
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

info "Application de la protection durcie (PUT)…"
if gh api -X PUT -H 'Accept: application/vnd.github+json' \
      "/repos/$REPO/branches/$BR_PROT/protection" \
      --input "$OUT/branch_protection_payload.json" >/dev/null 2>&1; then
  ok "Protection mise à jour (contexts = pypi-build/build, secret-scan/gitleaks; PR obligatoire; admins inclus)."
else
  warn "PUT protection a échoué (token ?). Procède via l'UI:
  • Settings → Branches → main → Edit
    - Require a pull request before merging : ✅
    - Require linear history               : ✅
    - Require conversation resolution      : ✅
    - Require status checks to pass…       : coche EXACTEMENT:
         ▸ pypi-build/build
         ▸ secret-scan/gitleaks
    - Include administrators               : ✅"
fi

# 3) Relancer CI sur main (best-effort)
CUR_BR="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
if [ "$CUR_BR" != "$BR_PROT" ]; then
  git fetch origin >/dev/null 2>&1 || true
  git checkout "$BR_PROT" >/dev/null 2>&1 || warn "checkout $BR_PROT non effectué (je continue)"
fi

# Dispatch best-effort si les fichiers existent
kick(){
  local wf="$1"
  [ -f ".github/workflows/$wf" ] || return 1
  gh workflow run ".github/workflows/$wf" -r "$BR_PROT" >/dev/null 2>&1 \
    && ok "Dispatch → $wf@$BR_PROT" \
    || warn "Dispatch KO → $wf (je continue)"
}
info "Relance CI (best-effort) sur $BR_PROT…"
kick build-publish.yml
kick ci-accel.yml
kick secret-scan.yml
kick pip-audit.yml

# 4) Stash: pointer vers diff et commandes utiles
if git stash list | grep -q 'post-merge safety'; then
  ST="$(git stash list | grep 'post-merge safety' | head -n1 | cut -d: -f1)"
  if [ -n "$ST" ] && git show "$ST":"MANIFEST.in" > "$OUT/stash_MANIFEST.in" 2>/dev/null; then
    cp -f MANIFEST.in "$OUT/main_MANIFEST.in" 2>/dev/null || true
    diff -u "$OUT/main_MANIFEST.in" "$OUT/stash_MANIFEST.in" > "$OUT/manifest.diff" 2>/dev/null || true
    info "Diff MANIFEST.in: $OUT/manifest.diff"
    printf '\nSuggestion:\n  • Garder version main  : rien à faire\n  • Ou réappliquer stash : git checkout "%s" -- MANIFEST.in && git commit -m "chore(manifest): apply post-merge tuned rules"\n  • Vider stash ensuite  : git stash drop "%s"\n' "$ST" "$ST"
  else
    warn "Stash présent mais pas de MANIFEST.in à comparer."
  fi
else
  ok "Pas de stash ‘post-merge safety’ détecté."
fi

# 5) Nettoyage des branches rewrite/* mergées (local + remote) — best-effort
info "Nettoyage branches rewrite/* mergées (best-effort)…"
git fetch -p origin >/dev/null 2>&1 || true
# local
for BR in $(git branch --merged 2>/dev/null | sed 's/^..//' | grep '^rewrite/' || true); do
  git branch -d "$BR" >/dev/null 2>&1 && ok "Branche locale supprimée: $BR" || true
done
# remote
for RBR in $(git branch -r --merged 2>/dev/null | sed 's/^..//' | grep '^origin/rewrite/' || true); do
  RB="${RBR#origin/}"
  git push origin --delete "$RB" >/dev/null 2>&1 \
    && ok "Branche distante supprimée: $RB" \
    || warn "Suppression distante ignorée: $RB (droits ?)"
done

ok "Durcissement + relance CI: terminé (fenêtre laissée OUVERTE)."
