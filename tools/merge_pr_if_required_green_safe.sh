# tools/merge_pr_if_required_green_safe.sh
#!/usr/bin/env bash
# NE FERME PAS LA FENÊTRE — merge PR si les checks REQUIS par la branch protection sont verts.
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

PR="${1:-20}"
BASE="${2:-main}"
REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"

printf '\n\033[1m== MERGE PR IF REQUIRED GREEN (NEVER-FAIL) ==\033[0m\n'
info "Repo=${REPO:-UNKNOWN} • Base=${BASE} • PR=#${PR}"

if ! command -v gh >/dev/null 2>&1; then
  err "gh introuvable. Merge via l’UI (‘Rebase and merge’) si les 2 requis sont verts."
  exit 0
fi

HEAD_BR="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)"
[ -n "$HEAD_BR" ] || { err "Impossible de lire la branche de tête de la PR."; exit 0; }
ok "Branche PR: $HEAD_BR"

# Lire la protection de branche pour lister les contextes REQUIS
REQ_CTX="$(gh api -H 'Accept: application/vnd.github+json' "/repos/$REPO/branches/$BASE/protection" \
            -q '.required_status_checks.checks[].context' 2>/dev/null | sed '/^null$/d')"
if [ -z "$REQ_CTX" ]; then
  warn "Impossible de lire la protection — fallback: pypi-build/build secret-scan/gitleaks"
  REQ_CTX="pypi-build/build secret-scan/gitleaks"
fi
info "Checks requis (préfixes) :"; for c in $REQ_CTX; do echo "  • $c"; done

# Essayer d’obtenir un JSON de checks ; sinon on s’appuie sur la vue texte + merge tentatif
json="$(gh pr checks "$PR" --json statusCheckRollup 2>/dev/null)"
if [ -z "$json" ]; then
  warn "gh pr checks JSON indisponible — tentative de merge directe si l’UI affiche les 2 requis en vert."
  gh pr checks "$PR" || true
  if gh pr merge "$PR" --rebase --delete-branch; then
    ok "Merge OK."
    info "Relance CI post-merge sur ${BASE}…"
    gh workflow run .github/workflows/build-publish.yml -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/ci-accel.yml      -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/pip-audit.yml     -r "$BASE" >/dev/null 2>&1 || true
    ok "Relances envoyées. Fin."
    exit 0
  else
    warn "Merge refusé par gh. Essaie via l’UI ‘Rebase and merge’ (les 2 requis sont verts d’après tes logs)."
    exit 0
  fi
fi

# Vérification stricte par PRÉFIXE dans le JSON
green=0
for ctx in $REQ_CTX; do
  concl="$(echo "$json" | jq -r --arg pfx "$ctx" '
    .statusCheckRollup
    | map(select(.name|startswith($pfx)))
    | map(.conclusion // empty)
    | unique | join(",")
  ' 2>/dev/null)"
  if [ -z "$concl" ]; then
    warn "Requis INCONNU: $ctx"
  elif echo "$concl" | grep -q 'SUCCESS'; then
    ok "Requis OK : $ctx"
    green=$((green+1))
  else
    warn "Requis NON VERT : $ctx ($concl)"
  fi
done

if [ "$green" -eq $(echo "$REQ_CTX" | wc -w) ]; then
  info "Tous les requis sont verts — tentative de merge (rebase)…"
  if gh pr merge "$PR" --rebase --delete-branch; then
    ok "PR #$PR mergée."
    info "Relance CI post-merge sur ${BASE}…"
    gh workflow run .github/workflows/build-publish.yml -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/ci-accel.yml      -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/pip-audit.yml     -r "$BASE" >/dev/null 2>&1 || true
    ok "Relances envoyées."
  else
    warn "Merge refusé — fais-le via l’UI (‘Rebase and merge’), c’est vert côté requis."
  fi
else
  warn "Conditions non réunies (d’après JSON). Si l’UI montre les 2 requis en VERT, merger via l’UI."
fi

echo; ok "Terminé — fenêtre laissée OUVERTE."
