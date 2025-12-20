\
#!/usr/bin/env bash
# list_cli_like.sh — uses the same heuristic as sweep_v2 to list files that will receive `-h`

set -u
mapfile -t PYFILES < <(git ls-files '*.py' 2>/dev/null || find . -type f -name '*.py')

is_cli_like() {
  local f="$1"
  case "$f" in
    *"/tests/"*|*"/utils/"*|*"/_common/"*|*"__init__.py") return 1;;
  esac
  grep -qE 'argparse|ArgumentParser|add_argument' "$f" || return 1
  return 0
}

for f in "${PYFILES[@]}"; do
  case "$f" in
    *"/_attic/"*|*"/_tmp/"*|*"/.eggs/"*|*"/site-packages/"*|*"/build/"*|*"/dist/"*) continue;;
  esac
  if is_cli_like "$f"; then
    echo "$f"
  fi
done
