#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -Eeuo pipefail
grep -q 'repo: https://github.com/mvdan/sh' .pre-commit-config.yaml && {
  echo "[INFO] shfmt déjà présent dans .pre-commit-config.yaml"
  exit 0
}
cat >>.pre-commit-config.yaml <<'YAML'

  - repo: https://github.com/mvdan/sh
    rev: v3.7.0
    hooks:
      - id: shfmt
        args: ["-w","-i","2","-ci"]
        files: "^(tools/|zz-scripts/).+\\.(sh|bash)$"
YAML

echo "[INFO] Ajouté. Exécution : pre-commit autoupdate && pre-commit run -a"
