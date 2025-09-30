#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: scripts/preflight_release.sh <version ex: 0.2.28> [package-name: default=mcgt]"
  exit 2
fi

VER="$1"
PKG_NAME="${2:-mcgt}"

echo "==> Preflight pour ${PKG_NAME} v${VER}"

# A) Cohérence pyproject <-> __init__ <-> cible
read -r PVER IVER <<EOF
$(python - <<'PY' "$VER"
import tomllib, pathlib, re, sys
ver = sys.argv[1]
pp = pathlib.Path("pyproject.toml").read_text("utf-8")
pver = tomllib.loads(pp).get("project",{}).get("version")
init_p = pathlib.Path("mcgt/__init__.py")
iver = "?"
if init_p.exists():
    m = re.search(r'__version__\s*=\s*"([^"]+)"', init_p.read_text("utf-8"))
    iver = m.group(1) if m else "?"
print(pver); print(iver)
PY
)
EOF

echo "   pyproject.version       = ${PVER}"
echo "   mcgt.__version__        = ${IVER}"
echo "   target (CLI argument)   = ${VER}"
if [[ "$PVER" != "$VER" ]] || [[ "$IVER" != "$VER" ]]; then
  echo "❌ Versions désalignées (pyproject=${PVER}, __init__=${IVER}, cible=${VER})."
  echo "   Corrige d'abord:"
  echo "     sed -i -E 's/(^version\\s*=\\s*\")[0-9]+\\.[0-9]+\\.[0-9]+(\")/\\1${VER}\\2/' pyproject.toml"
  echo "     sed -i -E 's/^(__version__\\s*=\\s*\")[0-9]+\\.[0-9]+\\.[0-9]+(\")/\\1${VER}\\2/' mcgt/__init__.py"
  exit 1
fi

# B) Présence workflow publication + triggers
WF=".github/workflows/publish.yml"
[[ -f "$WF" ]] || { echo "❌ ${WF} manquant"; exit 1; }
grep -qE '^\s*workflow_dispatch:' "$WF" || { echo "❌ ${WF} n'expose pas 'workflow_dispatch:'"; exit 1; }
awk 'BEGIN{ok=0} $0 ~ /^on:/ {in_on=1} in_on && /push:/ {p=1} p && /tags:/ {t=1} t && /"v\*"/ {ok=1} END{exit !ok}' "$WF" \
  || { echo "❌ ${WF} n'a pas le trigger push->tags 'v*'"; exit 1; }

# C) Empêcher la repub d'une version existante
if pip index versions "${PKG_NAME}" 2>/dev/null | grep -q " ${VER}$"; then
  echo "❌ ${PKG_NAME}==${VER} est déjà publié. Choisis une nouvelle version."
  exit 1
fi

# D) Fichiers clés
[[ -f pyproject.toml ]] || { echo "❌ pyproject.toml manquant"; exit 1; }
[[ -d mcgt ]] || { echo "❌ package 'mcgt/' manquant"; exit 1; }

echo "✅ Preflight OK pour ${PKG_NAME}==${VER}"
