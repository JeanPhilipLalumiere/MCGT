#!/usr/bin/env bash
set -euo pipefail
# tools/lib_psx.sh — Pause robuste pour fenêtres GUI
# Usage :
#   . tools/lib_psx.sh
#   psx_install "Étape N — Description"

: "${WAIT_ON_EXIT:=1}"
psx__label="(étape)"

psx_install() {
  psx__label="${1:-$psx__label}"
  trap 'psx__pause' EXIT
}

psx__pause() {
  rc=$?
  echo
  if [ "$rc" -eq 0 ]; then
    echo "✅ ${psx__label} — Terminé (exit: $rc)"
  else
    echo "❌ ${psx__label} — Terminé (exit: $rc)"
  fi
  if [ "${WAIT_ON_EXIT}" = "1" ] && [ -z "${CI:-}" ]; then
    if [ -r /dev/tty ]; then
      printf "PSX — Appuie sur Entrée pour fermer cette fenêtre…" > /dev/tty
      IFS= read -r _ < /dev/tty
      printf "\n" > /dev/tty
    elif [ -t 0 ]; then
      read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
      echo
    else
      echo "PSX — Aucun TTY détecté; la fenêtre restera ouverte (Ctrl+C pour fermer)."
      tail -f /dev/null
    fi
  fi
}
