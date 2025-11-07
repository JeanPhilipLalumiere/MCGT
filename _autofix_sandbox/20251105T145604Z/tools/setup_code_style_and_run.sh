#!/usr/bin/env bash
set -euo pipefail

KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[code-style] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[code-style] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Prépare pyproject.toml (Ruff + Black ; idempotent)"
touch pyproject.toml
# Injecte sections si absentes (sans casser un pyproject existant)
ensure_toml_section () {
  local section="$1"
  if ! grep -q "^\[$section\]" pyproject.toml; then
    printf "\n[%s]\n" "$section" >> pyproject.toml
  fi
}
ensure_kv () {
  local section="$1"; local key="$2"; local val="$3"
  if ! awk -v s="[$section]" -v k="$key" '
      $0==s {insec=1; next} /^\[.*\]/ {insec=0}
      insec && index($0,k)==1 {found=1}
      END{exit(found?0:1)}' pyproject.toml; then
    # ajoute la clé à la fin de la section
    awk -v s="[$section]" -v k="$key" -v v="$val" '
      {print}
      $0==s {print k" = "v; s="";}' pyproject.toml > pyproject.toml.tmp && mv pyproject.toml.tmp pyproject.toml
  fi
}

ensure_toml_section "tool.black"
ensure_kv "tool.black" "line-length" "88"
ensure_kv "tool.black" "target-version" '["py312"]'
# exclusions black (hérite de .gitignore, mais on est explicites)
if ! grep -q '^\[tool.black\]' pyproject.toml || ! grep -q '^exclude = ' pyproject.toml; then
  awk '1; END{print "exclude = \"(^\\.ci-out/|^legacy-tex/|^\\.git/|^venv/|^\\.mypy_cache/)\""}' pyproject.toml > pyproject.toml.tmp && mv pyproject.toml.tmp pyproject.toml
fi

ensure_toml_section "tool.ruff"
ensure_kv "tool.ruff" "line-length" "88"
ensure_kv "tool.ruff" "target-version" '"py312"'
ensure_toml_section "tool.ruff.lint"
# Un set raisonnable et stable
if ! grep -q '^\[tool.ruff.lint\]' pyproject.toml || ! grep -q '^select = ' pyproject.toml; then
  awk '1; END{print "select = [\"E\",\"F\",\"W\",\"I\",\"B\",\"UP\",\"SIM\"]"}' pyproject.toml > pyproject.toml.tmp && mv pyproject.toml.tmp pyproject.toml
fi
ensure_kv "tool.ruff" "extend-exclude" '[".ci-out","legacy-tex",".git","venv",".mypy_cache"]'

git add pyproject.toml

echo "==> (2) Met à jour .pre-commit-config.yaml (ajout Ruff + Black, idempotent)"
touch .pre-commit-config.yaml
# Ajout des blocs si absents
if ! grep -q 'repo: https://github.com/astral-sh/ruff-pre-commit' .pre-commit-config.yaml; then
  cat >> .pre-commit-config.yaml <<'YML'

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.4
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
YML
fi
if ! grep -q 'repo: https://github.com/psf/black' .pre-commit-config.yaml; then
  cat >> .pre-commit-config.yaml <<'YML'

  - repo: https://github.com/psf/black
    rev: 24.4.2
    hooks:
      - id: black
YML
fi
git add .pre-commit-config.yaml

echo "==> (3) Exécute les hooks Ruff/Black (auto-fix), tolérant"
pre-commit install || true
pre-commit run ruff -a || true
pre-commit run ruff-format -a || true
pre-commit run black -a || true

echo "==> (4) Commit/push des changements de style (si présents)"
if ! git diff --cached --quiet; then
  git commit -m "style: apply Ruff & Black across repo"
  git push
else
  echo "Aucun changement de style à committer."
fi

echo "==> (5) Refresh manifest (size/sha/mtime/git) + revalidation schémas"
KEEP_OPEN=0 tools/refresh_master_manifest_full.sh || true

echo "==> (6) Pré-commit complet (tolérant)"
pre-commit run --all-files || true

echo "==> (7) Fin."
