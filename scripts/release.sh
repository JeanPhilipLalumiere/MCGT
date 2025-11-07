#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: scripts/release.sh <version (ex: 0.2.23)>"
  exit 2
fi

VER="$1"
echo "==> Release mcgt-core v${VER}"

# 0) Sanity: outils
command -v gh >/dev/null || { echo "gh manquant (GitHub CLI)"; exit 2; }
command -v jq >/dev/null || { echo "jq manquant"; exit 2; }

# 1) Bump version (pyproject + __init__)
echo "==> Bump version"
sed -i -E "s/(^version\\s*=\\s*\")[0-9]+\\.[0-9]+\\.[0-9]+(\")/\\1${VER}\\2/" pyproject.toml || true
sed -i -E "s/^(__version__\\s*=\\s*\")[0-9]+\\.[0-9]+\\.[0-9]+(\")/\\1${VER}\\2/" mcgt/__init__.py

# 2) Build local rapide (sanity)
echo "==> Build local (sanity)"
python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U pip build >/dev/null
rm -rf dist build *.egg-info
python -m build

# 3) Commit + push
echo "==> Commit + push"
git add pyproject.toml mcgt/__init__.py
git commit -m "build: bump to ${VER} (match tag)" || true
git push || true

# 4) Tag + push tag
echo "==> Tag + push tag"
git tag -f "v${VER}"
git push -f origin "v${VER}"

# 5) Suivi du workflow
echo "==> Watch GH Actions run"
sleep 2
RUN_ID="$(gh run list --workflow publish.yml --limit 30 --json databaseId,headBranch,createdAt \
  | jq -r --arg v "v${VER}" '.[] | select(.headBranch==$v) | [.createdAt,.databaseId] | @tsv' \
  | sort -r | head -n1 | awk '{print $2}')"

if [[ -z "${RUN_ID}" ]]; then
  echo "Aucun run trouvé pour v${VER}. Vérifie que publish.yml est dans le commit tagué."
  exit 1
fi

gh run watch "${RUN_ID}"
JOB_ID="$(gh run view "${RUN_ID}" --json jobs --jq '.jobs[0].databaseId' || true)"
if [[ -n "${JOB_ID}" ]]; then
  echo "==> Extrait upload:"
  gh run view --job "${JOB_ID}" --log | sed -n '/Uploading/,/Post job cleanup/p' || true
fi

# 6) Vérif index PyPI et Phase 4
echo "==> PyPI index"
pip index versions mcgt-core || true

echo "==> Validation Phase 4"
VER="${VER}" ./phase4_validate.sh

# 7) Phase 5 – Prépare les docs si absents
[ -f POSTMORTEM.md ] || cat > POSTMORTEM.md <<'MD'
# Post-mortem publication mcgt-core

## Contexte
- Publication via GitHub Actions (tag v*), OIDC Trusted Publishing vers PyPI.

## Incidents résolus
- YAML de workflow tronqué ⇒ aucun run sur tag.
- Tags pointant sur des commits sans workflow complet.
- Dépendances runtime manquantes (`numpy`, `scipy`) ⇒ déclarées.

## Correctifs
- Workflow stable: build → vérif tag==version → publish.
- Script Phase 4 robuste (fenêtre maintenue ouverte).
- Procédure release automatisée (`scripts/release.sh`).

## Prévention
- Toujours bumper **pyproject** + **mcgt/__init__.py** ensemble.
- Commit puis tag sur **ce même commit**.
- Linter YAML en pré-commit.
MD

[ -f RELEASE_CHECKLIST.md ] || cat > RELEASE_CHECKLIST.md <<'MD'
# Release checklist mcgt-core

1. `git pull` (main à jour)
2. `scripts/release.sh X.Y.Z`
3. Vérifier:
   - GH Actions: build + "Publish to PyPI" ⇒ OK
   - `pip index versions mcgt-core` liste X.Y.Z
   - `VER=X.Y.Z ./phase4_validate.sh` ⇒ OK
4. Rédiger changelog si nécessaire et tag suivant prêt.
MD

echo "==> Release ${VER} terminé."
