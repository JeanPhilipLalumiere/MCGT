#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
###############################################################################
# Affiche le dernier diag (diag.json) déjà rapatrié.
# - Si aucun .tgz local, propose de télécharger l'artifact du dernier run
# - set +e + pause -> la fenêtre NE SE FERME JAMAIS
###############################################################################
set +e
STAMP="$(date +%Y%m%dT%H%M%S)"
ROOT_LOG="$PWD/.ci-logs/show-last-diag-$STAMP.log"
exec > >(tee -a "$ROOT_LOG") 2>&1

say() { printf "\n== %s ==\n" "$*"; }
pause() {
  printf "\n(Pause) Entrée pour continuer… "
  read -r _ || true
}

WF="sanity-main.yml"
ART_NAME="sanity-diag"

say "Recherche du dernier artifact .tgz déjà présent"
pick_tgz() {
  # Trie par date de modif décroissante et garde le 1er
  find .ci-logs -type f -name '*.tgz' -printf '%T@ %p\n' 2>/dev/null |
    sort -nr | head -n1 | cut -d' ' -f2-
}
TGZ="$(pick_tgz)"

if [ -z "$TGZ" ]; then
  echo "Aucun .tgz local trouvé."
  if command -v gh >/dev/null 2>&1 && [ -d .git ]; then
    printf "Télécharger l'artifact du DERNIER run existant ? [o/N] "
    read -r ans
    if [ "$ans" = "o" ] || [ "$ans" = "O" ]; then
      say "Téléchargement du dernier run $WF (si présent)"
      RID="$(gh run list --workflow "$WF" -L1 --json databaseId -q '.[0].databaseId' 2>/dev/null)"
      if [ -n "$RID" ]; then
        mkdir -p .ci-logs/sanity-main-artifacts
        if ! gh run download "$RID" --name "$ART_NAME" --dir .ci-logs/sanity-main-artifacts 2>/dev/null; then
          echo "WARN: download ciblé par nom échoué — tentative de download complet."
          gh run download "$RID" --dir .ci-logs/sanity-main-artifacts || true
        fi
        TGZ="$(pick_tgz)"
      else
        echo "WARN: Aucun run détecté."
      fi
    fi
  else
    echo "gh non disponible ou pas de repo git — pas de téléchargement."
  fi
fi

if [ -z "$TGZ" ]; then
  say "Toujours aucun artifact .tgz disponible."
  echo "Contenu actuel de .ci-logs/ :"
  find .ci-logs -maxdepth 2 -type f -print 2>/dev/null || true
  pause
  exit 0
fi

say "Artifact sélectionné"
echo "TGZ=$TGZ"
echo "-- Liste dans l'archive --"
tar -tzf "$TGZ" || true

echo "-- diag.json (pretty) --"
(tar -xOzf "$TGZ" ./diag.json 2>/dev/null || tar -xOzf "$TGZ" diag.json) | python -m json.tool || {
  echo "WARN: diag.json non lisible. Extraction complète vers .ci-logs/_extracted"
  mkdir -p .ci-logs/_extracted
  tar -xzf "$TGZ" -C .ci-logs/_extracted || true
  ls -la .ci-logs/_extracted || true
}

say "Terminé — la fenêtre RESTE OUVERTE"
pause
