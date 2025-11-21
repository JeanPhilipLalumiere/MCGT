#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

echo "== PyPI Upload Doctor =="

#--- helpers ---------------------------------------------------------------
log(){ printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*"; }
die(){ err "$*"; exit 1; }

#--- prerequisites ---------------------------------------------------------
need_cmd(){ command -v "$1" >/dev/null 2>&1 || die "Commande requise manquante: $1"; }
for c in python3 twine tar unzip sed awk grep; do need_cmd "$c"; done
if ! command -v curl >/dev/null 2>&1; then
  warn "curl non trouvé — saut du test d'existence du projet sur PyPI"
  NO_CURL=1
else
  NO_CURL=0
fi

#--- locate distributions --------------------------------------------------
shopt -s nullglob
dists=(dist/*.whl dist/*.tar.gz dist/*.zip)
shopt -u nullglob
((${#dists[@]})) || die "Aucun fichier de distribution trouvé dans ./dist"
log "Artefacts trouvés:"
for f in "${dists[@]}"; do echo "  - ${f}"; done

#--- extract Name/Version from metadata -----------------------------------
NAME=""
VERSION=""

# Try sdist PKG-INFO first
if compgen -G "dist/*.tar.gz" >/dev/null; then
  sdist=$(ls -1 dist/*.tar.gz | head -n1)
  if tar -tf "$sdist" | grep -qE '.*/PKG-INFO$'; then
    NAME=$(tar -xOf "$sdist" */PKG-INFO 2>/dev/null | awk -F': ' '/^Name:/{print $2; exit}')
    VERSION=$(tar -xOf "$sdist" */PKG-INFO 2>/dev/null | awk -F': ' '/^Version:/{print $2; exit}')
  fi
fi

# Fallback to wheel METADATA
if [[ -z "${NAME}" || -z "${VERSION}" ]] && compgen -G "dist/*.whl" >/dev/null; then
  wheel=$(ls -1 dist/*.whl | head -n1)
  meta_path=$(unzip -Z1 "$wheel" | grep -E '^[^/]+\.dist-info/METADATA$' | head -n1 || true)
  if [[ -n "$meta_path" ]]; then
    NAME=$(unzip -p "$wheel" "$meta_path" | awk -F': ' '/^Name:/{print $2; exit}')
    VERSION=$(unzip -p "$wheel" "$meta_path" | awk -F': ' '/^Version:/{print $2; exit}')
  fi
fi

[[ -n "$NAME" ]] || die "Impossible de lire 'Name' dans PKG-INFO/METADATA"
[[ -n "$VERSION" ]] || die "Impossible de lire 'Version' dans PKG-INFO/METADATA"

CANON="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')"
log "Projet: $NAME  (canonique: $CANON)  | Version: $VERSION"

#--- show environment ------------------------------------------------------
log "Environnement Twine"
echo "  TWINE_USERNAME=${TWINE_USERNAME-<non défini>}"
if [[ -n "${TWINE_PASSWORD-}" ]]; then
  pwlen=$(printf %s "$TWINE_PASSWORD" | wc -c | awk '{print $1}')
  has_nl="non"
  printf %s "$TWINE_PASSWORD" | grep -q $'\n' && has_nl="OUI"
  has_cr="non"
  printf %s "$TWINE_PASSWORD" | grep -q $'\r' && has_cr="OUI"
  echo "  TWINE_PASSWORD: défini (longueur=$pwlen, newline=$has_nl, CR=$has_cr)"
else
  echo "  TWINE_PASSWORD: <non défini>"
fi
echo "  TWINE_REPOSITORY=${TWINE_REPOSITORY-pypi}"
echo "  TWINE_REPOSITORY_URL=${TWINE_REPOSITORY_URL-<vide>}"

#--- check if project exists on PyPI --------------------------------------
if [[ "$NO_CURL" -eq 0 ]]; then
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/${CANON}/json" || true)
  if [[ "$code" == "200" ]]; then
    log "Projet déjà EXISTANT sur PyPI (prod). Un token 'Project: ${CANON}' suffit."
    EXISTS=1
  elif [[ "$code" == "404" ]]; then
    warn "Projet INEXISTANT sur PyPI (prod). Premier upload: token 'Entire account' requis."
    EXISTS=0
  else
    warn "Impossible de déterminer l'existence du projet (HTTP $code)."
    EXISTS=-1
  fi
else
  EXISTS=-1
fi

#--- run twine check -------------------------------------------------------
log "twine check ..."
set +e
twine check "${dists[@]}"
twine_rc=$?
set -e
if [[ $twine_rc -ne 0 ]]; then
  die "twine check a échoué (rc=$twine_rc) — corrige avant upload."
fi
log "twine check: OK"

#--- guidance --------------------------------------------------------------
echo
echo "== Conseils =="
if [[ "${TWINE_USERNAME-}" != "__token__" ]]; then
  warn "TWINE_USERNAME devrait être '__token__' pour un token API PyPI."
fi
if [[ -z "${TWINE_PASSWORD-}" ]]; then
  warn "TWINE_PASSWORD non défini — exporte ton token PyPI: export TWINE_PASSWORD='pypi-...'" 
else
  if printf %s "$TWINE_PASSWORD" | grep -q $'\r\|\n'; then
    warn "Ton token contient probablement un retour chariot / fin de ligne. Corrige avec: export TWINE_PASSWORD="$(printf %s "$TWINE_PASSWORD" | tr -d '\r\n')""
  fi
fi

if [[ "$EXISTS" == "0" ]]; then
  echo "  * Comme le projet n'existe pas encore: crée un token 'Entire account (all projects)' sur PyPI (prod)."
fi
echo "  * Dépôt visé: ${TWINE_REPOSITORY_URL-<défaut PyPI prod ou TWINE_REPOSITORY>}"
echo
echo "== Étape suivante =="
echo "  bash pypi_upload_try.sh   # lance l'upload (utilise tes variables TWINE_*)"
echo
echo "Fini."
