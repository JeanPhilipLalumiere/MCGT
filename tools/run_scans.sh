#!/usr/bin/env bash
set -Eeuo pipefail

bash tools/scan_repo.sh
python tools/scan_frontmatter.py
python tools/scan_py_consts.py
python tools/scan_make_vars.py
python tools/scan_figures.py
bash tools/scan_ci_budgets.sh

echo ""
echo "== Résultats à me coller =="
echo ".ci-out/workflows.list.txt"
echo ".ci-out/md_frontmatter_paths.txt  (et le fichier .ci-out/frontmatter_samples.txt si non vide)"
echo ".ci-out/makefiles.list.txt"
echo ".ci-out/makefiles.python_var.txt"
echo ".ci-out/python_consts_modules.txt  ET/OU  .ci-out/python_consts.tsv"
echo ".ci-out/figures_bad_names.tsv"
echo ".ci-out/pyproject_presence.txt"
echo ""
echo "[tip] Si le front-matter samples est vide, colle au moins 1 fichier .md avec son bloc ---...---"
