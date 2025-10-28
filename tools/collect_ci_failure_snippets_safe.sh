# tools/collect_ci_failure_snippets_safe.sh
#!/usr/bin/env bash
# NE JAMAIS FERMER LA FENÊTRE • extraction non-destructive
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail(){ printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; }

OUT="_tmp/ci_fail_probe"; mkdir -p "$OUT"
BR="${1:-main}"

REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#' )"
[ -z "$REPO" ] && warn "Impossible de détecter le repo GitHub (origin)."

printf '\n\033[1m== CI FAILURE PROBE ==\033[0m\n'
info "Repo=${REPO:-UNKNOWN} • Branch=$BR"

wf_list=( "build-publish.yml" "ci-accel.yml" "pip-audit.yml" )

list_failed_runs() {
  local wf="$1"
  # On liste les derniers runs (jusqu’à 10) et on filtre ceux en failure
  gh run list --workflow "$wf" --branch "$BR" --limit 10 2>/dev/null \
    | awk '$1=="completed" && $2=="failure"{print $0}' | head -n 2
}

grab_one() {
  local wf="$1" rid="$2"
  local dir="$OUT/${wf%.yml}__${rid}"
  mkdir -p "$dir"
  info "Téléchargement logs • wf=$wf • run=$rid"
  # Log texte consolidé
  if gh run view "$rid" --log > "$dir/combined.log" 2>"$dir/err.txt"; then
    ok "Logs bruts → $dir/combined.log"
  else
    warn "Impossible d’obtenir le log consolidé pour $rid (voir $dir/err.txt)"
  fi

  # Extraction patterns signal
  if [ -s "$dir/combined.log" ]; then
    grep -E -n "(\bERROR\b|Error:|Failed|Traceback|^E\s{3,}|FATAL|CRITICAL|fatal:|^##\[error\])" \
      "$dir/combined.log" > "$dir/signal.errlines.txt" || true
    tail -n 120 "$dir/combined.log" > "$dir/tail_120.txt" || true
    ok "Synthèses → $dir/signal.errlines.txt / $dir/tail_120.txt"
  fi
}

for wf in "${wf_list[@]}"; do
  if [ ! -f ".github/workflows/$wf" ]; then
    warn "$wf absent localement — je tente quand même la liste des runs"
  fi
  info "Recherche des 2 derniers échecs: $wf@$BR"
  rows="$(list_failed_runs "$wf")"
  if [ -z "$rows" ]; then
    ok "Aucun échec récent trouvé pour $wf@$BR"
    continue
  fi
  echo "$rows" | while IFS= read -r line; do
    # gh run list format: status conclusion name workflow branch event runID duration started
    rid="$(echo "$line" | awk '{print $(NF-2)}')" # le runID est le 3e champ en partant de la fin
    # robust fallback si format change
    [[ "$rid" =~ ^[0-9]+$ ]] || rid="$(echo "$line" | grep -Eo '[0-9]{8,}$' | tail -n1)"
    [ -n "$rid" ] && grab_one "$wf" "$rid" || warn "RunID introuvable pour: $line"
  done
done

printf '\n\033[1m== RAPPORT RAPIDE ==\033[0m\n'
for d in "$OUT"/*; do
  [ -d "$d" ] || continue
  wf="$(basename "$d" | sed 's/__.*//')"
  rid="$(basename "$d" | sed 's/.*__//')"
  echo "—— ${wf} • run ${rid} ——"
  if [ -s "$d/signal.errlines.txt" ]; then
    echo "[extraits erreurs]"
    sed -n '1,40p' "$d/signal.errlines.txt"
  else
    echo "(pas de patterns d’erreur capturés — voir combined.log)"
  fi
  echo
done

printf '\n\033[1;32mFini.\033[0m Logs dans: %s (fenêtre laissée OUVERTE)\n' "$OUT"
