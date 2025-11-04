#!/usr/bin/env bash
# Orchestration d'une passe complète de nettoyage/ajout/validation.
set -euo pipefail

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/cleanup_round.$TS.log"
say(){ echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG"; }

say "== cleanup_round: start =="

# 1) Planifier/rafraîchir les listes de candidats si dispo
if [[ -x tools/plan_next_cleanup.sh ]]; then
  say "[plan] rafraîchir candidats"
  bash tools/plan_next_cleanup.sh | tee -a "$LOG"
else
  say "[plan] SKIP (tools/plan_next_cleanup.sh introuvable)"
fi

# 2) Reclasser les 'unclassified' -> proposed_*
if [[ -x tools/auto_classify_unclassified.sh ]]; then
  say "[classify] auto_classify_unclassified"
  bash tools/auto_classify_unclassified.sh | tee -a "$LOG"
else
  say "[classify] SKIP (tools/auto_classify_unclassified.sh introuvable)"
fi

# 3) (optionnel) Appliquer .gitignore si un proposed_ignore est présent
LAST_PROP_IGN=$(ls -1 _tmp/proposed_ignore.*.txt 2>/dev/null | sort | tail -n1 || true)
if [[ -n "${LAST_PROP_IGN}" ]]; then
  say "[ignore] appliquer .gitignore depuis ${LAST_PROP_IGN}"
  APPLY_IGNORE=1 IGN_IN="${LAST_PROP_IGN}" bash tools/apply_candidates.sh | tee -a "$LOG"
else
  say "[ignore] SKIP (aucun _tmp/proposed_ignore.*.txt)"
fi

# 4) Boucle d'ajout par lots jusqu'à épuisement
ROUND=0
while :; do
  ((ROUND++)) || true
  say "[batch ${ROUND}] apply_add_list (BATCH=50, APPLY=1)"

  OUT_LOG="_tmp/apply_add.${TS}.round${ROUND}.log"
  BATCH=50 APPLY=1 bash tools/manifest_apply_add_list.sh | tee "$OUT_LOG" | tee -a "$LOG"

  ADDED=$(grep -Eo '^ADDED:[0-9]+' "$OUT_LOG" | head -n1 | cut -d: -f2 || echo "0")
  say "[batch ${ROUND}] ADDED=${ADDED}"

  # Corriger les git_hash découverts par diag
  bash tools/manifest_fix_git_hash_from_diag.sh | tee -a "$LOG"

  # Sceller (audit/diag strict/tests + tag)
  bash tools/manifest_seal.sh | tee -a "$LOG"

  # Arrêt si plus rien à ajouter
  [[ "${ADDED}" == "0" ]] && { say "[batch ${ROUND}] nothing more to add — stop"; break; }
done

say "== cleanup_round: done =="
