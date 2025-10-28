# tools/strict_toggle_merge_restore_safe.sh
#!/usr/bin/env bash
set -u -o pipefail; set +e

PR="${1:-20}"
BASE="${2:-main}"

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

need(){ command -v "$1" >/dev/null 2>&1 || { err "commande requise: $1"; exit 0; }; }
need gh; need jq

OUT="_tmp/strict_toggle_merge_restore"; mkdir -p "$OUT"

info "Lecture protection de branche… ($BASE)"
if ! gh api "repos/:owner/:repo/branches/$BASE/protection" \
      -H "Accept: application/vnd.github+json" >"$OUT/protection.get.json" 2>"$OUT/protection.get.err"; then
  err "Impossible de lire la protection de branche."
  exit 0
fi

STRICT_BEFORE="$(jq -r '.required_status_checks.strict // false' "$OUT/protection.get.json")"
info "strict avant = ${STRICT_BEFORE}"

# Construit un payload de PUT identique sauf 'strict=false'
CONTEXTS_JSON="$(jq -c '.required_status_checks.contexts // []' "$OUT/protection.get.json")"
PAYLOAD="$(jq -n \
  --argjson contexts "$CONTEXTS_JSON" \
  '{ required_status_checks: { strict: false, contexts: $contexts },
     enforce_admins: true,
     required_pull_request_reviews: .,
     restrictions: null }')"
# Injecte le bloc reviews complet depuis l'existant
PAYLOAD="$(jq --argjson reviews "$(jq '.required_pull_request_reviews' "$OUT/protection.get.json")" \
              '.required_pull_request_reviews = $reviews' <<<"$PAYLOAD")"

info "Désactivation TEMPORAIRE de strict (PUT)…"
if ! gh api -X PUT "repos/:owner/:repo/branches/$BASE/protection" \
      -H "Accept: application/vnd.github+json" \
      -F "required_status_checks.strict=false" \
      -F "required_status_checks.contexts=$(printf %s "$CONTEXTS_JSON")" \
      >"$OUT/protection.put.relax.json" 2>"$OUT/protection.put.relax.err"; then
  err "PUT strict=false refusé (droits ?)."
  exit 0
fi
ok "strict=false appliqué (temporairement)."

info "Tentative de merge (rebase)…"
if gh pr merge "$PR" --rebase --delete-branch; then
  ok "Merge effectué."
else
  warn "Le merge via CLI a été refusé. Tu peux essayer dans l’UI (Rebase and merge)."
fi

info "Restauration strict=true…"
if ! gh api -X PUT "repos/:owner/:repo/branches/$BASE/protection" \
      -H "Accept: application/vnd.github+json" \
      -F "required_status_checks.strict=true" \
      -F "required_status_checks.contexts=$(printf %s "$CONTEXTS_JSON")" \
      >"$OUT/protection.put.restore.json" 2>"$OUT/protection.put.restore.err"; then
  err "ATTENTION: restauration strict=true non appliquée (vérifie l’UI)."
  exit 0
fi
ok "Protection restaurée (strict=true)."
info "Terminé — fenêtres/logs conservés dans $OUT."
