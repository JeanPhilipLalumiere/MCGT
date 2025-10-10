#!/usr/bin/env bash
set -Eeo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

TS="$(date -u +%Y%m%d_%H%M%S)"
LOG=".ci-logs/guard_local_${TS}.log"

# Duplique stdout/err vers un log
exec > >(tee -a "$LOG") 2>&1

# --- Garde-fou anti-fermeture ---
on_exit() {
  ec=$?
  echo
  echo "== Fin (code: $ec) =="
  echo "Log: $LOG"
  if [ -z "${MCGT_NO_SHELL_DROP:-}" ]; then
    echo
    echo "Ouverture d'un shell interactif (anti-fermeture)."
    echo "Pour quitter: 'exit' ou Ctrl+D."
    if command -v "${SHELL:-bash}" >/dev/null 2>&1; then
      exec "${SHELL:-bash}" -i
    elif command -v bash >/dev/null 2>&1; then
      exec bash -i
    else
      echo "Aucun shell trouvé, maintien de la session (Ctrl+C pour fermer)."
      tail -f /dev/null
    fi
  fi
}
trap on_exit EXIT

echo ">> run guard via tools/ci_step2_figures_guard.sh"
bash tools/ci_step2_figures_guard.sh
