#!/usr/bin/env bash
# Diagnostic amélioré : remonte output.text + annotations du check "validate"
# Fenêtre RESTE OUVERTE

set -u -o pipefail

WF_PATH=".github/workflows/publish_testonly.yml"
FIXBR="ci/testpypi-workflow-rmid"
WF_ID_FALLBACK="193389332"

log(){ printf "\n== %s ==\n" "$*"; }
warn(){ printf "WARN: %s\n" "$*" >&2; }

final_loop(){
  echo
  echo "==============================================================="
  echo " Fin (diagnostic) — fenêtre OUVERTE. [Entrée]=quitter  [sh]=shell "
  echo "==============================================================="
  while true; do read -r -p "> " a || true; case "${a:-}" in
    sh) /bin/bash -i;;
    "") break;;
    *) echo "?";;
  esac; done
}

repo(){
  local r url
  r="$(git remote 2>/dev/null | head -n1 || true)"
  url="$(git remote get-url "${r:-origin}" 2>/dev/null || true)"
  if [[ "$url" =~ github.com[:/]+([^/]+)/([^/.]+) ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  else
    echo "JeanPhilipLalumiere/MCGT"
  fi
}
GH_REPO="$(repo)"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 requis"; final_loop; exit 0; }; }
need gh; need jq

get_wfid(){ gh workflow view "$WF_PATH" -R "$GH_REPO" --json databaseId -q .databaseId 2>/dev/null || echo "$WF_ID_FALLBACK"; }

log "Cherche le dernier run en échec (failure) pour $WF_PATH ($FIXBR)"
WFID="$(get_wfid)"; echo "Workflow ID: $WFID"
runs_json="$(gh run list --workflow "$WFID" -R "$GH_REPO" --limit 50 \
  --json databaseId,headSha,headBranch,createdAt,status,conclusion,event 2>/dev/null || echo "[]")"

echo "$runs_json" | jq -r 'map(select(.conclusion=="failure")) | sort_by(.createdAt)| reverse | .[0] // empty' > .diag_last_failed.json
if [ ! -s .diag_last_failed.json ]; then
  warn "Aucun run 'failure' récent trouvé."
  echo "$runs_json" | jq -r '.[]|@json' || true
  final_loop; exit 0
fi

RUN_ID="$(jq -r '.databaseId' .diag_last_failed.json)"
HEAD_SHA="$(jq -r '.headSha' .diag_last_failed.json)"
HEAD_BRANCH="$(jq -r '.headBranch' .diag_last_failed.json)"
echo "RUN_ID: $RUN_ID"
echo "HEAD_SHA: $HEAD_SHA"
echo "HEAD_BRANCH: $HEAD_BRANCH"

log "Jobs présents ? (si non => échec de validation du YAML)"
jobs="$(gh run view "$RUN_ID" -R "$GH_REPO" --json jobs -q '.jobs' 2>/dev/null || echo '[]')"
if echo "$jobs" | jq -e 'length>0' >/dev/null 2>&1; then
  echo "(Des jobs existent) — voici les logs :"
  gh run view "$RUN_ID" -R "$GH_REPO" --log || true
  final_loop; exit 0
fi
echo "(Aucun job — validation du workflow a échoué avant exécution)"

log "Check-suites pour le commit (github-actions)…"
suites="$(gh api -H "Accept: application/vnd.github+json" "/repos/$GH_REPO/commits/$HEAD_SHA/check-suites" 2>/dev/null || echo '{}')"
suite_ids="$(echo "$suites" | jq -r '.check_suites[] | select(.app.slug=="github-actions") | .id' 2>/dev/null || true)"

found=0
for sid in $suite_ids; do
  echo; echo "-- Check runs de la suite $sid --"
  runs="$(gh api -H "Accept: application/vnd.github+json" "/repos/$GH_REPO/check-suites/$sid/check-runs" 2>/dev/null || echo '{}')"
  echo "$runs" | jq -r '.check_runs[] | {id, name, status, conclusion, details_url} | @json' || true

  echo "$runs" | jq -r '.check_runs[] | select(.app.slug=="github-actions") | .id' | while read -r crid; do
    echo; echo "### Check-run $crid — détails"
    cr="$(gh api -H "Accept: application/vnd.github+json" "/repos/$GH_REPO/check-runs/$crid" 2>/dev/null || echo '{}')"
    echo "$cr" | jq -r '"name=\(.name) status=\(.status) conclusion=\(.conclusion)\ndetails=\(.details_url // "")\n--- output.title ---\n\(.output.title // "(no title)")\n--- output.summary ---\n\(.output.summary // "(no summary)")\n--- output.text ---\n\(.output.text // "(no text)")\n"' || true

    ann_url="$(echo "$cr" | jq -r '.output.annotations_url // empty')"
    if [ -n "$ann_url" ]; then
      echo "-- annotations --"
      anns="$(gh api -H "Accept: application/vnd.github+json" "$ann_url" 2>/dev/null || echo '[]')"
      echo "$anns" | jq -r '.[] | "file:\(.path) L\(.start_line)-L\(.end_line) | \(.annotation_level) | \(.message)"' || true
    fi
    found=1
  done
done

if [ "$found" -eq 0 ]; then
  warn "Pas de check-run github-actions exploitable (output vide). Réessaie plus tard."
fi

final_loop
