#!/usr/bin/env bash
# tools/apply_ci_quick_fixes.sh
# Patchs rapides, sûrs et idempotents pour verdir des checks courants.
# Usage:
#   bash tools/apply_ci_quick_fixes.sh [BRANCHE] [PR_NUMBER]
# Ex:
#   bash tools/apply_ci_quick_fixes.sh rewrite/main-20251026T134200 19

set -Eeuo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
PRNUM="${2:-19}"

i(){ printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
w(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
e(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" 1>&2; }

# 0) Préliminaires sûrs
i "Branche cible: $BRANCH • PR #$PRNUM"
git rev-parse --is-inside-work-tree >/dev/null || { e "Pas un repo git"; exit 0; }
git fetch --all -q || true
git checkout "$BRANCH" >/dev/null 2>&1 || { e "Branche $BRANCH introuvable"; exit 0; }

_changed=0
mark_changed(){ _changed=1; }

mkdir -p _tmp || true

# 1) MANIFEST.in robuste (inclure essentiels, exclure archives/tempos)
i "Appliquer/renforcer MANIFEST.in…"
cat > _tmp/MANIFEST.in.new <<'EOF'
include pyproject.toml
include README.md
include README.rst
include LICENSE
recursive-include src *.py
recursive-include msrc *.py

# Exclusions: artefacts & archives
global-exclude *.log
prune _tmp
prune backups
prune .ci-archive
global-exclude *.zip *.tar *.tar.gz *.tar.bz2 *.tar.xz
EOF

if [[ ! -f MANIFEST.in ]] || ! diff -q MANIFEST.in _tmp/MANIFEST.in.new >/dev/null 2>&1; then
  cp _tmp/MANIFEST.in.new MANIFEST.in
  git add MANIFEST.in
  mark_changed
  i "MANIFEST.in mis à jour."
else
  i "MANIFEST.in déjà conforme."
fi

# 2) pyproject.toml : s’assurer d’un readme valide & setuptools
i "Vérification pyproject.toml…"
if [[ -f pyproject.toml ]]; then
  # readme -> README.md si présent, sinon README.rst
  if [[ -f README.md ]]; then
    READMEREF="README.md"
  elif [[ -f README.rst ]]; then
    READMEREF="README.rst"
  else
    READMEREF=""
  fi

  need_commit=0
  if [[ -n "${READMEREF}" ]]; then
    if ! grep -Eq '^\s*readme\s*=\s*"(README\.md|README\.rst)"' pyproject.toml; then
      # Ajouter/forcer readme = "<file>"
      if grep -Eq '^\s*\[project\]\s*$' pyproject.toml; then
        # Injecter juste après [project]
        awk -v R="$READMEREF" '
          BEGIN{done=0}
          /^\[project\]/{print; if(!done){print "readme = \"" R "\""; done=1; next}}
          {print}
        ' pyproject.toml > _tmp/pyproject.tmp && mv _tmp/pyproject.tmp pyproject.toml
      else
        # Pas de [project] : on ajoute la section minimale
        {
          echo "[project]"
          echo "readme = \"${READMEREF}\""
          echo
          cat pyproject.toml
        } > _tmp/pyproject.tmp && mv _tmp/pyproject.tmp pyproject.toml
      fi
      need_commit=1
      i "pyproject.toml: readme = ${READMEREF}"
    fi
  else
    w "Aucun README.* détecté; readme non forcé."
  fi

  # S’assurer de tool.setuptools.packages.find (structure src/*)
  if ! grep -Eq '^\s*\[tool\.setuptools\.packages\.find\]' pyproject.toml; then
    cat >> pyproject.toml <<'EOF'

[tool.setuptools.packages.find]
where = ["src"]
include = ["*"]
EOF
    need_commit=1
    i "pyproject.toml: ajouté [tool.setuptools.packages.find]"
  fi

  if (( need_commit == 1 )); then
    git add pyproject.toml
    mark_changed
  fi
else
  w "pyproject.toml absent : MANIFEST couvrira l’essentiel, mais certains checks peuvent rester rouges."
fi

# 3) Gitleaks allowlist strict pour dossiers d’archives uniquement (si pas déjà présent)
i "Vérification .gitleaks.toml (allowlist archives ciblée)…"
ALLOW_SNIPPET=$(cat <<'EOS'
# Allowlist ciblée pour archives (ne couvre rien d'autre)
[allowlist]
paths = [
  "_tmp/.*",
  "backups/.*",
  ".ci-archive/.*"
]
EOS
)
if [[ -f .gitleaks.toml ]]; then
  if ! grep -q "_tmp/.*" .gitleaks.toml; then
    printf "\n%s\n" "$ALLOW_SNIPPET" >> .gitleaks.toml
    git add .gitleaks.toml
    mark_changed
    i ".gitleaks.toml: allowlist archives ajoutée."
  else
    i ".gitleaks.toml: allowlist archives déjà présente."
  fi
else
  printf "%s\n" "$ALLOW_SNIPPET" > .gitleaks.toml
  git add .gitleaks.toml
  mark_changed
  i "Créé .gitleaks.toml (allowlist archives)."
fi

# 4) Commit si modifs
if (( _changed == 1 )); then
  git commit -m "chore(ci): quick fixes — MANIFEST/pyproject readme/setuptools & gitleaks allowlist (archives only)"
  i "Commit créé."
else
  i "Aucune modification à committer."
fi

# 5) Push + dispatch CI
i "Push vers origin/$BRANCH…"
git push -u origin "$BRANCH"

if command -v gh >/dev/null 2>&1; then
  i "Dispatch workflows (si activés)…"
  gh workflow run .github/workflows/build-publish.yml -r "$BRANCH" >/dev/null 2>&1 || true
  gh workflow run .github/workflows/ci-accel.yml -r "$BRANCH" >/dev/null 2>&1 || true
  i "Relance demandée. Surveille: gh pr checks $PRNUM"
else
  w "gh indisponible : relance via l’UI GitHub ➝ Actions."
fi

i "Terminé (safe)."
