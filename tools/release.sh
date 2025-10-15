#!/usr/bin/env bash
# tools/release.sh — publication zz-tools / MCGT
# - garde-fou TWINE (ne fuit pas sous set -x)
# - xcurl (curl silencieux si xtrace actif)
# - journalisation propre + LOG robuste
# - --dry-run / --skip-build / --skip-upload
# - détection version déjà sur PyPI (silencieux)

set -Eeuo pipefail

#######################################
# Early init (sûr sous set -u)
#######################################
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_PATH" )" && pwd -P )"
ROOT="$( cd "$SCRIPT_DIR/.." && pwd -P )"

: "${RELEASE_NO_PAUSE:=0}"
: "${RELEASE_SKIP_BUILD:=0}"
: "${RELEASE_SKIP_UPLOAD:=0}"
: "${RELEASE_TIMEOUT:=180}"
: "${RELEASE_GITHUB_TIMEOUT:=180}"
: "${RELEASE_PYPI_RETRY:=30}"
: "${LOG:=<none>}"   # sera fixé après parsing version

#######################################
# Utilitaires
#######################################
# curl silencieux quand xtrace est actif
xcurl() { ( set +x; curl "$@" ); }

die() { printf "[ERREUR] %s\n" "$*" >&2; exit 1; }
info(){ printf "[info] %s\n" "$*"; }
note(){ printf "%s\n" "$*"; }

run() {
  local title="$1"; shift
  printf "\n[RUN] %s\n>>> %s\n" "$title" "$*"
  "$@"
}

_pause() {
  local rc="$?"
  printf "\nFin du script (rc=%s). Log: %s\n" "$rc" "${LOG:-<none>}"
  # pause seulement si demandé (par défaut on pause)
  if [[ "${RELEASE_NO_PAUSE}" != "1" ]]; then
    # pas d'écho du token : simple prompt neutre
    read -r -p $'---\nAppuie sur Entrée pour fermer cette fenêtre…' _ || true
  fi
  return "$rc"
}
trap _pause EXIT

usage() {
  cat <<'USAGE'
Usage: tools/release.sh <version> [--dry-run] [--skip-build] [--skip-upload]

Exemples:
  tools/release.sh 0.2.72 --dry-run
  tools/release.sh 0.2.72
USAGE
}

#######################################
# Parsing arguments
#######################################
VER="${1-}"; shift || true
[[ -n "${VER}" ]] || { usage; die "version manquante"; }
[[ "${VER}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version invalide: ${VER}"

DRY_RUN=0
while (($#)); do
  case "$1" in
    --dry-run)      DRY_RUN=1 ;;
    --skip-build)   RELEASE_SKIP_BUILD=1 ;;
    --skip-upload)  RELEASE_SKIP_UPLOAD=1 ;;
    -h|--help)      usage; exit 0 ;;
    *) die "argument inconnu: $1" ;;
  esac
  shift || true
done

# LOG (maintenant que VER est connu)
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="release_${VER}_${TS}.log"
# journalisation
exec > >(tee -a "${LOG}") 2>&1

note "[release] target -> ${VER}"
note "[cwd] ${ROOT}"
note "[log] ${LOG}"

#######################################
# Vérifs TWINE (masquées sous set -x)
#######################################
# TWINE_USERNAME doit exister (habituellement "__token__")
{ set +x;
  : "${TWINE_USERNAME:?token PyPI manquant (TWINE_USERNAME)}"
  : "${TWINE_PASSWORD:?token PyPI manquant (TWINE_PASSWORD)}"
set -x; } 2>/dev/null || true

# Garde-fou supplémentaire: longueur + préfixe
{ set +x;
  if [[ -z "${TWINE_PASSWORD-}" || ${#TWINE_PASSWORD} -lt 50 || "${TWINE_PASSWORD}" != pypi-AgEI* ]]; then
    echo "TWINE_PASSWORD invalide (vide, trop court ou format inattendu). Abandon."
    exit 1
  fi
set -x; } 2>/dev/null || true

#######################################
# Fonctions PyPI
#######################################
is_on_pypi_json() {
  # 0 -> présent, 1 -> absent, 2 -> erreur réseau / parsing
  local ver="$1" body status url
  url="https://pypi.org/pypi/zz-tools/json?ts=$(date +%s)"
  # masquer l'appel réseau sous xtrace
  { set +x; body="$(xcurl -fsS -H 'Cache-Control: no-cache' --max-time 5 "$url")"; set -x; } || return 2
  [[ -z "$body" ]] && return 2

  if command -v jq >/dev/null 2>&1; then
    status="$(printf '%s' "$body" | jq -r --arg v "$ver" '.releases[$v] | if . == null then "missing" else "present" end' 2>/dev/null || echo error)"
  else
    # fallback Python (pas d'accès net, juste parsing JSON)
    status="$(python - <<'PY' 2>/dev/null || echo error
import json,sys,os
data=json.load(sys.stdin)
v=os.environ.get("PYPI_QV","")
print("present" if v in data.get("releases",{}) else "missing")
PY
      )"
  fi

  [[ "$status" == "present" ]] && return 0
  [[ "$status" == "missing" ]] && return 1
  return 2
}

#######################################
# Étapes
#######################################
# 1) Vérifier si la version est déjà sur PyPI
if is_on_pypi_json "${VER}"; then
  info "Version ${VER} déjà sur PyPI → rien à publier."
  RELEASE_SKIP_UPLOAD=1
fi

# 2) Build (sauf si skip)
if [[ "${RELEASE_SKIP_BUILD}" != "1" ]]; then
  if [[ "${DRY_RUN}" == "1" ]]; then
    info "[dry-run] build (skippé)"
  else
    run "build dist/*" bash -c 'cd "'"${ROOT}"'" && rm -rf dist build *.egg-info && python -m build'
  fi
else
  info "skip build demandé."
fi

# 3) Upload (sauf si skip ou dry-run)
if [[ "${RELEASE_SKIP_UPLOAD}" != "1" ]]; then
  if [[ "${DRY_RUN}" == "1" ]]; then
    info "[dry-run] upload (skippé)"
  else
    run "twine upload" bash -c 'cd "'"${ROOT}"'" && twine upload dist/*'
  fi
else
  info "skip upload demandé."
fi

# 4) Tag git (seulement si pas dry-run)
if [[ "${DRY_RUN}" == "1" ]]; then
  info "[dry-run] tag git v${VER} (skippé)"
else
  run "git tag v${VER}"  git tag "v${VER}" -m "Release ${VER}" || true
  run "git push tag"     git push origin "v${VER}" || true
fi

info "Terminé."
