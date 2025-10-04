#!/usr/bin/env bash
set -euo pipefail

# === Garde-fou : empêcher la fermeture automatique de la fenêtre ===
# Appui sur Entrée requis pour fermer (PSX) si terminal interactif et pas en CI.
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
# ==================================================================

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Rafraîchir/normaliser le master manifest + revalider les schémas"
if [[ -x tools/fix_manifest_drift_and_rerun_schemas.sh ]]; then
  KEEP_OPEN=0 tools/fix_manifest_drift_and_rerun_schemas.sh
else
  echo "⚠️  tools/fix_manifest_drift_and_rerun_schemas.sh introuvable ou non exécutable."
  echo "    Vérifie son existence/permissions, puis relance."
  exit 2
fi

echo "==> (2) Vérifier le test ciblé (à réactiver s'il était ignoré)"
# Si le test est masqué quelque part, enlève l'exclusion puis relance cette étape.
if ! pytest -q -k diag_master_no_errors_json_report; then
  echo "❌ Le test diag_master_no_errors_json_report échoue."
  echo "   Consulte: .ci-out/schemas_guard_report.txt et corrige le manifest restant."
  exit 1
fi

echo "==> (3) Commit/push si nécessaire"
git add -A
if ! git diff --staged --quiet; then
  git commit -m "guard: sync master manifest and re-enable diag_master_no_errors_json_report"
  git push
  echo "✅ Changements poussés."
else
  echo "Aucun changement à committer."
fi
