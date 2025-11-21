#!/usr/bin/env bash
set -Eeuo pipefail

# À exécuter depuis la racine du dépôt Git
cat >> README.md <<'MD'

### Installation (depuis TestPyPI)
```bash
pip install --index-url https://test.pypi.org/simple \
            --extra-index-url https://pypi.org/simple \
            zz-tools==0.3.1
```
MD

git add README.md
git -c commit.gpgsign=false commit -m "docs(readme): add TestPyPI install instructions"
git push
