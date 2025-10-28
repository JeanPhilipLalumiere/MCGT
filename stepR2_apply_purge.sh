#!/usr/bin/env bash
# File: stepR2_apply_purge.sh
# Applique purge_plan_dryrun.txt : move vers attic par défaut (sécuritaire), option --delete pour supprimer.
set -Euo pipefail

MODE="${1:-move}"   # move|delete
PLAN="purge_plan_dryrun.txt"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ATTIC="_attic_untracked/round2/${STAMP}"

test -f "$PLAN" || { echo "[ERR] plan introuvable: $PLAN (exécute d'abord stepR2_build_and_preview.sh)"; exit 2; }

case "$MODE" in
  move)
    echo "[INFO] Déplacement vers ${ATTIC}…"
    mkdir -p "$ATTIC"
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      [ -e "$p" ] || continue
      dest="${ATTIC}/${p}"
      mkdir -p "$(dirname "$dest")"
      git mv -f "$p" "$dest" 2>/dev/null || { mkdir -p "$(dirname "$dest")"; mv -f "$p" "$dest"; }
    done < "$PLAN"
    echo "[OK] Déplacé. Tu peux réviser puis commit."
    ;;
  delete)
    echo "[WARN] Suppression définitive…"
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      [ -e "$p" ] || continue
      git rm -f "$p" 2>/dev/null || rm -rf -- "$p"
    done < "$PLAN"
    echo "[OK] Supprimé. Pense à commit."
    ;;
  *)
    echo "[ERR] MODE invalide: $MODE (attendu: move|delete)"; exit 2;;
esac
