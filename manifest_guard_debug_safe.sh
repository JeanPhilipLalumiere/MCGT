# manifest_guard_debug_safe.sh
#!/usr/bin/env bash
set -Eeuo pipefail

LOG="$(ls -1t .ci-out/manifest-guard_*.log 2>/dev/null | head -n1 || true)"
echo "[INFO] Log: ${LOG:-<introuvable>}"
if [ -n "${LOG:-}" ] && [ -f "$LOG" ]; then
  echo "──────── HEAD(60)"; head -n 60 "$LOG" || true
  echo "──────── ERRORS"; grep -nE '::error::|Traceback|ERROR|Fail|failed|JSON.*(Error|Decode)' "$LOG" || true
  echo "──────── TAIL(60)"; tail -n 60 "$LOG" || true
else
  echo "[WARN] Aucun log manifest-guard trouvé dans .ci-out/"
fi

echo "──────── Check présence/JSON local"
test -f zz-manifests/manifest_master.json || { echo "::error::zz-manifests/manifest_master.json manquant"; exit 1; }
python3 - <<'PY'
import json, sys
p="zz-manifests/manifest_master.json"
with open(p,'rb') as f: json.load(f)
print("[OK] JSON python valide:", p)
PY

if command -v jq >/dev/null 2>&1; then
  jq -e . zz-manifests/manifest_master.json >/dev/null && echo "[OK] JSON jq valide" || { echo "::error::jq parse fail"; exit 1; }
else
  echo "[INFO] jq absent, étape sautée"
fi

echo "──────── diag_consistency (optionnel)"
DIAG=""
for cand in zz-manifests/diag_consistency.py zz-scripts/diag_consistency.py; do
  [ -f "$cand" ] && DIAG="$cand" && break
done
if [ -n "$DIAG" ]; then
  echo "[INFO] DIAG=$DIAG"
  if python3 "$DIAG" -h 2>&1 | grep -q -- '--fail-on'; then
    set +e
    python3 "$DIAG" zz-manifests/manifest_master.json --report text --normalize-paths --apply-aliases --strip-internal --content-check --fail-on errors
    RC=$?
    set -e
    if [ $RC -ne 0 ]; then
      echo "::error::diag_consistency a retourné $RC (erreurs bloquantes)."
      exit $RC
    else
      echo "[OK] diag_consistency (errors-only) passé"
    fi
  else
    echo "[INFO] Pas d’option --fail-on, exécution best-effort (non-bloquante)"
    python3 "$DIAG" zz-manifests/manifest_master.json || echo "::warning::diag_consistency a retourné non-0 (toléré)"
  fi
else
  echo "[SKIP] Aucun diag_consistency.py trouvé"
fi

echo "──────── Résumé: local OK jusqu’ici."
