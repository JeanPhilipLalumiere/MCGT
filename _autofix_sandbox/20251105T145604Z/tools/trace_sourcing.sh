#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p zz-out
ts="$(date +%Y%m%dT%H%M%S)"
log="zz-out/trace_sourcing_${ts}.log"

# Met le shim 'environment' en tête de PATH (au cas où il serait exécuté) + purge cache
export PATH="$PWD/tools/shims:$PATH"
hash -r

# Nettoie les variables pièges au niveau PARENT, mais on va injecter notre propre BASH_ENV au CHILD
export -n BASH_ENV || true
export -n ENV || true

# Commande cible
if [[ "${1-}" == "--" ]]; then shift; fi
if [[ "$#" -eq 0 ]]; then
  echo "Usage: $0 -- <commande à tracer>" >&2
  if [[ -t 0 || -t 1 ]]; then read -rp $'Appuyez sur Entrée pour fermer… ' </dev/tty || true; fi
  exit 2
fi
target_cmd=("$@")

# Emplacement absolu de la probe pour BASH_ENV
probe="$PWD/tools/sourcing_probe.bash"
if [[ ! -f "$probe" ]]; then
  echo "Probe introuvable: $probe" >&2
  if [[ -t 0 || -t 1 ]]; then read -rp $'Appuyez sur Entrée pour fermer… ' </dev/tty || true; fi
  exit 3
fi

echo "[INFO] Trace vers $log"

# IMPORTANT: On passe MCGT_SOURCING_LOG au shell enfant; et on **définit BASH_ENV** -> la probe est évaluée au démarrage
# bash enfant démarré sans profils/rc pour éviter le bruit
MCGT_SOURCING_LOG="$log" \
env BASH_ENV="$probe" \
    bash --noprofile --norc -lc "${target_cmd[*]}" || true

echo "[INFO] Fin d’exécution. Log: $log"

# Garde-fou: rester ouvert tant que l’utilisateur n’appuie pas sur Entrée (si TTY dispo)
if [[ -t 0 || -t 1 ]]; then
  read -rp $'Appuyez sur Entrée pour fermer… ' </dev/tty || true
fi
