#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — Débloque PR #20 (titre CC, add workflow_dispatch, relances, update-branch)
set -u -o pipefail; set +e

PR="${1:-20}"
BASE="${2:-main}"
BR_PR="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)"
[ -z "${BR_PR:-}" ] && { echo "[ERR ] Impossible d’obtenir la branche PR"; exit 0; }

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

info "PR #$PR → branche = $BR_PR • base=$BASE"

# 0) Se placer sur la branche PR
git switch "$BR_PR" >/dev/null 2>&1 || git checkout "$BR_PR"

# 1) Fix titre PR → Conventional Commits (contourne semantic-pr rouge)
NEW_TITLE="fix(deps): raise floors for requests and jupyterlab"
if ! gh api -X PATCH "repos/:owner/:repo/pulls/$PR" -f "title=$NEW_TITLE" >/dev/null 2>&1; then
  warn "PATCH titre via API a échoué (droits ?). Titre actuel conservé."
else
  ok "Titre PR mis à: $NEW_TITLE"
fi

# 2) Ajouter workflow_dispatch aux guards PR manquants
#    (pypi-build.yml est déjà patché, secret-scan.yml l’a aussi ; on traite les guards)
add_dispatch_if_missing(){
  local file="$1"
  [ ! -f "$file" ] && return 0
  if grep -qE '^\s*workflow_dispatch\s*:' "$file"; then
    info "$file : workflow_dispatch déjà présent"
  else
    awk '1; /^on:/{print "  workflow_dispatch:"}' "$file" > "_tmp/.wf.$$" && mv "_tmp/.wf.$$" "$file"
    git add "$file"
    ok "$file : workflow_dispatch ajouté"
  fi
}

mkdir -p _tmp

add_dispatch_if_missing ".github/workflows/readme-guard.yml"
add_dispatch_if_missing ".github/workflows/manifest-guard.yml"
add_dispatch_if_missing ".github/workflows/guard-ignore-and-sdist.yml"

if git diff --cached --quiet; then
  info "Aucun changement de workflows à committer"
else
  git commit -m "ci(pr-guards): add workflow_dispatch to allow manual reruns on PR" || true
  git push || true
  ok "Workflows guards poussés sur $BR_PR"
fi

# 3) Relancer jobs requis & guards sur la branche PR (si dispatch présent)
relance(){
  local wf="$1"
  if gh workflow view "$wf" >/dev/null 2>&1; then
    gh workflow run "$wf" -r "$BR_PR" >/dev/null 2>&1 && ok "dispatch $wf@$BR_PR" || warn "dispatch $wf a échoué"
  else
    warn "$wf introuvable"
  fi
}
relance ".github/workflows/pypi-build.yml"
relance ".github/workflows/secret-scan.yml"
relance ".github/workflows/readme-guard.yml"
relance ".github/workflows/manifest-guard.yml"
relance ".github/workflows/guard-ignore-and-sdist.yml"

# 4) Satisfaire "Require up-to-date" via l’API update-branch (équiv. bouton UI)
#    Voir: PUT /repos/{owner}/{repo}/pulls/{pull_number}/update-branch
#    L’en-tête preview n’est plus requis sur la v3 récente, on tente standard.
if gh api -X PUT "repos/:owner/:repo/pulls/$PR/update-branch" >/dev/null 2>"_tmp/update_branch.err"; then
  ok "update-branch déclenché côté serveur"
else
  warn "update-branch via API a échoué (droits ?). Essaie le bouton 'Update branch' dans l’UI."
fi

# 5) Afficher l’état synthétique
echo
info "Statut requis sur '$BASE' :"
gh api "repos/:owner/:repo/branches/$BASE/protection" -H "Accept: application/vnd.github+json" | jq -r '.required_status_checks.strict as $s | "  • strict=\($s)\n" + ( .required_status_checks.checks[]?.context // "" )' | sed 's/^/  /'

echo
info "Ouvre l’onglet Checks de la PR #$PR. Quand ces 2 requis sont VERTS :"
echo "  gh pr merge $PR --rebase --delete-branch"
echo
ok "Terminé — cette fenêtre RESTE OUVERTE."
