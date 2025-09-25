#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: scripts/preflight_release.sh <version ex: 0.2.28>"
  exit 2
fi

VER="$1"
echo "==> Preflight pour mcgt-core v${VER}"

# A) Cohérence pyproject <-> __init__ <-> cible
PY_VER="$(python - <<'PY'
import tomllib, pathlib, re
pp = pathlib.Path("pyproject.toml").read_text("utf-8")
pver = tomllib.loads(pp).get("project",{}).get("version")
init = pathlib.Path("mcgt/__init__.py").read_text("utf-8")
m = re.search(r'__version__\s*=\s*"([^"]+)"', init)
iver = m.group(1) if m else "?"
print(pver); print(iver)
PY
)"
set -- $PY_VER
PVER="$1"; IVER="$2"
echo "   pyproject.version = ${PVER}"
echo "   __init__.__version__ = ${IVER}"
if [[ "$PVER" != "$VER" ]] || [[ "$IVER" != "$VER" ]]; then
  echo "❌ Versions désalignées (pyproject=${PVER}, __init__=${IVER}, cible=${VER})."
  echo "   Corrige d'abord: sed -i -E 's/(^version\\s*=\\s*\")[0-9]+\\.[0-9]+\\.[0-9]+(\")/\\1${VER}\\2/' pyproject.toml"
  echo "                    sed -i -E 's/^(__version__\\s*=\\s*\")[0-9]+\\.[0-9]+\\.[0-9]+(\")/\\1${VER}\\2/' mcgt/__init__.py"
  exit 1
fi

# B) Workflow de publication présent et correctement déclenché
WF=".github/workflows/publish.yml"
[[ -f "$WF" ]] || { echo "❌ ${WF} manquant"; exit 1; }

if ! grep -qE '^\s*workflow_dispatch:' "$WF"; then
  echo "❌ ${WF} n'expose pas 'workflow_dispatch:'"
  exit 1
fi
if ! awk 'BEGIN{ok=0} $0 ~ /^on:/ {in_on=1} in_on && /push:/ {p=1} p && /tags:/ {t=1} t && /"v\*"/ {ok=1} END{exit !ok}' "$WF"; then
  echo "❌ ${WF} n'a pas le trigger push->tags 'v*'"
  exit 1
fi

# C) Empêcher le 400 'File already exists' (si tu relances sur une version publiée)
if pip index versions mcgt-core 2>/dev/null | grep -q " ${VER}$"; then
  echo "❌ mcgt-core==${VER} est déjà sur PyPI. Choisis une nouvelle version (patch +1)."
  exit 1
fi

echo "✅ Preflight OK pour ${VER}"
