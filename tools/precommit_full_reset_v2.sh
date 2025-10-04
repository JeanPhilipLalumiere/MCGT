#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[precommit-full-reset] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[precommit-full-reset] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------

cd "$(git rev-parse --show-toplevel)"
mkdir -p .ci-out

echo "==> (1) Sauvegarde .pre-commit-config.yaml (si présent)"
[[ -f .pre-commit-config.yaml ]] && cp -f .pre-commit-config.yaml ".pre-commit-config.yaml.bak.$(date -u +%Y%m%dT%H%M%SZ)" || true

echo "==> (2) ÉCRASE .pre-commit-config.yaml avec un squelette VALIDE"
# IMPORTANT : here-doc fermé par 'YAML' seul sur sa ligne (pas de commandes ici !)
cat > .pre-commit-config.yaml <<'YAML'
exclude: '^\.ci-out/'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-executables-have-shebangs
      - id: check-shebang-scripts-are-executable
YAML

echo "==> (3) .gitattributes : ajoute '.ci-out export-ignore' (idempotent)"
[[ -f .gitattributes ]] || echo "# Attributes auto-générés" > .gitattributes
if ! grep -qE '^[[:space:]]*\.ci-out[[:space:]]+export-ignore[[:space:]]*$' .gitattributes; then
  tail -c1 .gitattributes | read -r _ || echo >> .gitattributes
  echo ".ci-out export-ignore" >> .gitattributes
  echo "INFO: ajouté dans .gitattributes"
else
  echo "INFO: déjà présent dans .gitattributes"
fi

echo "==> (4) .gitignore : ajoute '.ci-out/' (idempotent) + désindexe"
if ! grep -qE '^[[:space:]]*\.ci-out/[[:space:]]*$' .gitignore 2>/dev/null; then
  echo ".ci-out/" >> .gitignore
  echo "INFO: ajouté dans .gitignore"
fi
git rm -r --cached .ci-out 2>/dev/null || true

echo "==> (5) Remet les permissions d’exécution sur tools/*.sh + .ci-helpers/guard.sh"
if compgen -G "tools/*.sh" >/dev/null; then
  chmod +x tools/*.sh || true
  git add --chmod=+x tools/*.sh || true
fi
if [[ -f .ci-helpers/guard.sh ]]; then
  chmod +x .ci-helpers/guard.sh || true
  git add --chmod=+x .ci-helpers/guard.sh || true
fi

echo "==> (6) Valide la config et exécute pre-commit (tolérant)"
pre-commit validate-config
pre-commit run --all-files || true

echo "==> (7) Commit & push (si diff)"
git add .pre-commit-config.yaml .gitattributes .gitignore || true
git commit -m "ci: reset pre-commit; exclude .ci-out; export-ignore; fix exec bits" || true
git push || true

echo "✅ Terminé. Tu peux relancer: pre-commit run --all-files"
