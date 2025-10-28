# tools/post_merge_sync_main_safe.sh
#!/usr/bin/env bash
# NE FERME PAS LA FENÊTRE — sécurise ton état local puis bascule proprement sur main
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail(){ printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; }

OUT="_tmp/post_merge_sync"; mkdir -p "$OUT"
CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
[ -z "$CUR_BRANCH" ] && fail "Pas de repo Git courant." && exit 0
info "Branche courante: $CUR_BRANCH"

# 1) Stash de sécurité si arbre sale
if ! git diff --quiet || ! git diff --cached --quiet; then
  TS="$(date +%Y%m%dT%H%M%S)"
  MSG="post-merge safety $TS on $CUR_BRANCH"
  git stash push -u -m "$MSG" >/dev/null 2>&1
  STASH_REF="$(git stash list | head -n1 | cut -d: -f1)"
  [ -n "$STASH_REF" ] && ok "Stash créé: $STASH_REF ($MSG)" || warn "Aucun stash détecté (déjà propre ?)"
else
  ok "Arbre propre (pas de stash nécessaire)."
  STASH_REF=""
fi

# 2) Basculer sur main (création/liaison si besoin)
git fetch origin >/dev/null 2>&1 || warn "git fetch origin KO (je continue)"
if git show-ref --verify --quiet refs/heads/main; then
  git checkout main || { fail "checkout main impossible"; exit 0; }
else
  git checkout -B main origin/main || { fail "création main depuis origin/main impossible"; exit 0; }
fi
ok "Sur main"

git branch --set-upstream-to=origin/main main >/dev/null 2>&1 || true
git pull --rebase || warn "pull --rebase a renvoyé un avertissement (continuation)"

# 3) Si un stash existe: extraire MANIFEST.in du stash pour comparaison (sans l’appliquer)
if [ -n "${STASH_REF:-}" ]; then
  if git show "$STASH_REF":"MANIFEST.in" > "$OUT/stash_MANIFEST.in" 2>/dev/null; then
    cp -f MANIFEST.in "$OUT/main_MANIFEST.in" 2>/dev/null || true
    diff -u "$OUT/main_MANIFEST.in" "$OUT/stash_MANIFEST.in" > "$OUT/manifest.diff" 2>/dev/null || true
    info "Comparaison MANIFEST.in écrite: $OUT/manifest.diff"
    ok "Si tu veux réappliquer UNIQUEMENT MANIFEST.in du stash, plus tard:  git checkout \"$STASH_REF\" -- MANIFEST.in"
  else
    warn "MANIFEST.in absent du stash (rien à comparer)."
  fi
fi

# 4) Tentative douce de supprimer la branche locale de réécriture si déjà mergée (optionnelle)
MERGED_LIST="$(git branch --merged 2>/dev/null | sed 's/^..//')"
echo "$MERGED_LIST" | grep -q '^rewrite/' && {
  BR_TO_DEL="$(echo "$MERGED_LIST" | grep '^rewrite/' | head -n1)"
  git branch -d "$BR_TO_DEL" >/dev/null 2>&1 && ok "Branche locale supprimée: $BR_TO_DEL" || warn "Suppression locale non effectuée (peut-être non totalement mergée)."
}

ok "Sync post-merge terminé. Fenêtre laissée OUVERTE."
sleep 0.1; exit 0
