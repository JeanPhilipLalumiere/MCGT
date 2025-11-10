#!/usr/bin/env bash
set -Eeuo pipefail

WF_LIST=("guard-ignore-and-sdist.yml" "readme-guard.yml" "manifest-guard.yml")
REF="${1:-release/zz-tools-0.3.1}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG=".ci-out/rerun_ci_ref_SAFE_${TS}.log"
mkdir -p .ci-out

prompt_hold(){ if [ -t 0 ]; then echo "────────────────────────────────"; read -rp "Appuie sur Entrée pour fermer ce script..."; fi; }
log(){ echo -e "$@" | tee -a "$LOG"; }
on_err(){ code=$?; log "\n[ERREUR] Code=$code — vois $LOG"; prompt_hold; exit "$code"; }
trap on_err ERR

log "[INFO] Début : $TS (UTC)"
log "[CTX] Repo : $(pwd)"
log "[CTX] Ref  : $REF"

SHA="$(git rev-parse "$REF^{commit}" 2>/dev/null || true)"
[ -n "${SHA:-}" ] && log "[CTX] SHA  : ${SHA:0:12}"

log "\n[RUN] Dispatch workflows"
for wf in "${WF_LIST[@]}"; do
  if gh workflow run "$wf" --ref "$REF" >>"$LOG" 2>&1; then
    log "[OK] dispatch $wf"
  else
    log "[WARN] dispatch a échoué pour $wf (voir log)."
  fi
done

have_jq=0; command -v jq >/dev/null 2>&1 && have_jq=1

# Retourne l'ID du run le plus récent lié à la ref (priorité au SHA exact si dispo)
find_run_id(){
  local wf="$1" id=""
  if [ $have_jq -eq 1 ] && [ -n "$SHA" ]; then
    id="$(gh run list --workflow="$wf" --limit 20 --json databaseId,headSha \
         -q "map(select(.headSha==\"$SHA\")) | .[0].databaseId" 2>/dev/null || true)"
  else
    id="$(gh run list --workflow="$wf" --branch "$REF" --limit 1 --json databaseId \
         -q '.[0].databaseId' 2>/dev/null || true)"
  fi
  echo "${id:-}"
}

# Attend la fin d’un run et renvoie son id et sa conclusion
wait_one(){
  local wf="$1" id tries=0
  while [ $tries -lt 40 ]; do
    id="$(find_run_id "$wf")"
    [ -n "$id" ] && break
    sleep 3; tries=$((tries+1))
  done
  if [ -z "${id:-}" ]; then log "[WARN] Aucun run trouvé pour $wf"; return 0; fi
  log "[INFO] Suivi $wf (run #$id)"
  local timeout=900 step=10 waited=0 status="" conc=""
  while true; do
    if [ $have_jq -eq 1 ]; then
      read -r status conc <<<"$(gh run view "$id" --json status,conclusion -q '[.status,.conclusion] | @tsv' 2>/dev/null || echo -e 'unknown\tunknown')"
    else
      status="$(gh run view "$id" 2>/dev/null | awk -F': ' '/Status/{print $2; exit}')"
      conc="$(gh run view "$id" 2>/dev/null | awk -F': ' '/Conclusion/{print $2; exit}')"
    fi
    log "  - $wf: status=${status:-?} conclusion=${conc:-?} (t=${waited}s)"
    [ "${status:-}" = "completed" ] && break
    sleep "$step"; waited=$((waited+step))
    [ $waited -ge $timeout ] && { log "[WARN] Timeout $wf après ${timeout}s"; break; }
  done

  # Dump logs si échec
  if [ "${conc:-}" = "failure" ] || [ "${conc:-}" = "cancelled" ]; then
    local out=".ci-out/${wf%.yml}_${id}.log"
    log "  - Récupération des logs → $out"
    gh run view "$id" --log > "$out" 2>&1 || true
  fi

  # Stocke un résumé JSON minimal par run
  if [ $have_jq -eq 1 ]; then
    gh run view "$id" --json databaseId,name,workflowName,status,conclusion,headBranch,headSha,url \
      | jq '.' > ".ci-out/${wf%.yml}_${id}.json" 2>/dev/null || true
  fi
}

log "\n[WAIT] Surveillance des runs…"
for wf in "${WF_LIST[@]}"; do wait_one "$wf"; done

log "\n[SUMMARY]"
if [ $have_jq -eq 1 ]; then
  for wf in "${WF_LIST[@]}"; do
    gh run list --workflow="$wf" --limit 1 \
      --json name,status,conclusion,headBranch,headSha,url \
      | jq -r '.[] | "\(.name) — \(.status)/\(.conclusion) — \(.headBranch) — \(.headSha[0:12]) — \(.url)"' \
      | tee -a "$LOG"
  done
else
  for wf in "${WF_LIST[@]}"; do gh run list --workflow="$wf" --limit 1 | tee -a "$LOG"; done
fi

log "\n[HINT] Logs d’échec (si présents) dans .ci-out/*.log"
log "[FIN] Log : $LOG"
prompt_hold
