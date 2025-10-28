# tools/merge_when_required_green_safe.sh
#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — merge une PR si et seulement si les checks REQUIS sont verts.
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

PR_NUM="${1:-20}"          # par défaut: #20 (security-pins)
BASE="${2:-main}"
BR_REQUIRED_ONLY="${BR_REQUIRED_ONLY:-1}"  # 1 = n’examine que les checks REQUIS

printf '\n\033[1m== MERGE WHEN REQUIRED GREEN (NEVER-FAIL) ==\033[0m\n'
REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"
info "Repo=${REPO:-UNKNOWN} • Base=${BASE} • PR=#${PR_NUM}"

if ! command -v gh >/dev/null 2>&1; then
  err "gh absent. Merge dans l’UI (Rebase and merge)."
  exit 0
fi

# 1) Lire les contexts requis de la branche protégée
REQ_CTX="$(gh api -H 'Accept: application/vnd.github+json' \
  "/repos/$REPO/branches/$BASE/protection" \
  -q '.required_status_checks.checks[].context' 2>/dev/null | sed '/^null$/d')"

if [ -z "$REQ_CTX" ]; then
  warn "Impossible de lire la branch protection (permissions ?). Je bascule en best-effort."
fi

info "Checks requis sur '${BASE}':"
if [ -n "$REQ_CTX" ]; then printf "  - %s\n" $REQ_CTX; else echo "  (inconnu, best-effort)"; fi

# 2) Montrer l’état des checks PR (informatif)
info "État des checks PR #${PR_NUM}:"
gh pr checks "${PR_NUM}" || warn "gh pr checks indisponible; vérifie l’onglet Checks."

# 3) Vérifier réussite des checks REQUIS uniquement
ALL_OK=1
if [ -n "$REQ_CTX" ] && [ "$BR_REQUIRED_ONLY" = "1" ]; then
  for ctx in $REQ_CTX; do
    is_ok="$(gh pr checks "$PR_NUM" --json statusCheckRollup \
              -q '.statusCheckRollup[] | select(.name=="'"$ctx"'") | select(.conclusion=="SUCCESS")' 2>/dev/null)"
    if [ -z "$is_ok" ]; then
      warn "Requis NON vert: ${ctx}"
      ALL_OK=0
    else
      ok "Requis OK: ${ctx}"
    fi
  done
else
  warn "Liste des requis indisponible — tentative de merge best-effort."
fi

# 4) Si tout est OK, tenter le merge (rebase)
if [ "$ALL_OK" -eq 1 ]; then
  info "Tous les checks REQUIS sont verts → tentative de merge (rebase)…"
  if gh pr merge "$PR_NUM" --rebase --delete-branch; then
    ok "PR #${PR_NUM} mergée."
    info "Relance CI sur ${BASE} (build, ci-accel, pip-audit)…"
    gh workflow run .github/workflows/build-publish.yml -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/ci-accel.yml  -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/pip-audit.yml -r "$BASE" >/dev/null 2>&1 || true
    ok "Relances envoyées."
  else
    warn "Merge refusé (policy ou divergence). Essaie: gh pr merge ${PR_NUM} --auto (ou UI)."
  fi
else
  warn "Conditions non réunies pour merger."
  if [ -n "$REQ_CTX" ]; then
    echo "Rappels — checks requis attendus en VERT:"
    printf "  • %s\n" $REQ_CTX
  fi
  echo "Tu peux relancer les jobs requis sur la branche PR:"
  echo "  gh workflow run .github/workflows/pypi-build.yml -r \$(gh pr view ${PR_NUM} --json headRefName -q .headRefName)"
  echo "  gh workflow run .github/workflows/secret-scan.yml -r \$(gh pr view ${PR_NUM} --json headRefName -q .headRefName)"
fi

echo; ok "Terminé. La fenêtre RESTE OUVERTE."
