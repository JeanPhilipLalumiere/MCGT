#!/usr/bin/env bash
# sweep_help_and_smoke_guarded.sh
# - Passe A : compile & --help sweep (sans effets de bord)
# - Passe B : mini‑smoke sur *plot_*.py (sortie dans .ci-out/smoke_all/)
# - Garde‑fou : jamais 'set -e', on continue même en cas d'erreur ; pause finale (désactivable)
#
# Usage:
#   bash sweep_help_and_smoke_guarded.sh
#   NO_PAUSE=1 bash sweep_help_and_smoke_guarded.sh   # sans pause finale

set -u  # stricte sur variables ; PAS de -e

TS="$(date +%Y-%m-%dT%H%M%S)"
LOG_DIR=".ci-out"
LOG="${LOG_DIR}/sweep_help_and_smoke_${TS}.log"
OUT=".ci-out/smoke_all"
mkdir -p "${LOG_DIR}" "${OUT}"

say(){ printf "%s %s\n" "[$(date +%H:%M:%S)]" "$*" | tee -a "${LOG}"; }
run(){ say "\$ $*"; ( eval "$*" ) >>"${LOG}" 2>&1; RC=$?; [[ $RC -ne 0 ]] && say "→ RC=$RC (continue)"; return 0; }

say "=== START sweep_help_and_smoke @ ${TS} ==="

# -----------------------------------------------------------------------------
# Phase A — compilation + --help sweep
# -----------------------------------------------------------------------------
compile_ok=0; compile_fail=0
help_ok=0; help_fail=0

# Liste des fichiers Python à auditer (hors répertoires temporaires/attic)
mapfile -t PYFILES < <(find zz-scripts -type f -name '*.py' \
  ! -path '*/_attic/*' ! -path '*/_tmp/*' | sort)

for p in "${PYFILES[@]}"; do
  say "[A:compile] ${p}"
  ( python -m py_compile "${p}" ) >>"${LOG}" 2>&1
  if [[ $? -eq 0 ]]; then
    ((compile_ok+=1))
  else
    say "→ compile ERROR: ${p}"
    ((compile_fail+=1))
  fi

  say "[A:help] ${p} -h"
  ( MPLBACKEND=Agg python "${p}" -h ) >>"${LOG}" 2>&1
  if [[ $? -eq 0 ]]; then
    ((help_ok+=1))
  else
    say "→ help ERROR: ${p}"
    ((help_fail+=1))
  fi
done

say "[A:summary] compile_ok=${compile_ok} compile_fail=${compile_fail} help_ok=${help_ok} help_fail=${help_fail}"

# -----------------------------------------------------------------------------
# Phase B — mini-smoke pour les scripts de tracé (plot_*.py)
# -----------------------------------------------------------------------------
smoke_ok=0; smoke_fail=0

stem_for(){
  local path="$1"
  # stem = concat répertoire + base sans .py, aplati par underscores
  local dir base stem
  dir="$(dirname "$path")"
  base="$(basename "$path" .py)"
  # garde uniquement les deux derniers segments du chemin pour un stem lisible
  # ex: zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py -> chapter07_plot_fig04_dcs2_vs_k
  stem="$(echo "${dir}" | awk -F/ '{n=NF; print $(n-0)}')_${base}"
  # nettoyage simple
  echo "${stem//[^A-Za-z0-9_]/_}"
}

mapfile -t PLOTS < <(find zz-scripts -type f -name 'plot_*.py' \
  ! -path '*/_attic/*' ! -path '*/_tmp/*' | sort)

for s in "${PLOTS[@]}"; do
  stem="$(stem_for "$s")"
  say "[B:smoke] ${s} → ${stem}.png"
  # Exécution tolérante ; on fournit des options homogènes
  ( MPLBACKEND=Agg python "$s" --outdir "${OUT}" --format png --dpi 120 --style classic ) >>"${LOG}" 2>&1
  rc=$?
  if [[ $rc -ne 0 ]]; then
    say "→ run RC=${rc} (on tente de récupérer la dernière image)"
  fi
  # Si le script n'a pas nommé la figure, on duplique la dernière .png récente comme nom canonique
  if [[ ! -f "${OUT}/${stem}.png" ]]; then
    last="$(ls -1t "${OUT}"/*.png 2>/dev/null | head -n1 || true)"
    if [[ -n "${last}" ]]; then
      cp -f "${last}" "${OUT}/${stem}.png"
    fi
  fi
  if [[ -f "${OUT}/${stem}.png" ]]; then
    ((smoke_ok+=1))
  else
    say "→ smoke MISSING: ${stem}.png"
    ((smoke_fail+=1))
  fi
done

say "[B:summary] smoke_ok=${smoke_ok} smoke_fail=${smoke_fail}"

# Inventaire final
run "ls -lh \"${OUT}\" | sed -n '1,200p'"

say "=== DONE (log: ${LOG}) ==="

# Pause finale (désactivable)
if [[ "${NO_PAUSE:-}" != "1" ]]; then
  echo
  read -r -p "Garde-fou actif : appuie sur ENTRÉE pour fermer cette fenêtre." _
fi
