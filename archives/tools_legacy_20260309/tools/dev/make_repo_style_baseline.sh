#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"

echo "==> WIP checkpoint"
git add -A
git commit -m "WIP: before repo style baseline" || true

cat > setup.cfg <<'CFG'
[pycodestyle]
max-line-length = 100
ignore =
    E203,  # slice spacing (black compat)
    W503   # line break before binary operator

[tool:pytest]
addopts = -q

[isort]
profile = black
CFG

cat > .editorconfig <<'EC'
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
indent_style = space
indent_size = 4
max_line_length = 100
EC

git add setup.cfg .editorconfig
git commit -m "chore(style): add setup.cfg (pycodestyle=100) and .editorconfig" || true
git push || true
