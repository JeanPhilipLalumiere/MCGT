# tools/unblock_and_arm_automerge_safe.sh
#!/usr/bin/env bash
# NE FERME PAS LA FENÊTRE — remet la PR à jour avec main, relance les requis, arme l’auto-merge
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

PR="${1:-20}"
BASE="${2:-main}"

# 1) Récupère le nom de branche de la PR
HEAD_REF="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)"
if [ -z "${HEAD_REF:-}" ]; then err "Impossible d’obtenir la branche de la PR #$PR"; exit 0; fi
info "PR #$PR → headRef=$HEAD_REF • base=$BASE"

# 2) Rebase/merge main dans la branche PR (no-op possible)
git fetch origin >/dev/null 2>&1
git switch "$HEAD_REF" || { err "git switch $HEAD_REF a échoué"; exit 0; }

# Essayez d’abord un rebase (souvent mieux avec `Require linear history`)
if git rebase "origin/$BASE"; then
  ok "Rebase sur origin/$BASE OK"
else
  warn "Rebase non applicable, tentative de merge fast-forward"
  git rebase --abort >/dev/null 2>&1 || true
  if git merge --no-edit "origin/$BASE"; then
    ok "Merge de origin/$BASE OK"
  else
    warn "Merge sans changement probable (Already up to date)."
  fi
fi

# 3) Si aucun changement n’a été poussé (no-op), force un empty commit pour déclencher les checks
NEED_PUSH="$(git status --porcelain | wc -l | tr -d ' ')"
if [ "${NEED_PUSH:-0}" = "0" ]; then
  warn "Aucun diff détecté après sync base → je crée un empty commit pour rafraîchir les checks."
  git commit --allow-empty -m "ci: refresh required checks on up-to-date base $(date -u +%Y%m%dT%H%M%SZ)" || true
fi

git push || warn "Push sans changement (ok si déjà synchro)."

# 4) Relance ciblée des 2 workflows requis si dispatch disponible
# (tu as ajouté workflow_dispatch à pypi-build; secret-scan l’a déjà)
gh workflow run .github/workflows/pypi-build.yml  -r "$HEAD_REF" >/dev/null 2>&1 || warn "dispatch pypi-build indisponible"
gh workflow run .github/workflows/secret-scan.yml -r "$HEAD_REF" >/dev/null 2>&1 || warn "dispatch secret-scan indisponible"
ok "Relances envoyées (si présentes)."

# 5) Arme l’auto-merge (rebase). GitHub fusionnera dès que les 2 requis sont verts.
if gh pr merge "$PR" --rebase --auto >/dev/null 2>&1; then
  ok "Auto-merge armé (rebase). La PR sera mergée dès que pypi-build & gitleaks seront verts."
else
  warn "Impossible d’armer l’auto-merge via CLI (droits/paramètres). Tu peux cliquer 'Enable auto-merge' dans l’UI."
fi

# 6) Affiche l’état de protection (informative)
gh api -H 'Accept: application/vnd.github+json' \
  "/repos/$(git remote get-url origin | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')/branches/$BASE/protection" \
  | jq -C '{strict: .required_status_checks.strict, required: [.required_status_checks.checks[]?.context]}' 2>/dev/null || true

ok "Terminé. Suis les runs dans l’onglet Actions / Checks de la PR."
