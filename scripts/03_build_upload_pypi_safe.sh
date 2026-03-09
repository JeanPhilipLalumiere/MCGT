#!/usr/bin/env bash
# Objectif: builder + (optionnellement) uploader sur PyPI sans jamais fermer le shell.
# - pas de set -e
# - pas de exit
# - toutes les erreurs sont capturées et affichées, puis on CONTINUE

echo "🧭 Démarrage (mode safe). Heure: $(date)"

# -- helpers (sans exit) -------------------------------------------------------
info(){ printf "ℹ️  %s\n" "$*"; }
ok(){   printf "✅ %s\n" "$*"; }
warn(){ printf "⚠️  %s\n" "$*" >&2; }
err(){  printf "❌ %s\n" "$*" >&2; }

# -- se placer à la racine du repo --------------------------------------------
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$repo_root" ]; then
  err "Pas dans un dépôt Git. Je continue quand même, mais il se peut que 'python -m build' échoue."
  repo_root="$(pwd)"
fi
cd "$repo_root" || { err "Impossible de cd dans $repo_root"; printf "\n"; }
info "Racine: $repo_root"

# -- détecter version & nom de package ----------------------------------------
VER="$(
python - <<'PY' 2>/dev/null || true
import re, pathlib
p = pathlib.Path("src/mcgt/__init__.py")
try:
    s = p.read_text(encoding="utf-8")
    m = re.search(r"^__version__\s*=\s*['\"](.+?)['\"]", s, re.M)
    print(m.group(1) if m else "")
except Exception:
    print("")
PY
)"
[ -n "$VER" ] && info "Version détectée: $VER" || warn "Version introuvable dans src/mcgt/__init__.py"

PKG="$(
python - <<'PY' 2>/dev/null || true
try:
    import tomllib, pathlib
    s = pathlib.Path("pyproject.toml").read_bytes()
    d = tomllib.loads(s)
    print(d.get("project",{}).get("name","mcgt-core"))
except Exception:
    print("mcgt-core")
PY
)"
info "Nom PyPI: $PKG"

# -- build propre --------------------------------------------------------------
info "Nettoyage dist/ build/ *.egg-info"
rm -rf dist build ./*.egg-info 2>/dev/null || true

info "Build (python -m build)…"
python -m build
BUILD_CODE=$?
if [ $BUILD_CODE -ne 0 ]; then
  err "Build a renvoyé $BUILD_CODE (je continue quand même)."
else
  ok "Build OK"
fi

# -- vérification des artifacts ------------------------------------------------
if ls dist/* >/dev/null 2>&1; then
  info "twine check dist/*"
  python -m twine check dist/* || warn "twine check a signalé des avertissements/erreurs (je continue)."
else
  warn "Aucun artifact dans dist/ (je continue)."
fi

# -- upload PyPI (optionnel, via PYPI_API_TOKEN) ------------------------------
if [ -n "${PYPI_API_TOKEN-}" ]; then
  info "Upload PyPI (--skip-existing)…"
  TWINE_USERNAME="__token__" TWINE_PASSWORD="$PYPI_API_TOKEN" \
  python -m twine upload --skip-existing dist/* 2>&1 \
  || err "Upload PyPI a échoué (mais on continue)."
  : # no-op
else
  warn "PYPI_API_TOKEN non défini -> je saute l’upload PyPI."
fi

# -- test d’installation hors repo (best effort) ------------------------------
if [ -n "$VER" ]; then
  info "Test d’installation propre hors repo (/tmp)…"
  TMPVENV="/tmp/venv-${PKG//[^A-Za-z0-9]/_}-${VER//[^A-Za-z0-9]/_}"
  python -m venv "$TMPVENV" 2>/dev/null || warn "Impossible de créer un venv (je continue)."
  if [ -x "$TMPVENV/bin/pip" ]; then
    "$TMPVENV/bin/pip" install -U pip >/dev/null 2>&1 || true
    ( cd /tmp && "$TMPVENV/bin/pip" install "${PKG}==${VER}" ) \
      && ok "pip install ${PKG}==${VER} OK" \
      || warn "pip install ${PKG}==${VER} a échoué (peut-être pas publié encore)."
    "$TMPVENV/bin/python" -c "import mcgt,sys; print('import mcgt ->', mcgt.__version__, 'from', mcgt.__file__)" \
      || warn "import mcgt a échoué dans le venv de test."
    "$TMPVENV/bin/python" -m mcgt --version \
      || warn "'python -m mcgt --version' a échoué dans le venv de test."
  else
    warn "Pas de pip exécutable dans le venv de test (je continue)."
  fi
else
  warn "Version inconnue -> je saute le test d’installation."
fi

echo "🏁 Fin du script (safe). Rien n’a quitté ton shell."
