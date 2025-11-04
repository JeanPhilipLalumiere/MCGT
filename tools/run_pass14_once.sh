#!/usr/bin/env bash
# Lance PASS14 une fois, avec shims robustes, log live, timeout et garde-fou fenêtre
set -Eeuo pipefail

mkdir -p tools/shims zz-out

########## installe/maj shims ##########
# shim bash (voir ci-dessus)
cat > tools/shims/bash <<'SHIM'
#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${__MCGT_SHIM_GUARD:-}" == "1" ]]; then
  echo "[shim/bash] Boucle détectée (guard). Abandon." >&2
  exit 120
fi
export __MCGT_SHIM_GUARD=1
if [[ -x /usr/bin/bash ]]; then
  REAL_BASH=/usr/bin/bash
elif [[ -x /bin/bash ]]; then
  REAL_BASH=/bin/bash
else
  REAL_BASH="$(command -p bash -lc 'command -v bash')" || true
fi
: "${REAL_BASH:?Impossible de localiser le vrai bash}"
if [[ "$(readlink -f "$REAL_BASH")" == "$(readlink -f "$0")" ]]; then
  echo "[shim/bash] Résolution retombe sur le shim. Abandon." >&2
  exit 121
fi
ROOT="${MCGT_ROOT:-$PWD}"
PROBE="${PROBE:-$ROOT/tools/sourcing_probe.bash}"
: "${MCGT_SOURCING_LOG:=$ROOT/zz-out/trace_sourcing_$(date +%Y%m%dT%H%M%S).log}"
export MCGT_SOURCING_LOG
export BASH_ENV="$PROBE"
dedup_path() {
  awk -v RS=: '!(seen[$0]++) { out = out (NR>1?":":"") $0 } END{ print out }' <<<"$1"
}
export PATH="$(dedup_path "${PATH:-}")"
exec -a bash "$REAL_BASH" "$@"
SHIM
chmod +x tools/shims/bash

# shim "sh" : utiliser le vrai /bin/sh (évite toute récursion/ralentissement)
cat > tools/shims/sh <<'SHIM'
#!/usr/bin/env bash
set -Eeuo pipefail
exec /bin/sh "$@"
SHIM
chmod +x tools/shims/sh

# Probe LIGHT : seulement les includes, pas de xtrace flood
cat > tools/sourcing_probe.bash <<'PROBE'
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
PROBE
chmod +x tools/sourcing_probe.bash
########## fin shims/probe ##########

# Préfixer tools/shims UNE fois + dédupliquer PATH
prepend_once() {
  local dir="$1"
  local p=":${PATH:-}:"
  p="${p//:$dir:/:}"; p="${p#:}"; p="${p%:}"
  PATH="$dir${p:+:$p}"
  PATH="$(awk -v RS=: '!(seen[$0]++) { out = out (NR>1?":":"") $0 } END{ print out }' <<<"$PATH")"
  export PATH
}
prepend_once "$PWD/tools/shims"
hash -r

echo ">>> which -a bash"; which -a bash || true
echo ">>> type -a bash"; type -a bash || true

# Timeout (modifiable: MCGT_TIMEOUT="15m" | "900")
TIMEOUT="${MCGT_TIMEOUT:-20m}"
RUNNER=(bash --noprofile --norc -lc 'tools/pass14_smoke_with_mapping.sh')

ts="$(date +%Y%m%dT%H%M%S)"
log="zz-out/trace_sourcing_${ts}.log"
echo "[INFO] Trace vers $log"

# stream du log en live (retour visuel immédiat)
set +e
tail -n0 -F "$log" 2>/dev/null &
TAIL_PID=$!

if command -v timeout >/dev/null 2>&1; then
  MCGT_SOURCING_LOG="$log" env -u BASH_ENV -u ENV timeout --preserve-status "$TIMEOUT" "${RUNNER[@]}"
  rc=$?
  if [[ $rc -eq 124 || $rc -eq 137 ]]; then
    echo "[WARN] Exécution interrompue par timeout (${TIMEOUT})." | tee -a "$log"
  fi
else
  echo "[INFO] \`timeout\` indisponible — exécution sans garde-temps." | tee -a "$log"
  MCGT_SOURCING_LOG="$log" env -u BASH_ENV -u ENV "${RUNNER[@]}"
  rc=$?
fi

# stop le tail live
kill "$TAIL_PID" >/dev/null 2>&1 || true
wait "$TAIL_PID" 2>/dev/null || true
set -e

echo "[INFO] Fin d’exécution (rc=$rc). Log: $log"

# Garde-fou fenêtre
if [[ -t 0 || -t 1 ]]; then
  read -rp $'Appuyez sur Entrée pour fermer… ' </dev/tty || true
fi

exit "$rc"
