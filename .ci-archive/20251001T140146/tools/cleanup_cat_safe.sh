#!/usr/bin/env bash
set +e
STAMP="$(date +%Y%m%dT%H%M%S)"
LOG="$PWD/.ci-logs/cleanup-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

say(){ printf "\n== %s ==\n" "$*"; }
pause(){ printf "\n(Pause) Appuie Entrée pour continuer… "; read -r _ || true; }

say "Contexte: projet=$(basename "$PWD")  timestamp=$STAMP"

# 1) Archive .ci-logs -> .ci-archive/logs-$STAMP
ARCH_DIR=".ci-archive/$STAMP"
mkdir -p "$ARCH_DIR"
if [ -d .ci-logs ]; then
  say "Archiver .ci-logs -> $ARCH_DIR/.ci-logs.tar.gz"
  tar -czf "$ARCH_DIR/.ci-logs.tar.gz" .ci-logs || true
else
  echo "Aucun .ci-logs trouvé"
fi

# 2) Fichiers tools à PRESERVER (modifie si tu veux)
KEEP_TOOLS=(
  "tools/guard_no_recipeprefix.sh"
  "tools/sanity_diag.sh"
  "tools/ci_trigger_and_fetch_diag.sh"
  "tools/ci_show_last_diag.sh"
)

# 3) Collecter scripts tools existants
ALL_TOOLS=( $(ls tools 2>/dev/null || true) )
TO_MOVE=()
for f in "${ALL_TOOLS[@]}"; do
  full="tools/$f"
  keep=false
  for k in "${KEEP_TOOLS[@]}"; do
    [ "$full" = "$k" ] && keep=true && break
  done
  $keep || TO_MOVE+=("$full")
done

# 4) Archive les scripts obsolètes
if [ ${#TO_MOVE[@]} -gt 0 ]; then
  say "Archiver ${#TO_MOVE[@]} script(s) tools obsolètes -> $ARCH_DIR/tools/"
  mkdir -p "$ARCH_DIR/tools"
  for f in "${TO_MOVE[@]}"; do
    echo "  -> $f"
    mv "$f" "$ARCH_DIR/tools/" 2>/dev/null || cp -a "$f" "$ARCH_DIR/tools/" 2>/dev/null || true
  done
else
  echo "Aucun script tools obsolète détecté."
fi

# 5) Liste workflows multiples et propose d'archiver les non retenus
say "Workflows dans .github/workflows/"
ls -1 .github/workflows 2>/dev/null || echo "(vide)"
echo
echo "Propose d'archiver les workflows non-canonique (garde 'sanity-main.yml' et 'sanity-echo.yml' si présents)."
ARCH_WF_DIR="$ARCH_DIR/workflows"
mkdir -p "$ARCH_WF_DIR"
for wf in .github/workflows/*; do
  [ -f "$wf" ] || continue
  base="$(basename "$wf")"
  if [ "$base" != "sanity-main.yml" ] && [ "$base" != "sanity-echo.yml" ]; then
    echo "  -> archiver $base"
    mv "$wf" "$ARCH_WF_DIR/" 2>/dev/null || cp -a "$wf" "$ARCH_WF_DIR/" 2>/dev/null || true
  fi
done

# 6) Branches temporaires (locaux) list & suggestion (no remote delete by default)
say "Branches locales contenant 'ci/sanity' :"
git for-each-ref --format='%(refname:short)' refs/heads | grep -E 'ci/sanity' || echo "(aucune)"
echo
echo "Si tu veux supprimer une branche locale listée, exécute:"
echo "  git branch -D <branch-name>"
pause

# 7) Show archive summary
say "Archive créée : $ARCH_DIR"
ls -la "$ARCH_DIR" || true
echo
say "Aucune suppression irréversible n'a été faite sans ta confirmation. Fichiers déplacés/copied vers l'archive."
pause
