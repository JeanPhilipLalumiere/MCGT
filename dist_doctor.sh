#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: bash dist_doctor.sh [repo_root]
cd "${1:-.}"

echo "== dist doctor =="
SDIST="${SDIST:-$(ls -1t dist/*.tar.gz 2>/dev/null | head -n1 || true)}"
WHEEL="${WHEEL:-$(ls -1t dist/*.whl 2>/dev/null | head -n1 || true)}"

if [[ -z "${SDIST}" ]]; then echo "!! Aucun sdist trouvé"; else echo "sdist: $SDIST"; fi
if [[ -z "${WHEEL}" ]]; then echo "!! Aucun wheel trouvé"; else echo "wheel: $WHEEL"; fi

if [[ -n "${SDIST}" ]]; then
  echo -e "\n=== PKG-INFO (sdist) ==="
  TOPDIR="$(tar -tzf "$SDIST" | head -n1 | cut -d/ -f1)"
  if tar -tzf "$SDIST" | grep -q "^${TOPDIR}/PKG-INFO$"; then
      tar -xOf "$SDIST" "${TOPDIR}/PKG-INFO" | sed -n '1,120p'
  else
      echo "!! PKG-INFO introuvable au chemin attendu (${TOPDIR}/PKG-INFO). Listing:"
      tar -tzf "$SDIST" | sed -n '1,80p'
  fi
fi

if [[ -n "${WHEEL}" ]]; then
  echo -e "\n=== METADATA (wheel) ==="
  META_PATH="$(unzip -Z1 "$WHEEL" | grep -E '^[^/]+\.dist-info/METADATA$' | head -n1 || true)"
  if [[ -n "${META_PATH}" ]]; then
    unzip -p "$WHEEL" "$META_PATH" | sed -n '1,120p'
  else
    echo "!! METADATA introuvable — contenu :"; unzip -l "$WHEEL" | sed -n '1,80p'
  fi
fi

echo -e "\n=== Champs licence dans pyproject.toml ==="
grep -nE '^(license|license-files|dynamic)\s*=' pyproject.toml || true

echo -e "\n=== Champs licence potentiels dans setup.py ==="
grep -nE 'license\s*=' setup.py || echo "(aucun 'license=' dans setup.py)"

echo -e "\n=== twine check (sdist + wheel) ==="
if command -v twine >/dev/null 2>&1; then
  if [[ -n "${SDIST}" || -n "${WHEEL}" ]]; then
    twine check ${SDIST:+\"$SDIST\"} ${WHEEL:+\"$WHEEL\"} || true
  else
    echo "Rien à vérifier."
  fi
else
  echo "twine non installé"
fi

echo -e "\nTip: PKG-INFO d'un sdist est à '<topdir>/PKG-INFO', pas 'zz_tools.egg-info/PKG-INFO'."
