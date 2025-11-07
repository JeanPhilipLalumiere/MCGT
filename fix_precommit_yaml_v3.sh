#!/usr/bin/env bash
# Réécrit un .pre-commit-config.yaml minimal et valide (sans guillemets piégeux),
# en utilisant entry+args et des block scalars YAML pour éviter les erreurs.
set -Eeuo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"
bakdir="_tmp/precommit_fix_${ts}"
mkdir -p "$bakdir"

echo "[INFO] Backup éventuel → $bakdir"
if [ -f .pre-commit-config.yaml ]; then
  cp -a .pre-commit-config.yaml "$bakdir/.pre-commit-config.yaml.bak"
fi

cat > .pre-commit-config.yaml <<'YAML'
# Pre-commit config normalisée (MCGT)
# Docs: https://pre-commit.com
repos:
  - repo: local
    hooks:
      - id: assets-budgets
        name: assets-budgets
        entry: python3
        args: ["tools/scan_assets_budget.py"]
        language: system
        pass_filenames: false
        stages: [pre-commit, pre-push, manual]

      - id: gitleaks-protect
        name: gitleaks protect (skip si non installé)
        entry: bash
        args: ["-lc", "command -v gitleaks >/dev/null || exit 0; gitleaks protect --staged --no-banner --redact"]
        language: system
        pass_filenames: false
        stages: [pre-commit]

      - id: guard-placeholders
        name: guard placeholders
        entry: bash
        args: ["-lc", "tools/guard_fail_on_placeholders.sh"]
        language: system
        pass_filenames: false
        stages: [pre-commit]

      - id: guard-no-jupyterlab-in-runtime
        name: "guard: jupyterlab must stay in dev"
        entry: bash
        args:
          - -lc
          - |
            grep -q "^jupyterlab" requirements.txt \
              && { echo "jupyterlab doit rester dans requirements-dev.txt"; exit 1; } \
              || exit 0
        language: system
        files: ^requirements\.txt$
        stages: [pre-commit]

      - id: guard-pip-constraint
        name: "guard: pip installs must use constraints (env ou inline)"
        entry: bash
        args:
          - -lc
          - |
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
        language: system
        files: ^(.*\.(sh|bash|zsh|ps1|py|md|yml|yaml)|Makefile)$
        stages: [pre-commit, pre-push]
YAML

echo "[INFO] .pre-commit-config.yaml écrit."
echo "[HINT] Tu peux lancer : pre-commit validate-config && pre-commit run --all-files || true"
