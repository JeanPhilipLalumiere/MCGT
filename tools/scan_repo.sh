#!/usr/bin/env bash
set -Eeuo pipefail

out=".ci-out"
mkdir -p "$out"

ts() { date -u +%Y%m%dT%H%M%SZ; }

echo "[SCAN] start $(ts)" | tee "$out/scan_start.txt"

# 1) Workflows
{
  echo "[WORKFLOWS]"
  ls -1 .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null || true
} | tee "$out/workflows.list.txt"

# 2) Makefiles + var PYTHON
{
  echo "[MAKEFILES]"
  find . -type f -name 'Makefile' | sort || true
} | tee "$out/makefiles.list.txt"

{
  echo "[MAKE_PYTHON_VAR]"
  grep -Rnh '^[[:space:]]*PYTHON[[:space:]]*\?=' -- Makefile */Makefile 2>/dev/null | sort || true
} | tee "$out/makefiles.python_var.txt"

# 3) Markdown avec front-matter (chemins uniquement)
{
  echo "[MD_FRONTMATTER_PATHS]"
  grep -Rl '^---[[:space:]]*$' -- */*.md 2>/dev/null | sort || true
} | tee "$out/md_frontmatter_paths.txt"

# 4) Python: constantes module-scope (première passe regex)
{
  echo "[PY_CONST_MODULES]"
  grep -Rnl '^[[:space:]]*[A-Z][A-Z0-9_]\{2,\}[[:space:]]*=' --include='*.py' . 2>/dev/null | sort || true
} | tee "$out/python_consts_modules.txt"

# 5) Figures hors convention
{
  echo "[FIG_BADNAMES]"
  find zz-figures -type f \( -name '*.png' -o -name '*.pdf' \) 2>/dev/null |
    grep -Ev '^zz-figures/chapter[0-9]{2}/[0-9]{2}_fig_[a-z0-9_]+\.(png|pdf)$' ||
    true
} | tee "$out/figures_bad_names.txt"

# 6) pyproject.toml présence
{
  echo "[PYPROJECT]"
  test -f pyproject.toml && echo "pyproject.toml" || echo "(absent)"
} | tee "$out/pyproject_presence.txt"

echo "[SCAN] done $(ts)" | tee "$out/scan_done.txt"
