#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -Eeuo pipefail

cfg=".pre-commit-config.yaml"
[[ -f "$cfg" ]] || {
  echo "[ERREUR] $cfg introuvable"
  exit 1
}

# 1) Supprime un bloc éventuel pour mvdan/sh
awk '
  BEGIN{skip=0}
  /^  - repo: https:\/\/github\.com\/mvdan\/sh$/ {skip=1; next}
  skip && /^  - repo: / {skip=0}
  !skip {print}
' "$cfg" >"$cfg.new" && mv "$cfg.new" "$cfg"

# 2) Ajoute le bloc officiel pour shfmt si absent
grep -q 'repo: https://github.com/scop/pre-commit-shfmt' "$cfg" || cat >>"$cfg" <<'YAML'

  - repo: https://github.com/scop/pre-commit-shfmt
    # Tag compatible avec shfmt 3.7.0; "pre-commit autoupdate" fera le bump si besoin
    rev: v3.7.0-1
    hooks:
      - id: shfmt
        args: ["-w","-i","2","-ci"]
        files: "^(tools/|zz-scripts/).+\\.(sh|bash)$"
YAML

echo "[INFO] Hook shfmt OK dans $cfg"
