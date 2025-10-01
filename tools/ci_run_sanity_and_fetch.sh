#!/usr/bin/env bash
# tools/ci_run_sanity_and_fetch.sh
# Déclenche sanity-main.yml, attend la fin, télécharge artefacts, affiche diag.json

set -euo pipefail

STAMP="$(date +%Y%m%dT%H%M%S)"
RUN_DIR_BASE=".ci-logs/runs"
mkdir -p "$RUN_DIR_BASE"

log(){ printf "[%(%F %T)T] %s\n" -1 "$*"; }
need(){ command -v "$1" >/dev/null 2>&1 || { log "ERR: '$1' introuvable"; exit 1; }; }

need gh

log "Trigger workflow_dispatch (sanity-main.yml -> main)"
gh workflow run sanity-main.yml -r main

log "Récupération dernier run id (sanity-main.yml)"
RID="$(gh run list --workflow sanity-main.yml --limit 1 --json databaseId -q '.[0].databaseId' | tr -d '\n')"
if [[ -z "${RID:-}" ]]; then
  log "ERR: Impossible d'obtenir un run id"; exit 1
fi

RUN_DIR="${RUN_DIR_BASE}/${RID}-${STAMP}"
mkdir -p "${RUN_DIR}/artifacts"

log "Watch du run: ${RID}"
if gh run watch --exit-status "${RID}"; then
  log "Run ${RID} terminé: success"
else
  log "WARN: run ${RID} terminé en failure (on tente quand même de récupérer logs/artifacts)"
fi

log "Sauvegarde logs -> ${RUN_DIR}/run.log"
gh run view "${RID}" --log > "${RUN_DIR}/run.log" || log "WARN: impossible de sauvegarder les logs"

log "Téléchargement des artefacts (nom: sanity-diag) -> ${RUN_DIR}/artifacts"
if ! gh run download "${RID}" -n sanity-diag -D "${RUN_DIR}/artifacts"; then
  log "WARN: download par nom KO; tentative full download"
  gh run download "${RID}" -D "${RUN_DIR}/artifacts" || log "WARN: Aucun artefact téléchargé"
fi

# Normalement, gh place les fichiers sous ${RUN_DIR}/artifacts/sanity-diag/
ART_DIR="${RUN_DIR}/artifacts/sanity-diag"
[[ -d "${ART_DIR}" ]] || ART_DIR="${RUN_DIR}/artifacts"  # fallback

log "Inventaire des fichiers artefacts"
find "${RUN_DIR}/artifacts" -maxdepth 3 -type f -print | tee "${RUN_DIR}/artifacts/_list.txt" || true

if [[ -f "${ART_DIR}/diag.json" ]]; then
  log "Affichage diag.json"
  if command -v jq >/dev/null 2>&1; then
    jq . "${ART_DIR}/diag.json"
  else
    cat "${ART_DIR}/diag.json"
  fi
else
  log "WARN: diag.json introuvable dans ${ART_DIR}"
fi

log "DONE"
