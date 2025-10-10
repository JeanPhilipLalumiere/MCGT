#!/usr/bin/env bash
set -euo pipefail

# Log target (modifiable via MCGT_LOGFILE)
ts="$(date +%Y%m%dT%H%M%S)"
log="${MCGT_LOGFILE:-zz-out/pass14_run_${ts}.log}"
mkdir -p "$(dirname "$log")"

# Vérifie la présence du wrapper de pause
if [[ ! -x tools/run_with_pause.sh ]]; then
  echo "Erreur: tools/run_with_pause.sh introuvable." >&2
  exit 127
fi

# Commande de base
cmd='tools/pass14_smoke_with_mapping.sh'

# Filtre optionnel du bruit "environment: line 4: ... division by 0 (error token is "
if [[ "${MCGT_FILTER_ENV:-0}" == "1" ]]; then
  exec tools/run_with_pause.sh env -u BASH_ENV -u ENV bash --noprofile --norc -lc \
"set -o pipefail; $cmd 2>&1 \
 | grep -Ev '^environment: line 4: .*: division by 0 \(error token is ' \
 | tee -a '$log'"
else
  exec tools/run_with_pause.sh env -u BASH_ENV -u ENV bash --noprofile --norc -lc \
"set -o pipefail; $cmd 2>&1 | tee -a '$log'"
fi
