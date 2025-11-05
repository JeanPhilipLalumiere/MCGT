# tools/refresh_required_checks_and_merge_safe_v2.sh
#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — détecte les checks requis par préfixe et merge si verts.
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

PR="${1:-20}"
BASE="${2:-main}"
MAX_ITER="${MAX_ITER:-20}"
SLEEP_SECS="${SLEEP_SECS:-15}"

REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"

printf '\n\033[1m== REFRESH REQUIRED CHECKS & MERGE v2 (NEVER-FAIL) ==\033[0m\n'
info "Repo=${REPO:-UNKNOWN} • Base=${BASE} • PR=#${PR}"

if ! command -v gh >/dev/null 2>&1; then
  err "gh non disponible — fais le merge via l’UI quand build + gitleaks sont verts."
  exit 0
fi

HEAD_BR="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)"
[ -n "$HEAD_BR" ] || { err "Impossible d’obtenir la branche de tête de la PR #$PR."; exit 0; }
ok "Branche PR: ${HEAD_BR}"

# 1) Lire les checks requis (contexts) depuis la protection de branche
REQ_CTX="$(gh api -H 'Accept: application/vnd.github+json' "/repos/$REPO/branches/$BASE/protection" \
            -q '.required_status_checks.checks[].context' 2>/dev/null | sed '/^null$/d')"
if [ -z "$REQ_CTX" ]; then
  warn "Impossible de lire les checks requis (permissions ?). Je bascule sur un set par défaut."
  REQ_CTX="pypi-build/build secret-scan/gitleaks"
fi
info "Checks requis (préfixes):"; for c in $REQ_CTX; do echo "  • $c"; done

# 2) (Best-effort) relances, si dispatch dispo
info "Relance best-effort des workflows requis sur ${HEAD_BR}…"
gh workflow run .github/workflows/pypi-build.yml  -r "$HEAD_BR" >/dev/null 2>&1 || true
gh workflow run .github/workflows/secret-scan.yml -r "$HEAD_BR" >/dev/null 2>&1 || true
ok "Relances envoyées (si workflow_dispatch présent)."

# 3) Boucle: on considère qu’un check requis est OK si
#    il existe un item dont .name COMMENCE par le contexte requis (préfixe)
all_green=0
for i in $(seq 1 "$MAX_ITER"); do
  echo
  info "Itération $i/$MAX_ITER — lecture statut PR #$PR…"
  # dump brut (lisible) pour debug dans le terminal
  gh pr checks "$PR" || warn "gh pr checks indisponible (ouvre l’onglet Checks)."

  # JSON pour matching par préfixe
  json="$(gh pr checks "$PR" --json statusCheckRollup 2>/dev/null)"
  [ -z "$json" ] && { warn "Pas de JSON — réessaie après ${SLEEP_SECS}s"; sleep "$SLEEP_SECS"; continue; }

  green_count=0
  missing=()

  for ctx in $REQ_CTX; do
    # Trouver toutes les entrées dont le nom commence par $ctx (éventuels suffixes "(pull_request)")
    concl="$(echo "$json" | jq -r --arg pfx "$ctx" '
      .statusCheckRollup
      | map(select(.name|startswith($pfx)))        # match par préfixe
      | map(.conclusion // empty)
      | unique | join(",")
    ' 2>/dev/null)"

    if [ -z "$concl" ]; then
      warn "Requis INCONNU sur cette PR (aucun nom commençant par '$ctx')."
    elif echo "$concl" | grep -q 'SUCCESS'; then
      ok "Requis OK : $ctx"
      green_count=$((green_count+1))
    elif echo "$concl" | grep -q 'PENDING'; then
      warn "Requis EN COURS : $ctx ($concl)"
      missing+=("$ctx")
    else
      warn "Requis NON VERT : $ctx ($concl)"
      missing+=("$ctx")
    fi
  done

  if [ "$green_count" -eq $(echo "$REQ_CTX" | wc -w) ]; then
    all_green=1
    break
  fi

  sleep "$SLEEP_SECS"
done

# 4) Merge si tout vert
if [ "$all_green" -eq 1 ]; then
  info "Tous les requis sont verts — tentative de merge (rebase)…"
  if gh pr merge "$PR" --rebase --delete-branch; then
    ok "PR #$PR mergée."
    info "Relance CI sur ${BASE} (post-merge)…"
    gh workflow run .github/workflows/build-publish.yml -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/ci-accel.yml      -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/pip-audit.yml     -r "$BASE" >/dev/null 2>&1 || true
    ok "Relances envoyées."
  else
    warn "Merge refusé par la policy. Essaie via l’UI (‘Rebase and merge’) maintenant que c’est vert."
  fi
else
  warn "Conditions non réunies pour merger automatiquement."
  echo "Rappels — relances manuelles sur ${HEAD_BR} :"
  echo "  gh workflow run .github/workflows/pypi-build.yml  -r ${HEAD_BR}"
  echo "  gh workflow run .github/workflows/secret-scan.yml -r ${HEAD_BR}"
  echo "…puis merge rebase quand c’est vert."
fi

echo; ok "Terminé — fenêtre laissée OUVERTE."

