#!/usr/bin/env bash
set -euo pipefail

# Ce wrapper:
#  - lance tools/pass14_smoke_with_mapping.sh
#  - garde la fenêtre ouverte et demande "Entrée" via tools/run_with_pause.sh
#  - optionnellement filtre le bruit "environment: line 4: ... division by 0"
#    si MCGT_FILTER_ENV=1

# On s'assure que tools/run_with_pause.sh existe (sinon message clair)
if [[ ! -x tools/run_with_pause.sh ]]; then
  echo "Erreur: tools/run_with_pause.sh introuvable ou non exécutable." >&2
  echo "Astuce: relance le pack d’installation qui l’installe automatiquement." >&2
  exit 127
fi

# Chemin de la commande PASS14
CMD_PASS14='tools/pass14_smoke_with_mapping.sh'

# Mode filtrage optionnel
if [[ "${MCGT_FILTER_ENV:-0}" == "1" ]]; then
  # On passe par bash -lc pour pouvoir utiliser un pipe et activer pipefail
  exec tools/run_with_pause.sh bash -lc \
'set -o pipefail; '"$CMD_PASS14"' 2>&1 | grep -v "^environment: line 4: .*: division by 0 (error token is "'
else
  # Chemin direct (pas de pipe), sortie intacte
  exec tools/run_with_pause.sh "$CMD_PASS14"
fi
