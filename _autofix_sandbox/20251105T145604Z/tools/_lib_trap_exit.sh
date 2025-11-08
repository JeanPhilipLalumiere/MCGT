#!/usr/bin/env bash
set -Eeuo pipefail

# mcgt_install_exit_trap <logfile>
mcgt_install_exit_trap () {
  export MCGT_TRAP_LOG="${1:-/dev/null}"
  # Utilise une variable d’environnement: pas de variable locale volatilisée
  trap 'ec=$?; echo; echo "== Fin (code: $ec) =="; echo "Log: ${MCGT_TRAP_LOG:-/dev/null}"' EXIT
}
