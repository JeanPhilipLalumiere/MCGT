#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT_DIR="${ROOT}/.github/audit/out"; mkdir -p "$OUT_DIR"
ALLOW="${ROOT}/.github/audit/allowlist.txt"; touch "$ALLOW"

REQ=""
for f in requirements.txt requirements-prod.txt requirements.lock; do
  [[ -f "$ROOT/$f" ]] && { REQ="$f"; break; }
done

JSON="${OUT_DIR}/audit.json"
TXT="${OUT_DIR}/summary.txt"

if [[ -n "$REQ" ]]; then
  echo "[INFO] pip-audit on $REQ"
  pip-audit -r "$REQ" --desc --format json >"$JSON" || true
else
  echo "[INFO] pip-audit on environment"
  pip-audit --desc --format json >"$JSON" || true
fi

jq -r '.[] | [.dependency.name, .dependency.version, (.advisory.id // "-"), (.advisory.cve // "-"), (.advisory.severity // "-")] | @tsv' "$JSON" 2>/dev/null \
  | column -t -s $'\t' | tee "$TXT" || { echo "[WARN] pas de données audit"; :; }

VIOL=$(jq -r --argfile allow <(tr -d '\r' < "$ALLOW" | sed -E 's/#.*$//' | sed '/^\s*$/d' | awk '{print $1}' | jq -R -s -c 'split("\n")') '
  [ .[] | select( (.advisory.id // "") as $id | ($id|length>0) and ( ($allow|index($id)) == null )) ] | length ' "$JSON" 2>/dev/null || echo "0")

if [[ "${VIOL:-0}" -gt 0 ]]; then
  echo "::error title=audit failed::${VIOL} advisory(ies) non allowlistées (voir artifact audit.json)"
  exit 1
fi
echo "[OK] audit clean (allowlist appliquée)."
