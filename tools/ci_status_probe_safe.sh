# tools/ci_status_probe_safe.sh
#!/usr/bin/env bash
# Sonde non-destructive. N'écrit rien. NE FERME PAS la fenêtre.
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail(){ printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; }

OUT="_tmp/ci_status_probe"; mkdir -p "$OUT"
REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#' )"
BR="${1:-main}"

[ -z "$REPO" ] && fail "Impossible de détecter le repo GitHub (origin)"; REPO="${REPO:-UNKNOWN}"
CUR="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"

printf '\n\033[1m== CI STATUS PROBE ==\033[0m\n'
info "Repo=$REPO • Branch ciblée=$BR • Branche courante=$CUR"

# 1) Required checks (branch protection)
info "Lecture protection de branche (required checks)…"
if gh api -H 'Accept: application/vnd.github+json' "/repos/$REPO/branches/$BR/protection" > "$OUT/protection.json" 2>/dev/null; then
  jq -r '.required_status_checks.checks[].context' "$OUT/protection.json" 2>/dev/null | nl -w2 -s'  ' \
    | sed '1s/^/[OK  ] Required contexts:\n/' || warn "Impossible d'extraire les contexts"
else
  warn "Lecture via API impossible (token ?). Ouvre Settings → Branches pour vérifier."
fi

# 2) Derniers runs de workflows clés
list_runs(){
  local wf="$1"
  [ -f ".github/workflows/$wf" ] || { warn "$wf absent localement"; return; }
  info "Derniers runs • $wf@$BR"
  gh run list --workflow "$wf" --branch "$BR" --limit 5 2>/dev/null | sed 's/^/  /' \
    || warn "gh run list indisponible pour $wf"
}
list_runs build-publish.yml
list_runs ci-accel.yml
list_runs secret-scan.yml
list_runs pip-audit.yml

# 3) Stash post-merge + rappel commandes
if git stash list | grep -q 'post-merge safety'; then
  ST="$(git stash list | grep 'post-merge safety' | head -n1 | cut -d: -f1)"
  ok "Stash détecté: $ST"
  printf '   • Voir diff MANIFEST.in : less %s\n' "_tmp/hardening_now/manifest.diff"
  printf '   • Réappliquer MANIFEST.in: git checkout "%s" -- MANIFEST.in && git commit -m "chore(manifest): apply post-merge tuned rules"\n' "$ST"
  printf '   • Supprimer le stash    : git stash drop "%s"\n' "$ST"
else
  ok "Aucun stash ‘post-merge safety’ en attente."
fi

# 4) Branche rewrite distante existante ?
info "Branches distantes rewrite/* mergées (best-effort)…"
git fetch -p origin >/dev/null 2>&1 || true
RB_LIST="$(git branch -r | sed 's/^..//' | grep '^origin/rewrite/' || true)"
if [ -n "$RB_LIST" ]; then
  echo "$RB_LIST" | sed 's/^/[WARN] Existe encore: /'
  echo "  • Si mergée: suppression:  git push origin --delete <branch>"
else
  ok "Aucune branche distante rewrite/* trouvée."
fi

printf '\n\033[1;32mFait.\033[0m (fenêtre laissée OUVERTE)\n'
