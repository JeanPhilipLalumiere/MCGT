# tools/close_security_pins_pr_safe.sh
#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — merge la PR de sécurité si les checks requis sont verts,
# sinon affiche l’état et relance ce qu’il faut.

set -u -o pipefail; set +e
info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

BASE="${1:-main}"
REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"

printf '\n\033[1m== CLOSE SECURITY-PINS PR (NEVER-FAIL) ==\033[0m\n'
info "Repo=${REPO:-UNKNOWN} • Base=$BASE"

if ! command -v gh >/dev/null 2>&1; then
  err "gh non disponible. Ouvre la PR dans l’UI et merge en rebase."
  exit 0
fi

# 1) Trouver la PR ouverte avec un titre de sécurité ou la branche fix/security-pins-*
PR_LINE="$(gh pr list --base "$BASE" --state open --limit 20 2>/dev/null | \
           grep -E 'security-pins|raise floors|sec\(deps\)|fix/security-pins' | head -n1)"
if [ -z "$PR_LINE" ]; then
  warn "Aucune PR de sécurité détectée (security-pins). Liste brute :"
  gh pr list --base "$BASE" --state open || true
  exit 0
fi
PR_NUM="$(awk '{print $1}' <<<"$PR_LINE" | tr -d '#')"
TITLE="$(cut -f3- <<<"$PR_LINE")"
ok "PR détectée: #$PR_NUM — $TITLE"

# 2) Lire les contexts requis actuels sur la branche protégée
REQ_CTX="$(gh api -H 'Accept: application/vnd.github+json' \
  "/repos/$REPO/branches/$BASE/protection" -q '.required_status_checks.checks[].context' 2>/dev/null | sed '/^null$/d')"
if [ -z "$REQ_CTX" ]; then
  warn "Impossible de lire les checks requis (permissions ?). Je continue en best-effort."
fi
info "Checks requis (base=$BASE):"
printf "  - %s\n" $REQ_CTX

# 3) Lire l’état des checks PR
info "État des checks PR #$PR_NUM :"
gh pr checks "$PR_NUM" || warn "gh pr checks indisponible (ouvre l’onglet Checks dans l’UI)."

# 4) Si tous les requis sont VERTS, merge rebase
ALL_OK=1
for ctx in $REQ_CTX; do
  # gh pr checks n’a pas d’API machine-readable simple; on fait une heuristique
  # On considère "success" si le nom apparaît dans la liste et pas dans les sections failing.
  if ! gh pr checks "$PR_NUM" --json statusCheckRollup -q \
       '.statusCheckRollup[] | select(.name=="'"$ctx"'") | select(.conclusion=="SUCCESS")' >/dev/null 2>&1; then
    ALL_OK=0
  fi
done

if [ "$ALL_OK" -eq 1 ] && [ -n "$REQ_CTX" ]; then
  info "Tous les contexts requis semblent verts → tentative de merge (rebase)…"
  if gh pr merge "$PR_NUM" --rebase --delete-branch; then
    ok "PR #$PR_NUM mergée avec succès."
    # 5) Relancer CI sur main
    info "Relance CI sur $BASE (build, ci-accel, pip-audit)…"
    gh workflow run .github/workflows/build-publish.yml -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/ci-accel.yml -r "$BASE"        >/dev/null 2>&1 || true
    gh workflow run .github/workflows/pip-audit.yml -r "$BASE"       >/dev/null 2>&1 || true
    ok "Relances envoyées."
  else
    warn "Merge refusé (policy). Essaie avec l’UI, ou vérifie encore les checks."
  fi
else
  warn "Tous les contexts requis NE sont PAS verts. Rappels :"
  printf "  • Requis: %s\n" $REQ_CTX
  echo "  • Ouvre l’onglet Checks de la PR et attends build + gitleaks en VERT."
  echo "  • Si ça bloque, relance manuelle: gh workflow run … -r <branch-de-la-PR>"
fi

echo
ok "Terminé. La fenêtre RESTE OUVERTE."
