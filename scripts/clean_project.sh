#!/usr/bin/env bash
# Nettoyage des artéfacts de build, caches, logs et dossiers temporaires du projet MCGT.
# Par défaut, NE supprime PAS les venvs locaux (.venv/venv/env).
# Options :
#   --apply           : exécute réellement les suppressions (sinon dry-run)
#   --also-venv       : supprime aussi .venv venv env (locaux)
#   --no-color        : sortie sans couleurs
#   --quiet           : réduit la verbosité
set -Eeuo pipefail

APPLY=0
ALSO_VENV=0
COLOR=1
QUIET=0

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --also-venv) ALSO_VENV=1 ;;
    --no-color) COLOR=0 ;;
    --quiet) QUIET=1 ;;
    *) echo "Usage: $0 [--apply] [--also-venv] [--no-color] [--quiet]"; exit 2 ;;
  esac
done

# Couleurs
if [[ $COLOR -eq 1 ]] && [[ -t 1 ]]; then
  BOLD=$033[1m; DIM=$033[2m; RED=$033[31m; GRN=$033[32m; YLW=$033[33m; BLU=$033[34m; RST=$033[0m
else
  BOLD=""; DIM=""; RED=""; GRN=""; YLW=""; BLU=""; RST=""
fi

log() { [[ $QUIET -eq 1 ]] || printf "%s\n" "$*"; }
act() { [[ $APPLY -eq 1 ]] && eval "$1" || log "${DIM}[dry-run] ${1}${RST}"; }

# Sécurité : on s’assure d’être à la racine d’un repo git du projet
[[ -d .git ]] || { echo "${RED}❌ Pas de .git ici. Lance depuis la racine du repo.${RST}"; exit 1; }
if [[ ! -f pyproject.toml && ! -f setup.py ]]; then
  echo "${YLW}⚠️  Ni pyproject.toml ni setup.py détecté. Poursuite quand même...${RST}"
fi

log "${BOLD}==> Nettoyage MCGT (APPLY=${APPLY}, ALSO_VENV=${ALSO_VENV})${RST}"

# Listes de patterns (répertoires à supprimer récursivement)
DIRS_PRUNE=(
  "build" "dist" "*.egg-info"
  ".pytest_cache" ".ruff_cache" ".mypy_cache" ".tox" ".nox" ".hypothesis"
  "htmlcov" ".coverage_html" ".cache" ".benchmarks"
  ".ipynb_checkpoints" "__pycache__"
  # dossiers de travail/temporaires fréquents
  "tmp" "temp" ".tmp"
)

# Fichiers à supprimer
FILES_PATTERNS=(
  # Python bytecode / artefacts
  "*.pyc" "*.pyo" "*\$py.class"
  # Logs / traces / tmp
  "*.log" "*.tmp" "*.bak" "*.orig" "*.swp" "*.swo" "*~"
  # Coverage / rapports
  ".coverage" ".coverage.*" "coverage.xml"
  # Artéfacts locaux du projet
  "phase4_*.log"
)

# Venvs locaux (optionnels)
VENV_DIRS_LOCAL=( ".venv" "venv" "env" )

# Venvs Phase 4 créés sous /tmp
VENV_PHASE4_GLOB="/tmp/venv_phase4_*"

# 1) Répertoires à supprimer (dans l’arbre du repo)
for pat in "${DIRS_PRUNE[@]}"; do
  # -depth pour supprimer du plus profond vers la racine, -prune pour éviter de redescendre dedans
  while IFS= read -r -d "" d; do
    [[ -z "$d" ]] && continue
    if [[ $APPLY -eq 1 ]]; then
      rm -rf -- "$d"
      log "${GRN}rm -rf${RST} $d"
    else
      log "${DIM}[dry-run] rm -rf $d${RST}"
    fi
  done < <(find . -path "./.git" -prune -o -type d -name "$pat" -print0)
done

# 2) Fichiers à supprimer
for fpat in "${FILES_PATTERNS[@]}"; do
  while IFS= read -r -d "" f; do
    [[ -z "$f" ]] && continue
    if [[ $APPLY -eq 1 ]]; then
      rm -f -- "$f"
      log "${GRN}rm -f ${RST}$f"
    else
      log "${DIM}[dry-run] rm -f $f${RST}"
    fi
  done < <(find . -path "./.git" -prune -o -type f -name "$fpat" -print0)
done

# 3) Venvs Phase 4 sous /tmp (créés par phase4_validate.sh)
#    On ne “find” pas toute l’arbo de /tmp ici, on cible la convention connue.
if compgen -G "$VENV_PHASE4_GLOB" >/dev/null; then
  for v in $VENV_PHASE4_GLOB; do
    if [[ -d "$v" ]]; then
      if [[ $APPLY -eq 1 ]]; then
        rm -rf -- "$v"
        log "${GRN}rm -rf${RST} $v"
      else
        log "${DIM}[dry-run] rm -rf $v${RST}"
      fi
    fi
  done
fi

# 4) (Optionnel) venvs locaux du repo
if [[ $ALSO_VENV -eq 1 ]]; then
  for vdir in "${VENV_DIRS_LOCAL[@]}"; do
    if [[ -d "$vdir" ]]; then
      if [[ $APPLY -eq 1 ]]; then
        rm -rf -- "$vdir"
        log "${GRN}rm -rf${RST} $vdir"
      else
        log "${DIM}[dry-run] rm -rf $vdir${RST}"
      fi
    fi
  done
else
  log "${BLU}ℹ️  Venvs locaux conservés (.venv/venv/env). Utilise --also-venv pour les supprimer.${RST}"
fi

# 5) Résumé bref (compte ce qui reste des patterns majeurs)
count_dirs() { find . -path "./.git" -prune -o -type d -name "$1" -print | wc -l | tr -d " "; }
count_files() { find . -path "./.git" -prune -o -type f -name "$1" -print | wc -l | tr -d " "; }

LEFT_PYC=$(count_files "*.pyc")
LEFT_CACHES=$(( $(count_dirs "__pycache__") + $(count_dirs ".pytest_cache") + $(count_dirs ".ruff_cache") + $(count_dirs ".mypy_cache") ))
LEFT_BUILD=$(( $(count_dirs "build") + $(count_dirs "dist") + $(count_dirs "*.egg-info") ))

log ""
log "${BOLD}Résumé restant après passage:${RST}"
log "  *.pyc restants           : ${LEFT_PYC}"
log "  caches restants (dirs)   : ${LEFT_CACHES}"
log "  build artefacts restants : ${LEFT_BUILD}"
[[ $ALSO_VENV -eq 1 ]] || log "  venvs locaux             : conservés (passer --also-venv pour les supprimer)"
[[ $APPLY -eq 1 ]] && log "${GRN}✔ Nettoyage APPLY effectué.${RST}" || log "${YLW}🛈 Dry-run uniquement (aucune suppression réelle). Relance avec --apply.${RST}"
