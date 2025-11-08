#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[fix-precommit-config] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[fix-precommit-config] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------

cd "$(git rev-parse --show-toplevel)"
mkdir -p .ci-out

echo "==> (1) Sauvegarde de .pre-commit-config.yaml (si présent)"
[[ -f .pre-commit-config.yaml ]] && cp -f .pre-commit-config.yaml ".pre-commit-config.yaml.bak.$(date -u +%Y%m%dT%H%M%SZ)" || true

echo "==> (2) Réécrit une config pre-commit VALIDE (exclut .ci-out)"
cat > .pre-commit-config.yaml <<'YAML'
# Minimal, valid pre-commit config (+ exclusion .ci-out)
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-executables-have-shebangs
      - id: check-shebang-scripts-are-executable

# Exclure le répertoire d'artefacts CI de tous les hooks
exclude: |
  (?x)
  ^\.ci-out/
YAML

echo "==> (3) .gitattributes : s’assure de '.ci-out export-ignore' (idempotent)"
touch .gitattributes
# Ajoute une NL finale si absente pour éviter des collages moches
if [[ -s .gitattributes ]] && [[ "$(tail -c1 .gitattributes || true)" != $'\n' ]]; then
  printf '\n' >> .gitattributes
fi
if ! grep -qE '^[[:space:]]*\.ci-out[[:space:]]+export-ignore[[:space:]]*$' .gitattributes; then
  echo ".ci-out export-ignore" >> .gitattributes
  echo "INFO: ajouté '.ci-out export-ignore' à .gitattributes"
else
  echo "INFO: déjà présent dans .gitattributes"
fi

echo "==> (4) .gitignore : s’assure de '.ci-out/' + purge de l’index"
grep -q '^\.ci-out/$' .gitignore 2>/dev/null || echo '.ci-out/' >> .gitignore
git rm -r --cached .ci-out >/dev/null 2>&1 || true

echo "==> (5) Corrige les bits +x sur nos scripts (idempotent)"
if compgen -G "tools/*.sh" >/dev/null; then
  chmod +x tools/*.sh || true
  git add --chmod=+x tools/*.sh || true
fi
if [[ -f .ci-helpers/guard.sh ]]; then
  chmod +x .ci-helpers/guard.sh || true
  git add --chmod=+x .ci-helpers/guard.sh || true
fi

echo "==> (6) Valide la config & exécute les hooks"
pre-commit validate-config
pre-commit run --all-files || true

echo "==> (7) Commit & push (si diff)"
git add .pre-commit-config.yaml .gitattributes .gitignore
git commit -m "ci(pre-commit): rewrite valid config; exclude .ci-out; export-ignore" || true
git push || true

echo "✅ Fix appliqué. Teste: pre-commit run --all-files"
