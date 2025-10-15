#!/usr/bin/env bash
set -euo pipefail

WHEEL="$(ls dist/*.whl | head -n1)"
SDIST="$(ls dist/*.tar.gz | head -n1 || true)"

has_pep639() {
  unzip -p "$WHEEL" */METADATA | grep -qE '^License-Expression:'
}

if has_pep639; then
  echo "[OK] PEP639 détecté (License-Expression présent) — métadonnées conformes au mode SPDX."
  exit 0
fi

echo "[INFO] Mode legacy (pas de License-Expression): on s’assure qu’aucun header PEP639 ne s’est glissé."
if unzip -p "$WHEEL" */METADATA | grep -Ei '^(License-Expression|License-File|Dynamic: license)'; then
  echo "[ERR] Headers PEP639 détectés en mode legacy."
  exit 2
fi

if unzip -l "$WHEEL" | grep -qE '/dist-info/licenses/'; then
  echo "[ERR] Dossier licenses/ détecté en mode legacy."
  exit 3
fi

echo "[OK] Legacy: pas de headers PEP639 ni de dossier licenses/"
exit 0
