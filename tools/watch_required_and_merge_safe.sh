#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — merge auto quand pypi-build/build & secret-scan/gitleaks sont VERTS
set -u -o pipefail; set +e

PR="${1:-20}"
BASE="${2:-main}"
MAX_ITERS="${3:-60}"   # ~60 * 15s ≈ 15 minutes
SLEEP_SECS="${4:-15}"

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

REQ1="pypi-build/build"
REQ2="secret-scan/gitleaks"

info "PR #$PR • base=$BASE"
info "Checks requis: $REQ1  |  $REQ2"

# Boucle d’attente
i=1
while [ "$i" -le "$MAX_ITERS" ]; do
  info "Itération $i/$MAX_ITERS — lecture statut PR #$PR…"
  # On récupère la vue texte car gh pr checks JSON est capricieux dans ton env
  OUT="$(gh pr checks "$PR" 2>&1)"
  echo "$OUT" | sed 's/^/    /'

  ok1=false; ok2=false
  echo "$OUT" | grep -E "^[[:space:]]*✓[[:space:]]+$REQ1" >/dev/null 2>&1 && ok1=true
  echo "$OUT" | grep -E "^[[:space:]]*✓[[:space:]]+$REQ2" >/dev/null 2>&1 && ok2=true

  if $ok1 && $ok2; then
    ok "Les 2 checks requis sont VERTS — tentative de merge rebase…"
    if gh pr merge "$PR" --rebase --delete-branch; then
      ok "Merge rebase effectué."
      exit 0
    else
      warn "Le CLI a refusé. Essaie l’UI : bouton « Rebase and merge »."
      exit 0
    fi
  fi

  info "Requis encore en attente: $([ "$ok1" = false ] && echo "$REQ1 ")$([ "$ok2" = false ] && echo "$REQ2")"
  sleep "$SLEEP_SECS"
  i=$((i+1))
done

warn "Temps d’attente écoulé sans que les 2 requis soient verts. Relance les workflows si besoin, puis relance ce script."
exit 0
