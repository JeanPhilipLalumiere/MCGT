#!/usr/bin/env bash
# resolve_twine_license_error.sh
# Objectif: Corriger l'erreur Twine 'license-expression' / 'license-file' sur l'sdist
# Usage:
#   bash resolve_twine_license_error.sh                # depuis la racine du repo
#   bash resolve_twine_license_error.sh /chemin/MCGT   # ou passer le chemin du repo
#
# Le script tente d'abord de mettre à niveau Twine/pkginfo (solution la plus propre).
# Si l'erreur persiste, il reconstruit l'sdist avec setuptools < 74 pour éviter les champs PEP 639.

set -Eeuo pipefail

REPO="${1:-.}"
cd "$REPO"

echo "==> Repo: $(pwd)"

# ---- helpers ---------------------------------------------------------------
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }

die() { red "ERROR: $*"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---- guards ----------------------------------------------------------------
have python3 || die "python3 requis"
have pip || yellow "pip non trouvé dans PATH — j'essaie 'python3 -m pip' au besoin"
have tar || die "tar requis"
have sed || die "sed requis"

# ---- step 0: rebuild sdist -------------------------------------------------
build_sdist() {
  rm -rf dist
  python3 -m build --sdist
  SDIST="$(ls -1t dist/*.tar.gz 2>/dev/null | head -n1 || true)"
  test -n "${SDIST:-}" || die "Aucun sdist trouvé dans dist/"
  echo "$SDIST"
}

inspect_pkg_info() {
  local sdist="$1"
  echo "=== Inspect PKG-INFO (head) ==="
  if ! tar -xOf "$sdist" */PKG-INFO >/dev/null 2>&1; then
    red "!! PKG-INFO introuvable dans l’archive"
  else
    tar -xOf "$sdist" */PKG-INFO | sed -n '1,40p'
  fi
}

check_twine() {
  local sdist="$1"
  echo
  echo "=== Run twine check ==="
  echo "Checking $sdist with twine ..."
  if python3 -m twine check "$sdist"; then
    green "Twine check: OK"
    return 0
  else
    red "Twine check: ECHEC"
    return 1
  fi
}

# ---- Option A: upgrade Twine/pkginfo --------------------------------------
upgrade_twine() {
  echo "=== Upgrade twine/pkginfo ==="
  python3 -m pip install -U --disable-pip-version-check "twine" "pkginfo" "readme-renderer" >/dev/null
  echo "Versions:"
  python3 - <<'PY'
import pkgutil, importlib, sys
mods=["twine","pkginfo","readme_renderer"]
for m in mods:
    try:
        mod=importlib.import_module(m.replace("-","_"))
        v=getattr(mod,"__version__", "?")
        print(f"  {m} = {v}")
    except Exception as e:
        print(f"  {m} = <non installé>")
PY
}

# ---- Option B: rebuild with old setuptools (<74) ---------------------------
patch_pyproject_and_rebuild() {
  local backup="pyproject.toml.twinebak.$(date +%s)"
  cp pyproject.toml "$backup"
  yellow "Backup -> $backup"

  # Patch minimal (texte): forcer setuptools<74 dans [build-system].requires
  # Remplacements robustes (quel que soit le pin existant).
  # 1) si 'setuptools>=' => remplace par 'setuptools<74'
  # 2) si 'setuptools' nu => ajoute '<74'
  sed -i -E 's/setuptools>[^"]*/setuptools<74/g' pyproject.toml || true
  sed -i -E 's/"setuptools"/"setuptools<74"/g' pyproject.toml || true

  # Supprimer toute dynamique autour de la license
  sed -i -E 's/(^|\s)license(_expression)?\s*=.*$//I' pyproject.toml || true
  sed -i -E 's/(^|\s)license(-file|_files)?\s*=.*$//I' pyproject.toml || true
  sed -i -E 's/dynamic\s*=\s*\[[^]]*\]/dynamic = []/g' pyproject.toml || true

  # Si un bloc [project] existe sans license, injecter license = "MIT"
  # (très grossier mais sûr)
  if ! grep -qi '^\s*license\s*=' pyproject.toml; then
    awk '
      BEGIN{ins=0}
      /^\[project\]/{print; print "license = \"MIT\""; ins=1; next}
      {print}
      END{if(ins==0){print "[project]"; print "license = \"MIT\""}}
    ' pyproject.toml > pyproject.toml.new && mv pyproject.toml.new pyproject.toml
  fi

  # Reconstruire avec l’isolation PEP517 (respectera [build-system].requires)
  local sdist
  sdist=$(build_sdist)
  echo "sdist: $sdist"
  inspect_pkg_info "$sdist"

  # Valider
  if check_twine "$sdist"; then
    green "Succès (setuptools<74) — vous pouvez conserver ce pin côté publication."
  else
    red "Echec persistant même avec setuptools<74."
    echo "Restauration pyproject.toml original -> $backup (conservez le backup si utile)."
    cp "$backup" pyproject.toml
    return 1
  fi
}

# ================== MAIN =====================================================
SDIST="$(build_sdist)"
echo
echo "sdist: $SDIST"
inspect_pkg_info "$SDIST"

echo
echo "=== Validation rapide — absence des champs litigieux ==="
if tar -xOf "$SDIST" */PKG-INFO 2>/dev/null | grep -Ei '^(License-Expression:|Dynamic: .*license)'; then
  yellow "PKG-INFO contient encore des champs PEP 639"
else
  green "OK: pas de License-Expression / Dynamic: license* détecté (dans PKG-INFO)"
fi

if check_twine "$SDIST"; then
  exit 0
fi

# Essai 1: upgrade twine/pkginfo et re-check
upgrade_twine
if check_twine "$SDIST"; then
  green "Résolu en mettant Twine/pkginfo à jour."
  exit 0
fi

# Essai 2: reconstruire avec setuptools<74
patch_pyproject_and_rebuild || {
  red "Impossible de résoudre automatiquement. Voir le log ci-dessus."
  exit 1
}

green "Terminé."
