#!/usr/bin/env bash
# Housekeeping robuste qui ne ferme jamais la fenêtre automatiquement.
set -uo pipefail
mkdir -p _tmp
LOG="_tmp/housekeeping.safe.log"

ts() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }
log() { echo "[$(ts)] $*" | tee -a "$LOG"; }

trap 'st=$?; echo | tee -a "$LOG"; log "END status=$st — log: $LOG"; read -rp "Appuyez sur Entrée pour quitter..."; exit $st' EXIT

log "== housekeeping_safe_noclose.sh: start =="

# 1) normalisation .gitignore
log "normalize .gitignore"
{
  echo ""
  echo "# --- housekeeping (auto) ---"
  echo "_tmp/"
  echo "_tmp-figs/"
  echo "nano.*.save"
  echo "*.swp"
  echo "*~"
  echo "._*"
  echo "zz-manifests/manifest_master.backfilled*.json"
  echo "_archives_preclean/"
  echo "_attic_untracked/"
} >> .gitignore
awk '!a[$0]++' .gitignore > .gitignore.tmp && mv .gitignore.tmp .gitignore
log ".gitignore updated (deduped)"

# 2) ranger les non-suivis (compte simple par préfixe)
log "move untracked to safe places"
mkdir -p _attic_untracked tools
moved=0; skipped=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  echo "$line" | tee -a "$LOG"
  if [[ "$line" == MOVED:* ]]; then
    moved=$((moved+1))
  elif [[ "$line" == SKIP:* ]]; then
    skipped=$((skipped+1))
  fi
done < <(bash tools/_safe_move_untracked.sh)
log "SUMMARY moved=$moved skipped=$skipped"

# 3) audit
log "running audit"
./tools/audit_manifest_files.sh --all | tee -a "$LOG"

# 4) diag (warnings tolérés)
log "running diag (warnings tolerated)"
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check \
  > _tmp/diag_housekeeping.json 2>&1 || true
head -n 200 _tmp/diag_housekeeping.json | tee -a "$LOG"

# 5) tests (tolérant)
log "running pytest (tolerant)"
pytest -q | tee -a "$LOG" || true

# 6) état git
log "checking git status"
git status --porcelain | tee -a "$LOG"

log "== housekeeping_safe_noclose.sh: done =="
