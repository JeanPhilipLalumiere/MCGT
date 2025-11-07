#!/usr/bin/env bash
# tools/sourcing_probe.bash — LIGHT: log des includes seulement
set -Eeuo pipefail
_log="${MCGT_SOURCING_LOG:-zz-out/trace_sourcing_$(date +%Y%m%dT%H%M%S).log}"
mkdir -p "${_log%/*}"

# entête 1x
if [[ -z "${_PROBE_INITIALIZED:-}" ]]; then
  export _PROBE_INITIALIZED=1
  printf '[%(%F %T)T] pid=%s ppid=%s PWD=%s argv0=%s (LIGHT)\n' -1 "$$" "$PPID" "$PWD" "$0" >>"$_log"
fi

# DEBUG trap : détecte seulement "source …" ou ". …"
trap 'cmd=$BASH_COMMAND
      case "$cmd" in
        source\ *|.\ *) printf "[%(%F %T)T] INCLUDE -> %s (from %s:%s)\n" -1 \
                         "$cmd" "${BASH_SOURCE[1]-<none>}" "${BASH_LINENO[0]-0}" >>"$_log" ;;
      esac' DEBUG
