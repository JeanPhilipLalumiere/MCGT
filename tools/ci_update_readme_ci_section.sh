#!/usr/bin/env bash
set -euo pipefail

slug_from_remote() {
  local url
  url="$(git config --get remote.origin.url || true)"
  # gitea/https/ssh → extraire owner/repo
  echo "$url" | sed -E 's#.*github\.com[:/ ]([^/]+/[^/.]+)(\.git)?$#\1#'
}

REPO_SLUG="$(slug_from_remote)"
: "${REPO_SLUG:=JeanPhilipLalumiere/MCGT}"

README="README.md"
[[ -f "$README" ]] || echo "# MCGT" > "$README"

TMP="$(mktemp)"
cat > "$TMP" <<EOF
<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/${REPO_SLUG}/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/${REPO_SLUG}/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/${REPO_SLUG}/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/${REPO_SLUG}/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/${REPO_SLUG}/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/${REPO_SLUG}/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir \`docs/CI.md\`.
<!-- CI:END -->
EOF

BLOCK="$(cat "$TMP")"
export BLOCK

if grep -q "<!-- CI:BEGIN -->" "$README" && grep -q "<!-- CI:END -->" "$README"; then
  # Remplacement multiligne sûr (dotall)
  perl -0777 -pe 's/<!-- CI:BEGIN -->.*?<!-- CI:END -->/$ENV{BLOCK}/s' "$README" > "${README}.tmp"
  mv "${README}.tmp" "$README"
else
  printf "\n%s\n" "$BLOCK" >> "$README"
fi

rm -f "$TMP"
echo "README mis à jour pour ${REPO_SLUG}"
