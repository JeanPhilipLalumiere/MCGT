#!/usr/bin/env bash
# Normalise .pre-commit-config.yaml (citations correctes, YAML valide) et vérifie.
set -Eeuo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"
bakdir="_tmp/precommit_fix_${ts}"
mkdir -p "$bakdir"

echo "[INFO] Backup → $bakdir"
test -f .pre-commit-config.yaml && cp -a .pre-commit-config.yaml "$bakdir/.pre-commit-config.yaml.bak" || true

echo "[INFO] Écriture d'une config compacte et VALIDE (noms contenant ':' quotés)"
cat > .pre-commit-config.yaml <<'YAML'
# Pre-commit config normalisée (MCGT)
# Docs: https://pre-commit.com
repos:
  - repo: local
    hooks:
      - id: assets-budgets
        name: "assets-budgets"
        entry: python3 tools/scan_assets_budget.py
        language: system
        pass_filenames: false
        stages: [pre-commit, pre-push, manual]

      - id: gitleaks-protect
        name: "gitleaks protect (skip si non installé)"
        entry: bash -lc 'command -v gitleaks >/dev/null || exit 0; gitleaks protect --staged --no-banner --redact'
        language: system
        pass_filenames: false
        stages: [pre-commit]

      - id: guard-placeholders
        name: "guard placeholders"
        entry: tools/guard_fail_on_placeholders.sh
        language: system
        pass_filenames: false
        stages: [pre-commit]

      - id: guard-no-jupyterlab-in-runtime
        name: "guard: jupyterlab must stay in dev"
        entry: bash -lc 'grep -q "^jupyterlab" requirements.txt && { echo "jupyterlab doit rester dans requirements-dev.txt"; exit 1; } || exit 0'
        language: system
        files: ^requirements\.txt$
        stages: [pre-commit]

      - id: guard-pip-constraint
        name: "guard: pip installs must use constraints (env ou inline)"
        entry: bash -lc '
          files=$(git diff --cached --name-only); fail=0;
          for f in $files; do
            test -f "$f" || continue
            if grep -qE "pip +install +-r +requirements\.txt" "$f"; then
              if ! grep -q "PIP_CONSTRAINT" "$f"; then
                echo "::error file=$f::ajoute PIP_CONSTRAINT=constraints/security-pins.txt (ou exporte PIP_CONSTRAINT dans l env)"; fail=1;
              fi
            fi
          done
          exit $fail
        '
        language: system
        files: ^(.*\.(sh|bash|zsh|ps1|py|md|yml|yaml)|Makefile)$
        stages: [pre-commit, pre-push]
YAML

echo "[INFO] Validation YAML via pre-commit"
if ! command -v pre-commit >/dev/null 2>&1; then
  echo "[WARN] pre-commit non trouvé → installation légère"
  pip install --quiet pre-commit
fi

pre-commit validate-config
echo "[OK] .pre-commit-config.yaml est valide."

echo "[HINT] Active si besoin: pre-commit install"
