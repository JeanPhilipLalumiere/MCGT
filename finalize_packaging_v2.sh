#!/usr/bin/env bash
# finalize_packaging_v2.sh — corrige le packaging, commit/push si besoin, rebuild, et twine check
# Usage: bash finalize_packaging_v2.sh [/chemin/vers/repo]
set -Eeuo pipefail

REPO_PATH="${1:-$PWD}"

echo "== finalize packaging v2 =="
echo "Repo: $REPO_PATH"

if [[ ! -d "$REPO_PATH/.git" ]]; then
  echo "!! Ce répertoire n'est pas un repo git: $REPO_PATH" >&2
  exit 1
fi

cd "$REPO_PATH"

# --- helpers ---
has_cmd() { command -v "$1" >/dev/null 2>&1; }
git_dirty() { ! git diff --quiet || ! git diff --cached --quiet; }
ensure_line_in_file() {
  local line="$1" file="$2"
  [[ -f "$file" ]] || touch "$file"
  grep -Fqx "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

# --- contexte ---
BRANCH="$(git rev-parse --abbrev-ref HEAD || echo main)"
echo "Branche: $BRANCH"

# --- 1) Nettoyage licences héritées côté setup.* (source de vérité = pyproject.toml) ---
if [[ -f setup.py ]]; then
  # supprime license="..." seul sur une ligne
  sed -i.bak -E 's/^[[:space:]]*license[[:space:]]*=[[:space:]]*["'"'"'][^"'"'"']*["'"'"'][[:space:]]*,?[[:space:]]*$//g' setup.py
  # supprime occurence inline ", license='MIT'"
  sed -i -E 's/,[[:space:]]*license[[:space:]]*=[[:space:]]*["'"'"'][^"'"'"']*["'"'"']//g' setup.py
fi

if [[ -f setup.cfg ]]; then
  # retire "license =" dans [metadata] si présent
  sed -i.bak -E '/^\[metadata\]/,/^\[/{s/^[[:space:]]*license[[:space:]]*=.*$//}' setup.cfg
fi

# --- 2) .gitignore : ignorer scripts locaux utilitaires (idempotent) ---
ensure_line_in_file "# Local packaging helpers" .gitignore
for f in resolve_twine_license_error.sh twine_fix_v2.sh finalize_packaging.sh finalize_packaging_v2.sh dist_doctor.sh sanitize_metadata.sh repair_pkg_metadata.sh spdx_futureproof_patch.sh; do
  ensure_line_in_file "$f" .gitignore
done

# --- 3) Commit ciblé si des changements existent ---
if git_dirty; then
  git add -A
  git -c commit.gpgsign=false commit -m "build(packaging): normalize license source (pyproject), ignore local helpers"
  git push
else
  echo "Aucun changement à committer."
fi

# --- 4) Rebuild sdist + wheel frais ---
if ! has_cmd python3; then
  echo "!! python3 introuvable." >&2
  exit 2
fi
if ! python3 -c "import build" 2>/dev/null; then
  python3 -m pip install -U build >/dev/null
fi

rm -rf dist
python3 -m build --sdist --wheel

SDIST="$(ls -1t dist/*.tar.gz | head -n1)"
WHEEL="$(ls -1t dist/*.whl    | head -n1)"
echo "sdist: ${SDIST:-<none>}"
echo "wheel: ${WHEEL:-<none>}"

# --- 5) Inspect PKG-INFO du sdist (sans supposer le chemin interne) ---
echo
echo "=== Inspect PKG-INFO (sdist: head) ==="
if [[ -n "${SDIST:-}" ]]; then
  PKGINFO_PATH="$(tar -tf "$SDIST" | grep -E '/PKG-INFO$' | head -n1 || true)"
  if [[ -n "${PKGINFO_PATH:-}" ]]; then
    tar -xOf "$SDIST" "$PKGINFO_PATH" | sed -n '1,120p'
  else
    echo "!! PKG-INFO introuvable dans l’archive"
  fi
else
  echo "!! Pas de sdist trouvé"
fi

# --- 6) Inspect METADATA du wheel ---
echo
echo "=== Inspect METADATA (wheel: head) ==="
if [[ -n "${WHEEL:-}" ]]; then
  META_PATH="$(unzip -Z1 "$WHEEL" | grep -E '^[^/]+\.dist-info/METADATA$' | head -n1 || true)"
  if [[ -n "${META_PATH:-}" ]]; then
    unzip -p "$WHEEL" "$META_PATH" | sed -n '1,120p'
  else
    echo "!! METADATA introuvable dans le wheel"
  fi
else
  echo "!! Pas de wheel trouvé"
fi

# --- 7) twine check sdist + wheel ---
echo
echo "=== twine check ==="
if ! has_cmd twine; then
  python3 -m pip install -U twine >/dev/null
fi
if [[ -n "${SDIST:-}" && -n "${WHEEL:-}" ]]; then
  twine check "$SDIST" "$WHEEL" || { echo "twine check a signalé une erreur"; exit 3; }
else
  echo "!! Fichiers dist manquants pour twine"
  exit 3
fi

# --- 8) Relance optionnelle des guards s'ils existent (best effort) ---
echo
echo "=== Trigger guards (best-effort) ==="
trigger() {
  local wf="$1"
  if [[ -f ".github/workflows/$wf" ]] && has_cmd gh; then
    gh workflow run "$wf" -r "$BRANCH" || true
    echo "↳ trigger: $wf"
  fi
}
trigger "readme-guard.yml"
trigger "manifest-guard.yml"
trigger "guard-ignore-and-sdist.yml"

echo
echo "Done."
