#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <commande ...>" >&2
  exit 2
fi
_cmd=( "$@" )

# Neutralise toute injection
unset BASH_ENV ENV
export BASH_ENV=/dev/null ENV=

# Exécute en environnement minimal
if [[ "${_cmd[0]}" == *.py ]]; then
  set +e
  env -i \
    PATH="${PATH}" HOME="${HOME}" \
    LANG="${LANG:-C}" LC_ALL="${LC_ALL:-C}" \
    MPLBACKEND=Agg \
    BASH_ENV=/dev/null ENV= \
    python3 "${_cmd[@]}"
  status=$?
  set -e
else
  # Sans profils ni rc => pas de sourcing "environment"
  quoted_cmd=$(printf '%q ' "${_cmd[@]}")
  set +e
  env -i \
    PATH="${PATH}" HOME="${HOME}" \
    LANG="${LANG:-C}" LC_ALL="${LC_ALL:-C}" \
    MPLBACKEND=Agg \
    BASH_ENV=/dev/null ENV= \
    bash --noprofile --norc -c "$quoted_cmd"
  status=$?
  set -e
fi

# Pause anti-fermeture (sauf CI ou si désactivée)
if [[ -t 1 && -z "${CI:-}" && "${MCGT_NO_PAUSE:-0}" != "1" ]]; then
  echo
  read -r -p "✔ Terminé (code=${status}). Appuyez sur Entrée pour fermer… " _
fi
exit "${status}"
