#!/usr/bin/env bash
# Affiche le diag.json du **dernier run terminé** de sanity-main (success en priorité)

set -euo pipefail
log(){ printf "[%(%F %T)T] %s\n" -1 "$*"; }

command -v gh >/dev/null 2>&1 || { echo "ERR: gh introuvable"; exit 1; }

log "Recherche du dernier run (success d'abord, sinon dernier terminé)"
RID="$(gh run list --workflow sanity-main.yml --json databaseId,status,conclusion,createdAt \
      --limit 20 -q '[.[] | select(.status=="completed")] | sort_by(.createdAt) | reverse | .[0].databaseId')"
[[ -n "${RID:-}" ]] || { echo "ERR: aucun run trouvé"; exit 1; }
log "Run sélectionné: ${RID}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

log "Téléchargement artefacts -> $TMPDIR"
if ! gh run download "${RID}" -n sanity-diag -D "$TMPDIR"; then
  gh run download "${RID}" -D "$TMPDIR" || true
fi

ART_DIR="$TMPDIR/sanity-diag"
[[ -d "$ART_DIR" ]] || ART_DIR="$TMPDIR"

if [[ -f "$ART_DIR/diag.json" ]]; then
  log "diag.json :"
  if command -v jq >/dev/null 2>&1; then jq . "$ART_DIR/diag.json"; else cat "$ART_DIR/diag.json"; fi
else
  log "WARN: diag.json introuvable dans $ART_DIR"
  find "$TMPDIR" -maxdepth 3 -type f -print
fi
