# tools/watch_required_and_merge_safe_v3.sh
#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — merge auto quand TOUS les checks "requis" (branch protection) sont success
set -u -o pipefail; set +e

PR="${1:-20}"
BASE="${2:-main}"
MAX_ITERS="${3:-80}"          # 80 * 15s ≈ 20 min
SLEEP_SECS="${4:-15}"

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

need_cmd(){ command -v "$1" >/dev/null 2>&1 || { err "Commande '$1' requise"; exit 0; }; }

need_cmd gh
# jq est très utile mais on garde un fallback s'il manque
command -v jq >/dev/null 2>&1 || warn "jq absent — fallback heuristique activé."

REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"

info "Repo=${REPO:-UNKNOWN} • PR #$PR • base=$BASE"

# --- Récupérer la liste des contexts requis depuis la branch protection
REQ=()
if command -v jq >/dev/null 2>&1; then
  JSON_BP="$(gh api "repos/:owner/:repo/branches/$BASE/protection" -H "Accept: application/vnd.github+json" 2>/dev/null)"
  STRICT="$(printf '%s' "$JSON_BP" | jq -r '.required_status_checks.strict // false' 2>/dev/null)"
  REQ_CTXS="$(printf '%s' "$JSON_BP" | jq -r '.required_status_checks.checks[]?.context? // empty,.required_status_checks.contexts[]? // empty' 2>/dev/null | sed '/^$/d')"
  if [ -n "$REQ_CTXS" ]; then
    while IFS= read -r c; do REQ+=("$c"); done <<< "$REQ_CTXS"
  fi
  info "Require up-to-date (strict) = ${STRICT:-false}"
else
  warn "Impossible de lire la protection (jq manquant). Je retombe sur le cas connu: REQ=('pypi-build/build' 'secret-scan/gitleaks')."
  REQ=("pypi-build/build" "secret-scan/gitleaks")
fi

if [ "${#REQ[@]}" -eq 0 ]; then
  warn "Aucun contexte requis détecté. Je n’essaie pas de merger automatiquement."
  exit 0
fi

info "Checks requis:"
for c in "${REQ[@]}"; do echo "  - $c"; done

# --- SHA de tête de la PR
HEAD_SHA="$(gh pr view "$PR" --json commits -q '.commits[-1].oid' 2>/dev/null)"
if [ -z "${HEAD_SHA:-}" ]; then
  err "Impossible d’obtenir le HEAD SHA de la PR."
  exit 0
fi
info "PR head SHA = $HEAD_SHA"

# --- Fonction qui teste si tous les requis sont success via /check-runs
all_required_green_api() {
  command -v jq >/dev/null 2>&1 || return 2
  local json runs ok_count=0
  json="$(gh api "repos/:owner/:repo/commits/$HEAD_SHA/check-runs" -H "Accept: application/vnd.github+json" 2>/dev/null)" || return 2
  # build un index name->conclusion
  # note : GitHub renvoie beaucoup de check-runs; on mappe par .name
  for ctx in "${REQ[@]}"; do
    # certains jobs publient .name plus court (ex: 'build' plutôt que 'pypi-build/build')
    # on tente d'abord correspondance exacte, sinon suffixe après '/'
    # exact
    concl="$(printf '%s' "$json" | jq -r --arg n "$ctx" '.check_runs[]? | select(.name==$n) | .conclusion // ""' | head -n1)"
    if [ -z "$concl" ]; then
      short="${ctx##*/}"
      concl="$(printf '%s' "$json" | jq -r --arg n "$short" '.check_runs[]? | select(.name==$n) | .conclusion // ""' | head -n1)"
    fi
    [ "$concl" = "success" ] && ok_count=$((ok_count+1))
  done
  [ "$ok_count" -eq "${#REQ[@]}" ]
}

# --- Fallback heuristique sur la sortie texte de gh pr checks
all_required_green_text() {
  local out ok_count=0
  out="$(gh pr checks "$PR" 2>&1)"
  echo "$out" | sed 's/^/    /'
  for ctx in "${REQ[@]}"; do
    short="${ctx##*/}"              # p.ex. build, gitleaks
    # On accepte soit la forme longue avec coche, soit le format tableau "short  pass"
    if echo "$out" | grep -E "^[[:space:]]*✓[[:space:]]+$ctx" >/dev/null 2>&1; then
      ok_count=$((ok_count+1))
      continue
    fi
    if echo "$out" | awk '{print $1" "$2}' | grep -E "^(|.*[[:space:]])${short}[[:space:]]+pass$" >/dev/null 2>&1; then
      ok_count=$((ok_count+1))
      continue
    fi
  done
  [ "$ok_count" -eq "${#REQ[@]}" ]
}

i=1
while [ "$i" -le "$MAX_ITERS" ]; do
  info "Itération $i/$MAX_ITERS — vérification des requis…"
  if all_required_green_api; then
    ok "Tous les requis sont SUCCESS (API). Tentative de merge (rebase)…"
    if gh pr merge "$PR" --rebase --delete-branch; then
      ok "Merge rebase effectué."
      exit 0
    else
      warn "Le CLI a refusé. Tu peux cliquer « Rebase and merge » dans l’UI, les requis sont verts."
      exit 0
    fi
  fi
  if all_required_green_text; then
    ok "Tous les requis sont PASS (texte). Tentative de merge (rebase)…"
    if gh pr merge "$PR" --rebase --delete-branch; then
      ok "Merge rebase effectué."
      exit 0
    else
      warn "Le CLI a refusé. Clique « Rebase and merge » dans l’UI."
      exit 0
    fi
  fi
  info "Au moins un requis n’est pas encore vert. Pause ${SLEEP_SECS}s…"
  sleep "$SLEEP_SECS"
  i=$((i+1))
done

warn "Temps écoulé sans que tous les requis deviennent verts. Relance ciblée des workflows requis si nécessaire, puis relance ce script."
exit 0
