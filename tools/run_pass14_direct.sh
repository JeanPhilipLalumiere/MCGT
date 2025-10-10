#!/usr/bin/env bash
# tools/run_pass14_direct.sh — exécution directe, sortie live, timeout, garde-fou
set -Eeuo pipefail

mkdir -p zz-out

# 1) Choix d’un bash "réel" (pas de shim)
if [[ -x /usr/bin/bash ]]; then
  REAL_BASH=/usr/bin/bash
elif [[ -x /bin/bash ]]; then
  REAL_BASH=/bin/bash
else
  echo "[ERREUR] bash système introuvable." >&2
  exit 2
fi

# 2) Nettoyage env (aucune probe, aucun profil)
export -n BASH_ENV || true
export -n ENV || true

# 3) Retirer explicitement d’éventuels shims du PATH pour CE run
PRJ="$PWD"
CLEAN_PATH=":${PATH:-}:"
CLEAN_PATH="${CLEAN_PATH//:$PRJ/tools\/shims:/:}"
CLEAN_PATH="${CLEAN_PATH#:}"; CLEAN_PATH="${CLEAN_PATH%:}"
export PATH="$CLEAN_PATH"

# 4) Timeout (ex: MCGT_TIMEOUT=15m ou 900)
TIMEOUT="${MCGT_TIMEOUT:-20m}"

ts="$(date +%Y%m%dT%H%M%S)"
LOG="zz-out/pass14_direct_${ts}.log"
echo "[INFO] Lancement PASS14 (timeout=$TIMEOUT) — log : $LOG"

# 5) Exécution avec sortie live + capture dans le log
set +e
{
  timeout --preserve-status "$TIMEOUT" \
    "$REAL_BASH" --noprofile --norc -lc 'tools/pass14_smoke_with_mapping.sh'
} 2>&1 | stdbuf -oL -eL tee -a "$LOG"
RC=${PIPESTATUS[0]}
set -e

if [[ $RC -eq 124 || $RC -eq 137 ]]; then
  echo "[WARN] Interrompu par timeout ($TIMEOUT)." | tee -a "$LOG"
fi

echo "[INFO] Fin d’exécution (rc=$RC). Log : $LOG"

# 6) Garde-fou : attendre Entrée avant fermeture (désactivable avec MCGT_NO_PAUSE=1)
if [[ -z "${MCGT_NO_PAUSE:-}" ]] && [[ -t 0 || -t 1 ]]; then
  # lire sur /dev/tty pour survivre aux redirections
  read -rp $'Appuyez sur Entrée pour fermer… ' </dev/tty || true
fi

exit "$RC"
