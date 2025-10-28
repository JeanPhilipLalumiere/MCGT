# tools/unblock_pr20_and_merge_safe.sh
#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — débloque les required checks (dispatch), vérifie par préfixe, merge si verts.
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

PR="${1:-20}"
BASE="${2:-main}"
MAX_ITER="${MAX_ITER:-30}"
SLEEP_SECS="${SLEEP_SECS:-15}"

REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"
printf '\n\033[1m== UNBLOCK PR & MERGE (NEVER-FAIL) ==\033[0m\n'
info "Repo=${REPO:-UNKNOWN} • Base=${BASE} • PR=#${PR}"

if ! command -v gh >/dev/null 2>&1; then
  err "gh indisponible : fais l’étape via l’UI (Checks → verts → Rebase and merge)."
  exit 0
fi

HEAD_BR="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)"
[ -n "$HEAD_BR" ] || { err "Impossible d’obtenir la branche de tête de la PR #$PR."; exit 0; }
ok "Branche PR: $HEAD_BR"

# 1) S’assurer du workflow_dispatch sur secret-scan.yml (sur la branche PR)
info "Vérifie/ajoute workflow_dispatch dans .github/workflows/secret-scan.yml (branche PR)…"
git fetch origin "$HEAD_BR" -q
git checkout "$HEAD_BR" >/dev/null 2>&1 || { err "checkout $HEAD_BR impossible."; exit 0; }
f=".github/workflows/secret-scan.yml"
if [ -f "$f" ]; then
  if ! grep -q 'workflow_dispatch' "$f"; then
    awk '1; /^on:/{print "  workflow_dispatch:"}' "$f" > _tmp/secret-scan.patched.yml && \
    mv _tmp/secret-scan.patched.yml "$f"
    git add "$f" && git commit -m "ci: add workflow_dispatch to secret-scan for manual reruns" >/dev/null 2>&1
    git push --force-with-lease >/dev/null 2>&1 && ok "workflow_dispatch ajouté à secret-scan.yml"
  else
    ok "secret-scan.yml possède déjà workflow_dispatch"
  fi
else
  warn "secret-scan.yml introuvable sur $HEAD_BR — je continue sans patch."
fi

# 2) Relance best-effort des workflows requis
info "Relance pypi-build & secret-scan sur $HEAD_BR…"
gh workflow run .github/workflows/pypi-build.yml  -r "$HEAD_BR" >/dev/null 2>&1 || warn "dispatch pypi-build: impossible"
gh workflow run .github/workflows/secret-scan.yml -r "$HEAD_BR" >/dev/null 2>&1 || warn "dispatch secret-scan: impossible"
ok "Relances envoyées (si dispatch présent)."

# 3) Lire les contexts requis depuis la protection de branche
REQ_CTX="$(gh api -H 'Accept: application/vnd.github+json' "/repos/$REPO/branches/$BASE/protection" \
            -q '.required_status_checks.checks[].context' 2>/dev/null | sed '/^null$/d')"
if [ -z "$REQ_CTX" ]; then
  warn "Impossible de lire la protection — fallback sur: pypi-build/build secret-scan/gitleaks"
  REQ_CTX="pypi-build/build secret-scan/gitleaks"
fi
info "Checks requis (préfixes) :"; for c in $REQ_CTX; do echo "  • $c"; done

# 4) Boucle d’attente: match par PRÉFIXE + conclusion SUCCESS
all_green=0
for i in $(seq 1 "$MAX_ITER"); do
  echo
  info "Itération $i/$MAX_ITER — lecture statut PR #$PR…"
  gh pr checks "$PR" || warn "gh pr checks indisponible (ouvre l’onglet Checks)."

  json="$(gh pr checks "$PR" --json statusCheckRollup 2>/dev/null)"
  if [ -z "$json" ]; then
    warn "Pas de JSON — je réessaie dans ${SLEEP_SECS}s"
    sleep "$SLEEP_SECS"
    continue
  fi

  green=0
  for ctx in $REQ_CTX; do
    concl="$(echo "$json" | jq -r --arg pfx "$ctx" '
      .statusCheckRollup
      | map(select(.name|startswith($pfx)))
      | map(.conclusion // empty)
      | unique | join(",")
    ' 2>/dev/null)"
    if [ -z "$concl" ]; then
      warn "Requis INCONNU : $ctx (aucun nom commençant par ce préfixe)"
    elif echo "$concl" | grep -q 'SUCCESS'; then
      ok "Requis OK : $ctx"
      green=$((green+1))
    elif echo "$concl" | grep -q 'PENDING'; then
      warn "Requis EN COURS : $ctx ($concl)"
    else
      warn "Requis NON VERT : $ctx ($concl)"
    fi
  done

  if [ "$green" -eq $(echo "$REQ_CTX" | wc -w) ]; then
    all_green=1
    break
  fi
  sleep "$SLEEP_SECS"
done

# 5) Merge si tout vert
if [ "$all_green" -eq 1 ]; then
  info "Tous les requis sont verts — tentative de merge (rebase)…"
  if gh pr merge "$PR" --rebase --delete-branch; then
    ok "PR #$PR mergée."
    info "Relance CI post-merge sur ${BASE}…"
    gh workflow run .github/workflows/build-publish.yml -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/ci-accel.yml      -r "$BASE" >/dev/null 2>&1 || true
    gh workflow run .github/workflows/pip-audit.yml     -r "$BASE" >/dev/null 2>&1 || true
    ok "Relances envoyées."
  else
    warn "Merge refusé — essaie via l’UI (‘Rebase and merge’), maintenant que c’est vert."
  fi
else
  warn "Conditions non réunies pour merge automatique."
  echo "Rappels — relances manuelles sur ${HEAD_BR} :"
  echo "  gh workflow run .github/workflows/pypi-build.yml  -r ${HEAD_BR}"
  echo "  gh workflow run .github/workflows/secret-scan.yml -r ${HEAD_BR}"
fi

echo; ok "Terminé — fenêtre laissée OUVERTE."
