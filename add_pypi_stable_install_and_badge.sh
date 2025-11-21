#!/usr/bin/env bash
set -Eeuo pipefail

# 2) Met à jour le README (bloc “Installation” → PyPI stable)
if ! grep -q "### Installation (version stable, PyPI)" README.md 2>/dev/null; then
  cat >> README.md <<'MD'

### Installation (version stable, PyPI)
```bash
pip install -U zz-tools
# ou version spécifique
# pip install zz-tools==0.3.1.post1
```
MD
  git add README.md
  git -c commit.gpgsign=false commit -m "docs(readme): add stable PyPI install (zz-tools)" || true
  git push
else
  echo "[INFO] Section 'Installation (version stable, PyPI)' déjà présente — skip append."
fi

# 3) (Optionnel) Badge PyPI
if ! grep -q "img.shields.io/pypi/v/zz-tools.svg" README.md 2>/dev/null; then
  sed -i '1i [![PyPI](https://img.shields.io/pypi/v/zz-tools.svg)](https://pypi.org/project/zz-tools/) ' README.md
  git add README.md
  git -c commit.gpgsign=false commit -m "docs(readme): add PyPI badge" || true
  git push
else
  echo "[INFO] Badge PyPI déjà présent — skip."
fi
