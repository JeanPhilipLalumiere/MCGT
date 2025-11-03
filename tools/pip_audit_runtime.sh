#!/usr/bin/env bash
set -Eeuo pipefail

cd "${GITHUB_WORKSPACE:-.}"

ALLOW="${ALLOWLIST:-.github/audit/allowlist.txt}"
OUT_JSON="audit.json"

python -m pip install --upgrade pip >/dev/null
python -m pip install --upgrade pip-audit >/dev/null

# Génére un snapshot de l'environnement courant
python - "$@" > ._req.txt <<'PY'
import pkg_resources
for d in sorted(pkg_resources.working_set, key=lambda d: d.project_name.lower()):
    print(f"{d.project_name}=={d.version}")
PY

# Lance pip-audit (JSON). Exit code non-zéro si vulnérabilités.
set +e
pip-audit -r ._req.txt -f json -o "${OUT_JSON}"
rc=$?
set -e

# Si allowlist, filtre les vulns listées (par id GHSA/CVE)
if command -v jq >/dev/null 2>&1 && [[ -s "${OUT_JSON}" && -f "${ALLOW}" ]]; then
  jq --argfile wl <(tr -d '\r' < "${ALLOW}" | sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' | jq -R . | jq -s .) '
    # wl = ["GHSA-xxx","CVE-YYYY-zzzz",...]
    def WL: $wl;
    # conserve les éléments dont au moins UNE vuln n’est PAS allowlistée
    [ .[] as $p
      | ($p.vulns // []) as $vv
      | [ $vv[]? | select( ( .id // .advisory.id ) as $id | (WL | index($id)) | not ) ] as $remain
      | if ($remain|length) > 0 then
          $p | .vulns = $remain
        else empty end
    ]' "${OUT_JSON}" > "${OUT_JSON}.filtered" 2>/dev/null \
  && mv "${OUT_JSON}.filtered" "${OUT_JSON}"
fi

# Si des vulnérabilités restent, fail (rc=1). Sinon success.
if command -v jq >/dev/null 2>&1 && [[ -s "${OUT_JSON}" ]]; then
  n="$(jq '[ .[] | (.vulns // [])[] ] | length' "${OUT_JSON}")"
  if [[ "${n}" -gt 0 ]]; then
    echo "[audit] ${n} vuln(s) détectée(s) après allowlist"
    exit 1
  fi
fi
exit 0
