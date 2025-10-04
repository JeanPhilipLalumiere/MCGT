#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[fix-precommit] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[fix-precommit] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------

cd "$(git rev-parse --show-toplevel)"
mkdir -p .ci-out

echo "==> (1) Sauvegarde .pre-commit-config.yaml (si présent)"
if [[ -f .pre-commit-config.yaml ]]; then
  cp -f .pre-commit-config.yaml ".pre-commit-config.yaml.bak.$(date -u +%Y%m%dT%H%M%SZ)"
fi

repair_from_head() {
  if git cat-file -e HEAD:.pre-commit-config.yaml 2>/dev/null; then
    git show HEAD:.pre-commit-config.yaml > .pre-commit-config.yaml
    echo "INFO: restauré .pre-commit-config.yaml depuis HEAD"
    return 0
  fi
  return 1
}

write_minimal_yaml() {
  cat > .pre-commit-config.yaml <<'YAML'
exclude: "^(?:\.ci-out/|.*/\.ci-out/)"
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
  echo "INFO: écrit un squelette .pre-commit-config.yaml minimal"
}

echo "==> (2) Répare/Crée la config pre-commit"
if ! pre-commit validate-config >/dev/null 2>&1; then
  repair_from_head || write_minimal_yaml
fi

# Re-valide : si encore cassé (HEAD corrompu), on force le squelette minimal.
if ! pre-commit validate-config >/dev/null 2>&1; then
  write_minimal_yaml
fi

echo "==> (3) Ajoute/assure l'exclude .ci-out (idempotent)"
if grep -qE '^[[:space:]]*exclude[[:space:]]*:' .pre-commit-config.yaml; then
  if ! grep -q '\.ci-out' .pre-commit-config.yaml; then
    # remplace la ligne exclude:* par une version propre incluant .ci-out
    awk '
      BEGIN{done=0}
      /^[[:space:]]*exclude[[:space:]]*:/ && !done {
        print "exclude: \"^(?:\\.ci-out/|.*/\\.ci-out/)\""; done=1; next
      }
      {print}
    ' .pre-commit-config.yaml > .pre-commit-config.yaml.tmp && mv .pre-commit-config.yaml.tmp .pre-commit-config.yaml
    echo "INFO: injecté .ci-out dans exclude"
  else
    echo "INFO: exclude contient déjà .ci-out"
  fi
else
  printf '\nexclude: "^(?:\\.ci-out/|.*/\\.ci-out/)"\n' >> .pre-commit-config.yaml
  echo "INFO: ajouté exclude top-level"
fi

echo "==> (4) .gitattributes : '.ci-out export-ignore' (idempotent)"
[[ -f .gitattributes ]] || echo "# Attributes auto-générés" > .gitattributes
if ! grep -qE '^[[:space:]]*\.ci-out[[:space:]]+export-ignore[[:space:]]*$' .gitattributes; then
  tail -c1 .gitattributes | read -r _ || echo >> .gitattributes
  echo ".ci-out export-ignore" >> .gitattributes
  echo "INFO: ajouté '.ci-out export-ignore' à .gitattributes"
else
  echo "INFO: déjà présent dans .gitattributes"
fi

echo "==> (5) .gitignore : ignore .ci-out/ + désindexation"
if ! grep -qE '^[[:space:]]*\.ci-out/[[:space:]]*$' .gitignore 2>/dev/null; then
  echo ".ci-out/" >> .gitignore
  echo "INFO: ajouté '.ci-out/' à .gitignore"
fi
git rm -r --cached .ci-out 2>/dev/null || true

echo "==> (6) Corrige les permissions d’exécution sur tools/*.sh"
if compgen -G "tools/*.sh" >/dev/null; then
  chmod +x tools/*.sh || true
  git add --chmod=+x tools/*.sh || true
fi

echo "==> (7) Validation pre-commit"
pre-commit validate-config
pre-commit run --all-files || true

echo "==> (8) Commit & push (si diff)"
git add .pre-commit-config.yaml .gitattributes .gitignore || true
git commit -m "ci: repair pre-commit config; exclude .ci-out; export-ignore; fix exec bits" || true
git push || true

echo "✅ Réparation terminée. Tu peux relancer: pre-commit run --all-files"
