#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — Diagnostic protections/rulesets qui bloquent le merge
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

PR_NUM="${1:-20}"
BASE="${2:-main}"
OUT="_tmp/merge_blockers_probe"; mkdir -p "$OUT"

if ! gh auth status >/dev/null 2>&1; then
  warn "gh non authentifié — résultats partiels possibles."
fi

REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"
info "Repo=${REPO:-UNKNOWN} • Base=$BASE • PR=#$PR_NUM"

# 1) Branch protection (classique)
gh api "repos/:owner/:repo/branches/$BASE/protection" \
  -H "Accept: application/vnd.github+json" \
  > "$OUT/branch_protection.json" 2>"$OUT/branch_protection.err"
jq '.required_status_checks' "$OUT/branch_protection.json" 2>/dev/null | sed 's/^/[BP] /' || cat "$OUT/branch_protection.json" | sed 's/^/[BP] /'
STRICT="$(jq -r '.required_status_checks.strict' "$OUT/branch_protection.json" 2>/dev/null)"
REQS="$(jq -r '.required_status_checks.checks[]?.context // .required_status_checks.contexts[]?' "$OUT/branch_protection.json" 2>/dev/null)"
echo
info "Branch protection — strict=$STRICT"
echo "$REQS" | sed 's/^/  • /'

# 2) Rulesets (nouvelles règles GitHub)
gh api "repos/:owner/:repo/rulesets?per_page=100" \
  -H "Accept: application/vnd.github+json" \
  > "$OUT/rulesets.json" 2>"$OUT/rulesets.err"

HAS_JQ=1; command -v jq >/dev/null 2>&1 || HAS_JQ=0
ACTIVE_MATCHING=()

if [ "$HAS_JQ" = "1" ]; then
  jq -r '
    .[] 
    | select(.enforcement == "active")
    | select((.conditions.ref_name.include[]? | test("^refs/heads/'"$BASE"'$")) or (.conditions.ref_name.include[]? == "'$BASE'"))
    | {name, enforcement, bypass_actors, rules, conditions}
  ' "$OUT/rulesets.json" > "$OUT/rulesets.active.$BASE.json"

  if [ -s "$OUT/rulesets.active.$BASE.json" ]; then
    ok "Rulesets ACTIVES ciblant '$BASE':"
    cat "$OUT/rulesets.active.$BASE.json" | sed 's/^/  /'
    echo

    # Extraire exigences communes
    REQ_ALL_CHECKS="$(jq -r '..|objects|select(has("require_status_checks"))|.require_status_checks.requirements // empty' "$OUT/rulesets.active.$BASE.json" | tr '\n' ' ')"
    REQ_SPECIFIC_CHECKS="$(jq -r '..|objects|select(has("status_checks"))|.status_checks[].context // empty' "$OUT/rulesets.active.$BASE.json")"
    REQ_UPTODATE="$(jq -r '..|objects|select(has("pull_request"))|.pull_request.require_up_to_date // empty' "$OUT/rulesets.active.$BASE.json" | tr '\n' ' ')"
    [ -n "$REQ_ALL_CHECKS" ] && info "Ruleset: peut exiger « all checks pass » → $REQ_ALL_CHECKS"
    [ -n "$REQ_SPECIFIC_CHECKS" ] && info "Ruleset: checks spécifiques requis:" && echo "$REQ_SPECIFIC_CHECKS" | sed 's/^/  • /'
    [ -n "$REQ_UPTODATE" ] && info "Ruleset: require_up_to_date → $REQ_UPTODATE"
  else
    info "Aucune ruleset active ciblant explicitement '$BASE'."
  fi
else
  warn "jq absent — rulesets non analysées. Ouvre Settings ▸ Rules (Rulesets)."
fi

# 3) Statut PR (mergeable / mergeStateStatus)
gh pr view "$PR_NUM" --json mergeStateStatus,mergeable,isDraft,headRefName,baseRefName,title \
  > "$OUT/pr_state.json" 2>"$OUT/pr_state.err"
cat "$OUT/pr_state.json" | sed 's/^/[PR ] /'
echo

MS="$(jq -r '.mergeStateStatus' "$OUT/pr_state.json" 2>/dev/null)"
ME="$(jq -r '.mergeable' "$OUT/pr_state.json" 2>/dev/null)"
if [ "$MS" = "BLOCKED" ]; then
  warn "GitHub signale mergeStateStatus=BLOCKED (ruleset, up-to-date ou autre exigence)."
fi
if [ "$ME" != "MERGEABLE" ] && [ -n "$ME" ]; then
  warn "mergeable=$ME — GitHub calcule que la PR n’est pas mergeable."
fi

echo
ok "Diagnostic écrit dans $OUT/ (json + err). Fenêtre laissée OUVERTE."
