#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
# tools/ci_run_sanity_and_fetch.sh
# Déclenche sanity-main.yml, attend la fin, télécharge artefacts, affiche diag.json

set -euo pipefail

STAMP="$(date +%Y%m%dT%H%M%S)"
RUN_DIR_BASE=".ci-logs/runs"
mkdir -p "$RUN_DIR_BASE"

log() { printf "[%(%F %T)T] %s\n" -1 "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || {
  log "ERR: '$1' introuvable"
  exit 1
}; }

need gh

log "Trigger workflow_dispatch (sanity-main.yml -> main)"
gh workflow run sanity-main.yml -r main

# Laisse à GitHub 2-3 secondes pour enregistrer le run
sleep 3

log "Récupération dernier run id (sanity-main.yml, branch=main)"
RID="$(
  gh run list \
    --workflow sanity-main.yml \
    --branch main \
    --limit 10 \
    --json databaseId,createdAt \
    -q 'sort_by(.createdAt) | last | .databaseId' | tr -d '\n'
)"
if [[ -z "${RID:-}" ]]; then
  log "ERR: Impossible d'obtenir un run id"
  exit 1
fi

RUN_DIR="${RUN_DIR_BASE}/${RID}-${STAMP}"
mkdir -p "${RUN_DIR}/artifacts"

log "Watch du run: ${RID}"
if gh run watch --exit-status "${RID}"; then
  log "Run ${RID} terminé: success"
else
  log "WARN: run ${RID} non-success (on continue pour récupérer logs/artefacts)"
fi

log "Sauvegarde logs -> ${RUN_DIR}/run.log"
gh run view "${RID}" --log >"${RUN_DIR}/run.log" || true

log "Téléchargement des artefacts (nom: sanity-diag) -> ${RUN_DIR}/artifacts"
if ! gh run download "${RID}" -n sanity-diag -D "${RUN_DIR}/artifacts"; then
  log "WARN: download par nom KO; tentative full download"
  gh run download "${RID}" -D "${RUN_DIR}/artifacts" || true
fi

log "Inventaire des fichiers artefacts"
# Important: -maxdepth AVANT -type, pas de sed qui double le chemin
find "${RUN_DIR}/artifacts" -maxdepth 2 -type f -print |
  tee "${RUN_DIR}/artifacts/_list.txt" || true

# diag.json peut être à la racine d'artifacts/ ou dans un sous-dossier
CANDIDATES=()
while IFS= read -r f; do CANDIDATES+=("$f"); done < <(grep -E '/?diag\.json$' "${RUN_DIR}/artifacts/_list.txt" || true)

if [[ ${#CANDIDATES[@]} -gt 0 && -f "${CANDIDATES[0]}" ]]; then
  DJ="${CANDIDATES[0]}"
  log "Affichage ${DJ}"
  if command -v jq >/dev/null 2>&1; then jq . "${DJ}"; else cat "${DJ}"; fi
else
  log "WARN: diag.json non trouvé"
fi

log "DONE"
