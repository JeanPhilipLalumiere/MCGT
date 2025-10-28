# tools/refresh_required_checks_and_merge_safe.sh
#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — relance pypi-build & gitleaks sur la branche de la PR et merge quand c'est vert.
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

PR="${1:-20}"
BASE="${2:-main}"
MAX_ITER="${MAX_ITER:-30}"
SLEEP_SECS="${SLEEP_SECS:-20}"
REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"

printf '\n\033[1m== REFRESH REQUIRED CHECKS & MERGE (NEVER-FAIL) ==\033[0m\n'
info "Repo=${REPO:-UNKNOWN} • Base=${BASE} • PR=#${PR}"

if ! command -v gh >/dev/null 2>&1; then
  err "gh non disponible — fais-le dans l’UI: relance pypi-build & secret-scan → quand verts, merge rebase."
  exit 0
fi

HEAD_BR="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)"
[ -n "$HEAD_BR" ] || { err "Impossible d’obtenir la branche de tête de la PR #$PR."; exit 0; }
ok "Branche PR: ${HEAD_BR}"

# 1) Lire les checks requis de BASE (pour ne regarder QUE ceux-là)
REQ_CTX="$(gh api -H 'Accept: application/vnd.github+json' "/repos/$REPO/branches/$BASE/protection" \
            -q '.required_status_checks.checks[].context' 2>/dev/null | sed '/^null$/d')"
if [ -z "$REQ_CTX" ]; then
  warn "Impossible de lire les checks requis (permissions ?). Je continuerai en best-effort."
else
  info "Checks requis sur '${BASE}':"; printf "  • %s\n" $REQ_CTX
fi

# 2) Dispatch best-effort sur la branche PR
info "Dispatch pypi-build & secret-scan sur ${HEAD_BR}…"
gh workflow run .github/workflows/pypi-build.yml  -r "$HEAD_BR" >/dev/null 2>&1 || warn "dispatch pypi-build: 422 ? (pas de workflow_dispatch)"
gh workflow run .github/workflows/secret-scan.yml -r "$HEAD_BR" >/dev/null 2>&1 || warn "dispatch secret-scan: 422 ? (pas de workflow_dispatch)"
ok "Relances envoyées (si triggers présents)."

# 3) Boucle de polling jusqu’à succès des checks requis
need_all_ok=1
if [ -n "$REQ_CTX" ]; then
  need_all_ok=0
  info "Surveillance des checks REQUIS de la PR #$PR… (max ${MAX_ITER} itérations)"
  i=0
  while [ $i -lt $MAX_ITER ]; do
    i=$((i+1))
    all_ok=1
    echo
    info "Itération $i/${MAX_ITER} — statut actuel:"
    gh pr checks "$PR" || warn "gh pr checks indisponible (ouvre l’onglet Checks)."

    for ctx in $REQ_CTX; do
      concl="$(gh pr checks "$PR" --json statusCheckRollup \
               -q '.statusCheckRollup[] | select(.name=="'"$ctx"'") | .conclusion' 2>/dev/null | tail -n1)"
      case "$concl" in
        SUCCESS) ok   "Requis OK : $ctx" ;;
        PENDING|"") warn "Requis EN COURS : $ctx" ; all_ok=0 ;;
        *)         warn "Requis NON VERT : $ctx (conclusion=$concl)" ; all_ok=0 ;;
      esac
    done

    if [ $all_ok -eq 1 ]; then
      ok "Tous les checks REQUIS sont verts."
      need_all_ok=1
      break
    fi
    sleep "$SLEEP_SECS"
  done
else
  warn "Liste des requis inconnue — je ne peux pas évaluer automatiquement."
fi

# 4) Merge si OK
if [ $need_all_ok -eq 1 ]; then
  info "Tentative de merge (rebase)…"
  if gh pr merge "$PR" --rebase --delete-branch; then
    ok "PR #$PR mergée."
    info "Relance CI sur ${BASE} (post-merge) :"
    gh workflow run .github/workflows/build-publish.yml -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/ci-accel.yml  -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/pip-audit.yml -r "$BASE" >/dev/null 2>&1 || true
    ok "Relances main envoyées."
  else
    warn "Merge refusé par la policy. Essaie via l’UI (‘Rebase and merge’) quand c’est vert."
  fi
else
  warn "Conditions non réunies pour merger (ou requis inconnus)."
  echo "Rappels — relances manuelles sur ${HEAD_BR} :"
  echo "  gh workflow run .github/workflows/pypi-build.yml  -r ${HEAD_BR}"
  echo "  gh workflow run .github/workflows/secret-scan.yml -r ${HEAD_BR}"
fi

echo; ok "Terminé — fenêtre laissée OUVERTE."
