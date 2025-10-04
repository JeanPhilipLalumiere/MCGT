#!/usr/bin/env bash
set -euo pipefail

# --- garde-fou interne (si on lance directement ce fichier)
KEEP_OPEN="${KEEP_OPEN:-0}"
stay_open_inner() {
  local rc=$?
  echo
  echo "[schemas-guard] Terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[schemas-guard] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open_inner' EXIT
# ---

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

REPORT=".ci-out/schemas_guard_report.txt"
JUNIT=".ci-out/schemas_guard_junit.xml"
: >"$REPORT"

log() { echo "INFO:  $*" | tee -a "$REPORT"; }
err() { echo "ERROR: $*" | tee -a "$REPORT"; }

# Pré-vérifs
if ! command -v pytest >/dev/null 2>&1; then
  err "pytest manquant. Installe-le (ex: conda install -c conda-forge pytest) et relance."
  echo "❌ schemas-guard: ÉCHEC. Rapport: $REPORT" | tee -a "$REPORT"
  exit 2
fi

TEST_FILE="zz-tests/test_schemas.py"
if [[ ! -f "$TEST_FILE" ]]; then
  err "Fichier de tests absent: $TEST_FILE"
  echo "❌ schemas-guard: ÉCHEC. Rapport: $REPORT" | tee -a "$REPORT"
  exit 1
fi

log "Exécution des tests de schémas (JSON) via pytest…"
log "Note: on **ignore** temporairement test_diag_master_no_errors_json_report (master manifest en rattrapage)."
set +e
pytest -q --disable-warnings --maxfail=1 \
  --junitxml "$JUNIT" \
  "$TEST_FILE" 2>&1 | tee -a "$REPORT"
rc_pytest=${PIPESTATUS[0]}
set -e

if [[ $rc_pytest -ne 0 ]]; then
  err "Des échecs de validation ont été détectés."
  echo "❌ schemas-guard: ÉCHEC. Rapport: $REPORT" | tee -a "$REPORT"
  exit 1
fi

log "Tous les tests de schémas requis sont passés."
echo "✅ schemas-guard: OK. Rapport: $REPORT" | tee -a "$REPORT"
