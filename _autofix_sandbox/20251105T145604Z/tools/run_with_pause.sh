#!/usr/bin/env bash
set -euo pipefail

pause_guard() {
  local code="${1:-0}"
  [[ "${MCGT_NO_PAUSE:-}" == "1" ]] && return 0

  if [[ "$code" -eq 0 ]]; then
    echo "✔ Terminé (code=${code})."
  else
    echo "✖ Terminé avec erreurs (code=${code})."
  fi

  # 1) TTY direct
  if [[ -t 0 ]]; then
    read -r -p "Appuyez sur Entrée pour fermer… " _
    return 0
  fi
  # 2) /dev/tty
  if [[ -r /dev/tty ]]; then
    printf "%s" "Appuyez sur Entrée pour fermer… " > /dev/tty || true
    IFS= read -r _ < /dev/tty || true
    return 0
  fi
  # 3) /dev/console
  if [[ -r /dev/console ]]; then
    printf "%s" "Appuyez sur Entrée pour fermer… " > /dev/console || true
    IFS= read -r _ < /dev/console || true
    return 0
  fi

  # 4) Fallback : garder la fenêtre ouverte
  echo "⚠ Aucun TTY détecté. Fenêtre maintenue ouverte (Ctrl+C pour quitter)."
  tmpfifo="$(mktemp -u)"; mkfifo "$tmpfifo" 2>/dev/null || true
  tail -f "$tmpfifo" 2>/dev/null || sleep 999999
}

# Neutralise toute injection d'init bash
unset BASH_ENV ENV
export BASH_ENV=/dev/null ENV=

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <commande ...>" >&2
  exit 2
fi

__exit_trap() { local rc=$?; pause_guard "$rc"; exit "$rc"; }
trap __exit_trap EXIT

_cmd=( "$@" )

common_env=( env -i
  PATH="${PATH}" HOME="${HOME}"
  LANG="${LANG:-C}" LC_ALL="${LC_ALL:-C}"
  MPLBACKEND=Agg
  BASH_ENV=/dev/null ENV=
)

# .py : exécuter Python directement (pas de bash)
if [[ "${_cmd[0]}" == *.py ]]; then
  "${common_env[@]}" python3 "${_cmd[@]}"
else
  # autre : bash sans profils/rc
  quoted_cmd=$(printf '%q ' "${_cmd[@]}")
  "${common_env[@]}" bash --noprofile --norc -lc "${quoted_cmd}"
fi
