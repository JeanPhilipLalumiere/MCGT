#!/usr/bin/env bash
# set -euo pipefail
# [ -f README.md ] || echo "# MCGT" > README.md
# perl -0777 -pe 's/<!-- CI:BEGIN -->.*?<!-- CI:END -->/<!-- CI:BEGIN -->\n### CI (Workflows canoniques)\n- sanity-main.yml\n- sanity-echo.yml\n- ci-yaml-check.yml\n\nVoir docs/CI.md.\n<!-- CI:END -->/s' -i README.md

# Si les marqueurs n'existent pas, on les ajoute à la fin

# if ! grep -q "<!-- CI:BEGIN -->" README.md; then
# cat >> README.md <<'MD'

# <!-- CI:BEGIN -->
# CI (Workflows canoniques)

# sanity-main.yml

# sanity-echo.yml

# ci-yaml-check.yml

# Voir docs/CI.md.

<!-- CI:END -->

MD
fi
echo "[OK] README.md encart CI normalisé"
