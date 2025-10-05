#!/usr/bin/env bash
set -euo pipefail
# Petite lib de pause robuste pour scripts tools/*
# Usage: . tools/lib_psx.sh && psx_install "nom_du_script"
psx_install() {
  : "${WAIT_ON_EXIT:=1}"
  _PSX_NAME="${1:-script}"
  _psx__pause() {
    rc=$?
    echo
    if [ "$rc" -eq 0 ]; then
      echo "✅ ${_PSX_NAME} — Terminé (exit: $rc)"
    else
      echo "❌ ${_PSX_NAME} — Terminé (exit: $rc)"
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
  trap '_psx__pause' EXIT
}
