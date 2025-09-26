#!/usr/bin/env bash
# bump_and_tag_safe.sh — bump version, tag, build & push — sans tuer le terminal

# ── Guardrails ────────────────────────────────────────────────────────────────
# - Pas de `set -e` : on capture les RC et on continue.
# - Log complet de la session.
# - Récapitulatif final + pause (désactivable).
# - Variables:
#     DRYRUN=1   → affiche les commandes, ne modifie rien
#     NO_BUILD=1 → saute build & twine check
#     NO_PUSH=1  → saute git push & push --tags
#     FORCE=1    → continue même si WT sale ou tag existant
#     NO_PAUSE=1 → désactive la pause finale

set -u
START_TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="bump_tag_${START_TS}.log"
FAILS=0
WARN=0

# Log de toute la session
exec > >(tee -a "$LOG") 2>&1

section(){ printf '\n===== %s =====\n' "$*"; }
note(){ printf '[NOTE] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*"; WARN=$((WARN+1)); }
err(){  printf '[ERR ] %s\n' "$*";  FAILS=$((FAILS+1)); }

run(){ # Runner non fatal
  local desc="$1"; shift
  section "$desc"
  if [[ "${DRYRUN:-0}" == "1" ]]; then
    printf '[DRYRUN] %q ' "$@"; printf '\n'
    return 0
  fi
  "$@"; local rc=$?
  if [[ $rc -ne 0 ]]; then err "rc=$rc on: $*"; fi
  return 0
}

finish(){
  section "RÉCAPITULATIF"
  echo "- WARNINGS : $WARN"
  echo "- FAILS    : $FAILS"
  echo "- LOG      : $LOG"
  if [[ "${NO_PAUSE:-0}" != "1" ]]; then
    echo
    read -r -p "Exécution terminée. Appuyez sur Entrée pour fermer..." _ || true
  fi
}
trap finish EXIT

# ── Args ──────────────────────────────────────────────────────────────────────
if [[ $# -ne 1 ]]; then
  section "Usage"
  echo "Usage: $0 X.Y.Z[-rcN]"
  echo "Exemples:"
  echo "  $0 0.2.32-rc1   # tag RC (TestPyPI via workflow)"
  echo "  $0 0.2.32       # tag final (PyPI via workflow)"
  err "Argument version manquant."
  exit 0
fi
VER="$1"

echo "== bump_and_tag_safe (start: $START_TS) =="
echo "Version cible      : $VER"
echo "Options            : DRYRUN=${DRYRUN:-0} NO_BUILD=${NO_BUILD:-0} NO_PUSH=${NO_PUSH:-0} FORCE=${FORCE:-0}"
echo "Pause finale       : $( [[ "${NO_PAUSE:-0}" == "1" ]] && echo "non" || echo "oui" )"
echo "Log fichier        : $LOG"

# ── Pré-requis ────────────────────────────────────────────────────────────────
section "Vérification prérequis"
need_cmds=(git python sed awk)
missing=0
for c in "${need_cmds[@]}"; do
  if ! command -v "${c%% *}" >/dev/null 2>&1; then err "binaire requis manquant: $c"; missing=1; else note "ok: $(command -v "${c%% *}")"; fi
done
[[ $missing -eq 0 ]] || warn "Des prérequis manquent — certaines étapes peuvent échouer."

# Semver-ish
if ! [[ "$VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z\.-]+)?$ ]]; then
  err "Version invalide: $VER"
fi

# Git sanity
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then err "Pas un dépôt git."; fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  [[ "${FORCE:-0}" == "1" ]] && warn "WT/Index non propres mais FORCE=1 → on continue." || err "WT/Index non propres (FORCE=1 pour ignorer)."
fi
if git tag -l "v${VER}" | grep -qx "v${VER}"; then
  [[ "${FORCE:-0}" == "1" ]] && warn "Tag v${VER} existe (FORCE=1) → on continue." || err "Le tag v${VER} existe déjà."
fi

# ── Bump versions ─────────────────────────────────────────────────────────────
run "Mise à jour pyproject.toml → version=${VER}" bash -c '
if [[ -f pyproject.toml ]] && grep -Eq "^[[:space:]]*version[[:space:]]*=" pyproject.toml; then
  sed -i -E "s/^([[:space:]]*version[[:space:]]*=\s*\")[0-9]+\.[0-9]+\.[0-9]+(\".*)$/\1'"$VER"'\2/" pyproject.toml
else
  echo "[WARN] Aucun champ version dans pyproject.toml (ok si géré ailleurs)."
fi'

run "Mise à jour mcgt/__init__.py → __version__=${VER}" env VER="$VER" python - <<'PY'
import os, re
from pathlib import Path
ver = os.environ["VER"]
p = Path("mcgt/__init__.py")
if not p.exists():
    raise SystemExit("Fichier manquant: mcgt/__init__.py")
t = p.read_text(encoding="utf-8")
pat = re.compile(r'(__version__\s*=\s*["\'])(.*?)((["\']))')
if pat.search(t):
    t = pat.sub(r'\g<1>'+ver+r'\3', t, count=1)
else:
    if not t.endswith("\n"): t += "\n"
    t += f'__version__ = "{ver}"\n'
p.write_text(t, encoding="utf-8")
print("ok: __version__ =", ver)
PY

# ── Commit & tag ──────────────────────────────────────────────────────────────
run "git add/commit"  git add -A
run "git commit"      git commit -m "release: bump version ${VER}"
run "git tag v${VER}" git tag -a "v${VER}" -m "mcgt_core ${VER}"

# ── Build & check (optionnel) ────────────────────────────────────────────────
if [[ "${NO_BUILD:-0}" == "1" ]]; then
  note "NO_BUILD=1 → on saute le build."
else
  run "Nettoyage artefacts" bash -c 'rm -rf dist build *.egg-info'
  run "Build sdist+wheel"  python -m build
  run "twine check dist/*" python -m twine check dist/*
fi

# ── Push (optionnel) ─────────────────────────────────────────────────────────
if [[ "${NO_PUSH:-0}" == "1" ]]; then
  note "NO_PUSH=1 → on saute le push."
else
  run "git push"      git push
  run "git push tags" git push --tags
fi

# Fin — summary via trap
true
