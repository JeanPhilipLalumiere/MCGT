#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: bash finalize_packaging.sh [repo_root]
REPO_ROOT="${1:-.}"
cd "$REPO_ROOT"

echo "== finalize packaging =="
echo "Repo: $(pwd)"
echo

echo "== git status (short) =="
git status -s || true
echo

# 1) Nettoyage des champs 'license' hérités côté setup.py / setup.cfg (source de vérité = pyproject.toml)
if [[ -f setup.py ]]; then
  cp -n setup.py "setup.py.bak.$(date -u +%Y%m%dT%H%M%SZ)" || true
  # Retire 'license=' seul ou au milieu d'autres kwargs (idempotent)
  sed -i -E 's/,\s*license\s*=\s*["'\''"][^"'\''"]*["'\''']//; /^\s*license\s*=\s*["'\''"][^"'\''"]*["'\''"]\s*,?\s*$/d' setup.py || true
fi

if [[ -f setup.cfg ]]; then
  cp -n setup.cfg "setup.cfg.bak.$(date -u +%Y%m%dT%H%M%SZ)" || true
  # Supprime une éventuelle clé metadata:license
  sed -i -E '/^\s*license\s*=/d' setup.cfg || true
fi

# 2) .gitignore local pour scripts/archives auxiliaires (sans dupliquer)
add_ignore() {
  local pat="$1"
  grep -qxF "$pat" .gitignore 2>/dev/null || echo "$pat" >> .gitignore
}
touch .gitignore
add_ignore ""
add_ignore "# Helpers locaux (non versionnés)"
add_ignore "/dist_doctor.sh"
add_ignore "/resolve_twine_license_error.sh"
add_ignore "/twine_fix_v2.sh"
add_ignore "/repair_pkg_metadata.sh"
add_ignore "/sanitize_metadata.sh"
add_ignore "/spdx_futureproof_patch.sh"
add_ignore "/pyproject.toml.twine*"
add_ignore "/pyproject.toml.spdxbak.*"
add_ignore "/.bkp_pkgmeta_*/"

echo
echo "== Stage & commit ciblé (pyproject/setup.cfg/setup.py/.gitignore) =="
git add -A :/pyproject.toml :/setup.cfg :/setup.py :/.gitignore || true
# Commit seulement s'il y a quelque chose à committer
if ! git diff --cached --quiet; then
  git -c commit.gpgsign=false commit -m "build(metadata): settle SPDX license + cleanup legacy fields; ignore local helpers" || true
  git pull --rebase --autostash || true
  git push || true
else
  echo "(rien à committer)"
fi

echo
echo "== Build sdist + wheel =="
python -m build

echo
SDIST="$(ls -1t dist/*.tar.gz | head -n1)"
WHEEL="$(ls -1t dist/*.whl    | head -n1)"
echo "sdist: $SDIST"
echo "wheel: $WHEEL"

echo
echo "=== PKG-INFO (sdist, head) ==="
tar -xOf "$SDIST" "*/PKG-INFO" | sed -n '1,80p' || { echo "!! PKG-INFO introuvable"; true; }

echo
echo "=== METADATA (wheel, head) ==="
unzip -p "$WHEEL" "$(unzip -Z1 "$WHEEL" | grep -E '^[^/]+\.dist-info/METADATA$' | head -n1)" | sed -n '1,80p'

echo
echo "=== twine check ==="
twine check "$SDIST" "$WHEEL"

echo
echo "=== (Optionnel) relance des guards si présents sur la branche courante ==="
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
for wf in readme-guard.yml manifest-guard.yml guard-ignore-and-sdist.yml; do
  if gh workflow view "$wf" >/dev/null 2>&1; then
    echo "→ Trigger $wf on $BRANCH"
    gh workflow run "$wf" -r "$BRANCH" || true
  fi
done

echo
echo "Done."
