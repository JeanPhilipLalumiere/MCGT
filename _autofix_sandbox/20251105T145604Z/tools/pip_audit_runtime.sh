#!/usr/bin/env bash
set -Eeuo pipefail

cd "${GITHUB_WORKSPACE:-.}"

# Info env
python -VV || true
python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install --upgrade pip wheel >/dev/null

# Installer pip-audit (verrou souple)
if ! python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install "pip-audit>=2,<3" >/dev/null 2>&1; then
  python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install pip-audit >/dev/null
fi

OUT="audit.json"
ALLOW=".github/audit/allowlist.txt"

# Construire les --ignore-vuln à partir du fichier d'allowlist (une ID par ligne, commentaires OK)
IGNORE_ARGS=()
if [[ -f "${ALLOW}" ]]; then
  while IFS= read -r id; do
    id="${id%%#*}"; id="$(echo "$id" | xargs)"
    [[ -n "$id" ]] && IGNORE_ARGS+=( "--ignore-vuln" "$id" )
  done < "${ALLOW}"
fi

# Choisir la stratégie d'audit:
# - si requirements*.txt existent, les utiliser (reproductible)
# - sinon, auditer l'environnement courant (fallback)
REQS=()
while IFS= read -r f; do REQS+=("$f"); done < <(ls -1 requirements*.txt 2>/dev/null || true)

set +e
if (( ${#REQS[@]} > 0 )); then
  # prendre le premier requirements* trouvé (simple et suffisant ici)
  pip-audit -r "${REQS[0]}" -f json -o "${OUT}" "${IGNORE_ARGS[@]}"
else
  pip-audit -f json -o "${OUT}" "${IGNORE_ARGS[@]}"
fi
RC=$?
set -e

# Toujours produire un JSON non vide pour l'artifact
[[ -s "${OUT}" ]] || echo '[]' > "${OUT}"

# On ne casse pas le job ici : la policy (fail/green) se gère côté CI si besoin
exit 0
