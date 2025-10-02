#!/usr/bin/env bash
# shellcheck disable=SC2015
#!/usr/bin/env bash
###############################################################################
# 8) Trigger + fetch diag pour sanity-main.yml
#    - REST workflow_dispatch -> fallback commit vide (push)
#    - Watch + download artifact + affiche diag.json
###############################################################################
set +e
STAMP="$(date +%Y%m%dT%H%M%S)"
ROOT_LOG=".ci-logs/trigger-fetch-$STAMP.log"
exec > >(tee -a "$ROOT_LOG") 2>&1
say() { printf "\n== %s ==\n" "$*"; }
pause() {
  printf "\n(Pause) Entrée pour continuer… "
  read -r _ || true
}

WF="sanity-main.yml"
ART="sanity-diag"

command -v gh >/dev/null 2>&1 || {
  echo "✘ gh manquant"
  pause
  exit 2
}
[ -d .git ] || {
  echo "✘ Pas de dépôt git"
  pause
  exit 2
}

say "Dispatch REST ($WF -> main)"
if gh api repos/:owner/:repo/actions/workflows/"$WF"/dispatches --method POST -f ref=main 2>&1; then
  echo "OK: workflow_dispatch envoyé."
else
  echo "WARN: REST dispatch a échoué — fallback push vide."
  git commit --allow-empty -m "ci(sanity-main): manual retrigger $STAMP" --no-verify && git push || true
fi

say "Récupération du dernier run ($WF)"
RID="$(gh run list --workflow "$WF" -L1 --json databaseId -q '.[0].databaseId' 2>/dev/null)"
echo "Run id: ${RID:-<indisponible>}"

if [ -n "$RID" ]; then
  say "Watch du run $RID"
  gh run watch "$RID" --exit-status || true

  say "Téléchargement logs & artifacts"
  mkdir -p .ci-logs/"${WF%.yml}"-artifacts
  gh run view "$RID" --log >.ci-logs/"${WF%.yml}".full.log 2>/dev/null || true
  gh run download "$RID" --dir .ci-logs/"${WF%.yml}"-artifacts || true

  echo
  say "Inspection de l'artifact"
  TGZ="$(find .ci-logs -type f -path "*${ART}/*" -name '*.tgz' | head -n1)"
  echo "TGZ=$TGZ"
  if [ -n "$TGZ" ] && [ -f "$TGZ" ]; then
    echo "-- Liste dans l'archive --"
    tar -tzf "$TGZ" || true
    echo "-- diag.json (pretty) --"
    (tar -xOzf "$TGZ" ./diag.json 2>/dev/null || tar -xOzf "$TGZ" diag.json) | python -m json.tool || true
  else
    echo "WARN: artifact $ART non trouvé"
  fi
else
  echo "WARN: pas de run détecté (index GitHub lent ?)."
fi
say "Terminé"
pause
