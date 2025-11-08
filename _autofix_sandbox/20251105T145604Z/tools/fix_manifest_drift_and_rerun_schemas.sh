#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[fix-drift] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[fix-drift] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------


echo "==> (0) Contexte dépôt"
cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Rafraîchit le manifest (FULL: size/sha/mtime/git)"
KEEP_OPEN=0 tools/refresh_master_manifest_full.sh || true

echo "==> (2) Relance schemas-guard"
set +e
KEEP_OPEN=0 tools/ci_step6_schemas_guard.sh
RC=$?
set -e

if (( RC != 0 )); then
  echo "==> (2b) Des erreurs subsistent — second essai après FULL refresh"
  KEEP_OPEN=0 tools/refresh_master_manifest_full.sh || true
  KEEP_OPEN=0 tools/ci_step6_schemas_guard.sh
fi

echo "==> (3) pre-commit (tolérant)"
pre-commit run --all-files || true

echo "==> (4) Commit/push si le manifest a changé"
if ! git diff --quiet -- zz-manifests/manifest_master.json; then
  git add zz-manifests/manifest_master.json
  git commit -m "manifests: full refresh post-config changes (auto)"
  git push || true
else
  echo "Aucun changement de manifest à committer."
fi
