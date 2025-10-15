#!/usr/bin/env bash
set -euo pipefail
WHEEL="$(ls dist/*.whl | head -n1)"
SDIST="$(ls dist/*.tar.gz | head -n1)"

# Wheel
if unzip -p "$WHEEL" */METADATA | grep -Eiq '^(License-Expression|License-File|Dynamic: license)'; then
  echo "[ERR] Wheel contient un champ PEP639 non désiré"; exit 1
fi

# Sdist (PKG-INFO peut être ailleurs selon l’emballage)
if tar -tzf "$SDIST" | grep -Eq '\.egg-info/PKG-INFO$'; then
  PKGINFO="$(tar -tzf "$SDIST" | grep '\.egg-info/PKG-INFO$' | head -n1)"
  if tar -xOf "$SDIST" "$PKGINFO" | grep -Eiq '^(License-Expression|License-File|Dynamic: license)'; then
    echo "[ERR] Sdist contient un champ PEP639 non désiré"; exit 1
  fi
fi

echo "[OK] métadonnées propres"
