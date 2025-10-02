#!/usr/bin/env bash
set -euo pipefail
CFG=".pre-commit-config.yaml"
touch "$CFG"

add_block () {
  local id="$1"; shift
  local block="$1"; shift
  if ! grep -qE "^\s*-+\s*id:\s*${id}\b" "$CFG"; then
    printf "\n%s\n" "$block" >> "$CFG"
    echo "Added hook: ${id}"
  else
    echo "Kept hook: ${id}"
  fi
}

ACTIONLINT_BLOCK="$(cat <<'EOF'
- repo: https://github.com/rhysd/actionlint
  rev: v1.7.1
  hooks:
    - id: actionlint
EOF
)"

SHELLCHECK_BLOCK="$(cat <<'EOF'
- repo: https://github.com/shellcheck-py/shellcheck-py
  rev: v0.10.0.1
  hooks:
    - id: shellcheck
      args: [ "-S", "style", "-x" ]
      files: ^tools/.*\.sh$
EOF
)"

add_block "actionlint"  "$ACTIONLINT_BLOCK"
add_block "shellcheck"  "$SHELLCHECK_BLOCK"
echo "Done. You can run: pre-commit autoupdate && pre-commit run -a"
