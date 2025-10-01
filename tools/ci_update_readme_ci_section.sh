#!/usr/bin/env bash
set -euo pipefail

slug_from_remote() {
  local url
  url="$(git config --get remote.origin.url || true)"
  # gitea/https/ssh → extraire owner/repo
  echo "$url" | sed -E 's#.*github\.com[:/ ]([^/]+/[^/.]+)(\.git)?$#\1#'
}

REPO_SLUG="$(slug_from_remote)"
if [[ -z "${REPO_SLUG:-}" ]]; then
  # fallback si non détecté
  REPO_SLUG="JeanPhilipLalumiere/MCGT"
fi

readme="README.md"
[[ -f "$readme" ]] || echo "# MCGT" > "$readme"

tmp="$(mktemp)"
cat > "$tmp" <<EOF
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

# Remplacement entre marqueurs si présents; sinon append
if grep -q "<!-- CI:BEGIN -->" "$readme" && grep -q "<!-- CI:END -->" "$readme"; then
  awk -v RS= -v r="$(cat "$tmp")" '
  BEGIN{FS="\n"}
  {
    gsub(/<!-- CI:BEGIN -->.*<!-- CI:END -->/s, r)
    print
  }' "$readme" > "${readme}.tmp"
  mv "${readme}.tmp" "$readme"
else
  {
    echo
    cat "$tmp"
  } >> "$readme"
fi

rm -f "$tmp"
echo "README mis à jour avec les badges pour ${REPO_SLUG}"
