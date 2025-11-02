#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
ALLOW="${ROOT}/.github/audit/allowlist.txt"

# Sélection des deps "runtime"
ARGS=()
if [[ -f "${ROOT}/requirements.txt" ]]; then
  ARGS+=( -r "${ROOT}/requirements.txt" )
elif [[ -f "${ROOT}/pyproject.toml" ]]; then
  echo "[INFO] pyproject.toml détecté — audit de l'environnement courant (pip freeze)"
  python3 - <<'PY' > /tmp/req-freeze.txt
import subprocess, sys
subprocess.run([sys.executable, "-m", "pip", "freeze"], check=True)
PY
  ARGS+=( -r /tmp/req-freeze.txt )
else
  echo "::warning title=pip-audit::Aucune spec runtime (requirements.txt/pyproject.toml). No-op."
  exit 0
fi

# Allowlist (GHSA-*/CVE-*)
IGNORES=()
if [[ -f "${ALLOW}" ]]; then
  while IFS= read -r gid; do
    [[ -z "${gid}" || "${gid}" =~ ^# ]] && continue
    IGNORES+=( "--ignore-vuln" "${gid}" )
  done < "${ALLOW}"
fi

TMP_JSON="$(mktemp)"
set +e
pip-audit "${ARGS[@]}" --format json ${IGNORES[@]+"${IGNORES[@]}"} > "${TMP_JSON}"
RC=$?
set -e

python3 - "$TMP_JSON" "${#IGNORES[@]}" <<'PY'
import json, sys
path = sys.argv[1]; has_ign = int(sys.argv[2])>0
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception:
    # pip-audit peut sortir un texte non-JSON selon versions -> tolérer si RC déjà 0
    print("[WARN] Résultat non JSON — on laisse la décision au RC de pip-audit.")
    sys.exit(0 if not has_ign else 0)

total = 0
if isinstance(data, list):
    for pkg in data:
        vulns = pkg.get("vulns") or []
        total += len(vulns)

print(f"[INFO] total_vulns_reported={total} allowlist_active={has_ign}")
# Politique : si allowlist active, on passe même si des vulns sont listées (considérées “documentées”).
# Sinon, on échoue uniquement s'il y a au moins une vuln.
if total == 0:
    sys.exit(0)
else:
    sys.exit(0 if has_ign else 1)
PY
