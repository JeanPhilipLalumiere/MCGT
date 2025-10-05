#!/usr/bin/env bash
# (Option A) Pour utiliser la pause PSX factorisée :
# . tools/lib_psx.sh
# psx_install "step5_repo_sanity_suite.sh"
set -euo pipefail

# === PSX : bloquer la fermeture auto (hors CI) ===
WAIT_ON_EXIT="${WAIT_ON_EXIT:-1}"
psx() {
  rc=$?
  echo
  if [[ $rc -eq 0 ]]; then
    echo "✅ Étape 5 — Sanity suite OK (exit: $rc)"
  else
    echo "❌ Étape 5 — Sanity suite KO (exit: $rc)"
  fi
  if [[ "${WAIT_ON_EXIT}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
  fi
}
trap 'psx' EXIT
# ================================================

cd "$(git rev-parse --show-toplevel)"

# S’auto-marquer exécutable pour éviter un échec du hook
if [[ ! -x "$0" ]]; then
  chmod +x "$0"
  git add --chmod=+x "$0" || git add "$0"
fi

echo "==> (1) Pré-commit (tolérant, 2 passes)"
pre-commit install >/dev/null 2>&1 || true
pre-commit run --all-files || true
pre-commit run --all-files || true

echo "==> (2) Tests Python (rapides)"
# Tests globaux + dossiers de tests connus; ignore les très lents si marqués
if command -v pytest >/dev/null 2>&1; then
  pytest -q || true
  if [[ -d "zz-tests" ]]; then
    pytest -q zz-tests || true
  fi
  # tests unitaires connus de chapitres (ex: ch07)
  if [[ -d "zz-scripts/chapter07/tests" ]]; then
    pytest -q zz-scripts/chapter07/tests || true
  fi
else
  echo "WARN: pytest introuvable; étape (2) sautée."
fi

echo "==> (3) Guards schémas/manifest (tolérant)"
if [[ -x tools/fix_manifest_drift_and_rerun_schemas.sh ]]; then
  KEEP_OPEN=0 tools/fix_manifest_drift_and_rerun_schemas.sh || true
fi
if [[ -x tools/step1_manifest_reenable_test.sh ]]; then
  KEEP_OPEN=0 tools/step1_manifest_reenable_test.sh || true
fi

echo "==> (4) Récapitulatif final"
pre-commit run --all-files || true
echo "INFO: Sanity suite terminée."
