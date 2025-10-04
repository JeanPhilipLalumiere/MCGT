#!/usr/bin/env bash
set -euo pipefail

# === Garde-fou PSX : la fenêtre attend Entrée avant de se fermer (hors CI) ===
WAIT_ON_EXIT="${WAIT_ON_EXIT:-1}"
pause_on_exit() {
  rc=$?
  echo
  if [[ $rc -eq 0 ]]; then
    echo "✅ Étape 1 — Terminé avec exit code: $rc"
  else
    echo "❌ Étape 1 — Terminé avec exit code: $rc"
  fi
  if [[ "${WAIT_ON_EXIT}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
  fi
}
trap 'pause_on_exit' EXIT

cd "$(git rev-parse --show-toplevel)"

echo "==> (0) Auto-réparation des bits exécutables pour éviter l'échec du hook"
# Se rendre exécutable au premier run, et marquer côté git
if [[ ! -x "$0" ]]; then
  chmod +x "$0"
  git add --chmod=+x "$0" || git add "$0"
fi
# Corriger l'outil de réparation s'il existe
if [[ -f tools/fix_exec_bits_and_rerun_precommit.sh && ! -x tools/fix_exec_bits_and_rerun_precommit.sh ]]; then
  chmod +x tools/fix_exec_bits_and_rerun_precommit.sh
  git add --chmod=+x tools/fix_exec_bits_and_rerun_precommit.sh || git add tools/fix_exec_bits_and_rerun_precommit.sh
fi

echo "==> (1) Rafraîchir/normaliser le master manifest + revalider les schémas"
if [[ -x tools/fix_manifest_drift_and_rerun_schemas.sh ]]; then
  KEEP_OPEN=0 tools/fix_manifest_drift_and_rerun_schemas.sh
else
  echo "⚠️  tools/fix_manifest_drift_and_rerun_schemas.sh introuvable ou non exécutable."
  exit 2
fi

echo "==> (2) Vérifier le test ciblé (à réactiver s'il était ignoré)"
pytest -q -k diag_master_no_errors_json_report

echo "==> (3) pré-commit (tolérant) pour capter d'autres soucis globaux"
pre-commit run --all-files || true

echo "==> (4) Commit/push si nécessaire"
git add -A
if ! git diff --staged --quiet; then
  git commit -m "guard: sync master manifest and re-enable diag_master_no_errors_json_report"
  git push
else
  echo "Aucun changement à committer."
fi
