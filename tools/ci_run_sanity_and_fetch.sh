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
  log "WARN: run ${RID} terminé en failure (on continue pour récupérer logs/artefacts)"
fi

log "Sauvegarde logs -> ${RUN_DIR}/run.log"
gh run view "${RID}" --log > "${RUN_DIR}/run.log" || log "WARN: impossible de sauvegarder les logs"

log "Téléchargement des artefacts (nom: sanity-diag) -> ${RUN_DIR}/artifacts"
if ! gh run download "${RID}" -n sanity-diag -D "${RUN_DIR}/artifacts"; then
  log "WARN: download par nom KO; tentative full download"
  gh run download "${RID}" -D "${RUN_DIR}/artifacts" || log "WARN: Aucun artefact téléchargé"
fi

log "Inventaire des .tgz"
find "${RUN_DIR}/artifacts" -maxdepth 3 -type f -name '*.tgz' -print | tee "${RUN_DIR}/artifacts/_list.txt" || true

PKG="$(grep -m1 'sanity-diag.tgz' "${RUN_DIR}/artifacts/_list.txt" || true)"
if [[ -n "${PKG}" && -f "${PKG}" ]]; then
  EXTRACT_DIR="${RUN_DIR}/extracted"
  mkdir -p "${EXTRACT_DIR}"
  tar xzf "${PKG}" -C "${EXTRACT_DIR}"
  if [[ -f "${EXTRACT_DIR}/sanity-diag/diag.json" ]]; then
    log "Affichage diag.json"
    if command -v jq >/dev/null 2>&1; then
      jq . "${EXTRACT_DIR}/sanity-diag/diag.json"
    else
      cat "${EXTRACT_DIR}/sanity-diag/diag.json"
    fi
  else
    log "WARN: diag.json manquant après extraction"
  fi
else
  log "WARN: paquet sanity-diag.tgz non trouvé"
fi

log "DONE"
