#!/usr/bin/env bash
# apply_attic_round2_guarded.sh — applique les déplacements vers attic/ depuis le dernier checkpoint (guardé)
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs attic
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/apply_attic_${TS}.log"

echo "[INFO] Recherche du dernier attic_candidates.txt" | tee -a "$LOG"
LAST_DIR="$(ls -1d _tmp/round2_checkpoint_* 2>/dev/null | sort -r | head -n1 || true)"
CAND="${LAST_DIR:+$LAST_DIR/attic_candidates.txt}"
if [[ -z "${LAST_DIR:-}" || ! -s "${CAND:-/dev/null}" ]]; then
  echo "[ERR] Aucune liste attic_candidates.txt trouvée. Lance d'abord: bash round2_checkpoint_robuste.sh" | tee -a "$LOG"
  read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true
  exit 2
fi

echo "[INFO] Liste détectée: $CAND" | tee -a "$LOG"
CNT="$(wc -l < "$CAND" | tr -d ' ')"
echo "[INFO] $CNT candidats 'attic/'" | tee -a "$LOG"

echo "[DRY-RUN] Aperçu des 50 premiers chemins:" | tee -a "$LOG"
head -n 50 "$CAND" | sed 's/^/  - /' | tee -a "$LOG"

if [[ "${APPLY:-0}" != "1" ]]; then
  echo
  echo "[HINT] Rien n'a été déplacé (dry-run). Pour appliquer:"
  echo "  APPLY=1 bash apply_attic_round2_guarded.sh"
  read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true
  exit 0
fi

echo "[APPLY] Création branche: chore/attic-round2-${TS}" | tee -a "$LOG"
git switch -c "chore/attic-round2-${TS}" >/dev/null

# Déplacements en conservant arborescence: attic/<path>
moved=0
while IFS= read -r p; do
  [[ -z "$p" ]] && continue
  [[ ! -e "$p" ]] && { echo "[WARN] ignore (n’existe pas): $p" | tee -a "$LOG"; continue; }
  dest="attic/$p"
  mkdir -p "$(dirname "$dest")"
  git mv -k "$p" "$dest" 2>>"$LOG" || { echo "[WARN] git mv a échoué, tentative mv+add" | tee -a "$LOG"; mkdir -p "$(dirname "$dest")"; mv "$p" "$dest"; git add -A "$dest"; git rm -f --cached "$p" 2>/dev/null || true; }
  moved=$((moved+1))
done < "$CAND"

echo "[INFO] Déplacés: $moved" | tee -a "$LOG"
git add -A
git commit -m "round2(attic): move ${moved} items from checkpoint ${LAST_DIR##*_}" >/dev/null

echo "[PUSH] & PR…" | tee -a "$LOG"
git push -u origin HEAD >/dev/null
gh pr create --fill >/dev/null || true

echo "[DONE] PR ouverte. Vérifie l’aperçu sur GitHub, puis merge suivant la policy." | tee -a "$LOG"
read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true
