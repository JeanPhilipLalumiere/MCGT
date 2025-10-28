# tools/collect_ci_failure_snippets_safe_v2.sh
#!/usr/bin/env bash
# NEVER-FAIL: n'interrompt pas la fenêtre, loggue tout dans _tmp/ci_fail_probe_v2/
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail(){ printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; }

BR="${1:-main}"
OUT="_tmp/ci_fail_probe_v2"; mkdir -p "$OUT"

REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"
printf '\n\033[1m== CI FAILURE PROBE v2 (per-job logs) ==\033[0m\n'
info "Repo=${REPO:-UNKNOWN} • Branch=$BR"

# Vérif best-effort de l’auth gh
if ! gh auth status >/dev/null 2>&1; then
  warn "gh non authentifié ou token insuffisant. Les logs consolidés peuvent échouer."
fi

wf_list=( "build-publish.yml" "ci-accel.yml" "pip-audit.yml" )

list_failed_runs() {
  local wf="$1"
  gh run list --workflow "$wf" --branch "$BR" --limit 10 2>/dev/null \
    | awk '$1=="completed" && $2=="failure"{print $0}' | head -n 2
}

run_url_of() {
  local rid="$1"
  gh run view "$rid" --json url -q .url 2>/dev/null
}

fetch_run_combined_or_jobs() {
  local wf="$1" rid="$2"
  local dir="$OUT/${wf%.yml}__${rid}"
  mkdir -p "$dir"

  # 1) Tentative log consolidé du run
  if gh run view "$rid" --log > "$dir/combined.log" 2>"$dir/combined.err"; then
    if [ -s "$dir/combined.log" ]; then
      ok "Logs consolidés → $dir/combined.log"
      return 0
    fi
  fi
  warn "Log consolidé indisponible pour run $rid — je tente logs par job."

  # 2) Fallback: logs par job
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq absent — impossible d’énumérer les jobs. Installe jq pour une extraction fine."
    return 1
  fi

  local jobs_json="$dir/jobs.json"
  if ! gh run view "$rid" --json jobs > "$jobs_json" 2>"$dir/jobs.err"; then
    warn "Impossible d’énumérer les jobs (voir $dir/jobs.err)"
    return 1
  fi

  local job_ids
  job_ids="$(jq -r '.jobs[].id' "$jobs_json" 2>/dev/null)"
  if [ -z "$job_ids" ]; then
    warn "Aucun job id trouvé pour run $rid."
    return 1
  fi

  local idx=0
  while IFS= read -r jid; do
    [ -n "$jid" ] || continue
    idx=$((idx+1))
    local jlog="$dir/job_${idx}_${jid}.log"
    if gh run view --job "$jid" --log > "$jlog" 2>"$jlog.err"; then
      if [ -s "$jlog" ]; then
        ok "Job#$idx logs → $jlog"
      else
        warn "Job#$idx: log vide."
      fi
    else
      warn "Job#$idx: impossible d’obtenir le log (voir $jlog.err)"
    fi
  done <<< "$job_ids"

  # Fusion naïve des logs de jobs si le consolidé manque
  cat "$dir"/job_*.log 2>/dev/null > "$dir/combined.jobs.log" || true
  if [ -s "$dir/combined.jobs.log" ]; then
    ok "Fusion jobs → $dir/combined.jobs.log"
    return 0
  fi
  return 1
}

extract_signals() {
  local file="$1"; shift
  local dir="$1"; shift
  local base="$(basename "$file")"
  local sig="$dir/${base%.log}.signals.txt"
  local tailf="$dir/${base%.log}.tail_120.txt"

  # Motifs élargis: GHA et outils usuels
  grep -E -n "(\:\:error|##\[error\]|Error:|^E\s{3,}|Failed|FAIL|FATAL|CRITICAL|fatal:|Traceback)" \
      "$file" > "$sig" 2>/dev/null || true
  tail -n 120 "$file" > "$tailf" 2>/dev/null || true
  [ -s "$sig" ] && ok "Signals → $sig" || warn "Aucun motif d’erreur détecté dans $base (voir tail)."
}

# Boucle principale
for wf in "${wf_list[@]}"; do
  info "Recherche des 2 derniers échecs: $wf@$BR"
  rows="$(list_failed_runs "$wf")"
  if [ -z "$rows" ]; then
    ok "Aucun échec récent pour $wf@$BR"
    continue
  fi
  echo "$rows" | while IFS= read -r line; do
    rid="$(echo "$line" | awk '{print $(NF-2)}')"
    [[ "$rid" =~ ^[0-9]+$ ]] || rid="$(echo "$line" | grep -Eo '[0-9]{8,}$' | tail -n1)"
    [ -z "$rid" ] && { warn "RunID introuvable pour: $line"; continue; }
    url="$(run_url_of "$rid")"
    dir="$OUT/${wf%.yml}__${rid}"; mkdir -p "$dir"

    fetch_run_combined_or_jobs "$wf" "$rid"

    # Choisir le meilleur fichier présent
    log_file=""
    if   [ -s "$dir/combined.log" ]; then log_file="$dir/combined.log"
    elif [ -s "$dir/combined.jobs.log" ]; then log_file="$dir/combined.jobs.log"
    else
      warn "Aucun log dispo pour $wf run=$rid (voir $dir)"
      continue
    fi

    extract_signals "$log_file" "$dir"

    # garde un lien URL
    [ -n "$url" ] && echo "$url" > "$dir/run.url"
  done
done

printf '\n\033[1m== RAPPORT RAPIDE v2 ==\033[0m\n'
for d in "$OUT"/*; do
  [ -d "$d" ] || continue
  wf="$(basename "$d" | sed 's/__.*//')"
  rid="$(basename "$d" | sed 's/.*__//')"
  url="(no-url)"
  [ -s "$d/run.url" ] && url="$(cat "$d/run.url")"
  echo "—— ${wf} • run ${rid} ——"
  echo "   ${url}"
  # montres les premières lignes de signaux si présentes
  sig="$(ls "$d"/*signals.txt 2>/dev/null | head -n1)"
  if [ -n "$sig" ] && [ -s "$sig" ]; then
    echo "[extraits d’erreurs]"
    sed -n '1,50p' "$sig"
  else
    echo "(pas de motifs d’erreur détectés — inspecte *.log / tail_120.txt)"
  fi
  echo
done

printf '\n\033[1;32mFini.\033[0m Logs & signaux → %s (fenêtre laissée OUVERTE)\n' "$OUT"
