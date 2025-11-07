#!/usr/bin/env bash
# tools/arm_automerge_and_nudge_strict_safe.sh
set -u -o pipefail; set +e
PR="${1:-20}"
BASE="${2:-main}"

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR]\033[0m %s\n' "$*"; }

REPO_JSON="$(gh api repos/:owner/:repo 2>/dev/null)" || { err "gh api repo ko"; exit 0; }
ALLOW_MERGE="$(jq -r '.allow_merge_commit' <<<"$REPO_JSON")"
ALLOW_SQUASH="$(jq -r '.allow_squash_merge' <<<"$REPO_JSON")"
ALLOW_REBASE="$(jq -r '.allow_rebase_merge' <<<"$REPO_JSON")"
info "merge_commit=$ALLOW_MERGE • squash=$ALLOW_SQUASH • rebase=$ALLOW_REBASE"

arm_auto() {
  local method="$1"
  info "Tentative auto-merge ($method)…"
  gh pr merge "$PR" --auto "--$method" 2>&1 | sed 's/^/  /'
}

# 1) armer auto-merge selon méthodes autorisées
TRIED=0
if [ "$ALLOW_SQUASH" = "true" ]; then arm_auto squash; TRIED=1; fi
if [ "$ALLOW_MERGE"  = "true" ]; then arm_auto merge;  TRIED=1; fi
if [ "$ALLOW_REBASE" = "true" ]; then arm_auto rebase; TRIED=1; fi
[ "$TRIED" -eq 0 ] && warn "Aucune méthode de merge autorisée via API ? (vérifie les Settings › Merge)."

# 2) relance pypi-build & secret-scan sur la branche PR
BR_HEAD="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)"
[ -z "${BR_HEAD:-}" ] && { warn "Branche PR introuvable"; exit 0; }
info "Relance workflows requis sur $BR_HEAD…"
gh workflow run .github/workflows/pypi-build.yml  -r "$BR_HEAD" 2>/dev/null
gh workflow run .github/workflows/secret-scan.yml -r "$BR_HEAD" 2>/dev/null

ok "Auto-merge armé (si autorisé) + relances envoyées. Surveille l’onglet Checks."
