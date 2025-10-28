#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — extrait les vulnérabilités pip-audit depuis les 2 derniers runs en échec
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

BR="${1:-main}"
OUT="_tmp/pip_audit_findings_now"; mkdir -p "$OUT"

REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/ ]([^/]+/[^/.]+)(\.git)?#\1#')"
printf '\n\033[1m== PIP-AUDIT FINDINGS PROBE ==\033[0m\n'
info "Repo=${REPO:-UNKNOWN} • Branch=$BR"

if ! gh auth status >/dev/null 2>&1; then
  warn "gh non authentifié — extraction best-effort."
fi

# 1) lister 2 derniers runs "failure" pour pip-audit.yml
rows="$(gh run list --workflow pip-audit.yml --branch "$BR" --limit 10 2>/dev/null \
        | awk '$1=="completed" && $2=="failure"{print $0}' | head -n 2)"
if [ -z "$rows" ]; then
  warn "Pas d'échec récent pip-audit sur $BR."
  exit 0
fi

idx=0
echo "$rows" | while IFS= read -r line; do
  idx=$((idx+1))
  run_id="$(echo "$line" | awk '{print $(NF-2)}')"
  [[ "$run_id" =~ ^[0-9]+$ ]] || run_id="$(echo "$line" | grep -Eo '[0-9]{8,}$' | tail -n1)"
  dir="$OUT/run_${run_id}"; mkdir -p "$dir"

  # 2) tenter log consolidé
  if gh run view "$run_id" --log > "$dir/combined.log" 2>"$dir/combined.err"; then
    if [ -s "$dir/combined.log" ]; then
      ok "Run #$idx ($run_id) log consolidé → $dir/combined.log"
    fi
  fi

  # 3) fallback: logs par job si combiné vide
  if [ ! -s "$dir/combined.log" ]; then
    warn "Run $run_id: log combiné vide — je tente par job"
    if command -v jq >/dev/null 2>&1; then
      gh run view "$run_id" --json jobs > "$dir/jobs.json" 2>"$dir/jobs.err"
      job_ids="$(jq -r '.jobs[].id' "$dir/jobs.json" 2>/dev/null)"
      n=0
      while IFS= read -r jid; do
        [ -n "$jid" ] || continue
        n=$((n+1))
        gh run view --job "$jid" --log > "$dir/job_${n}_${jid}.log" 2>"$dir/job_${n}_${jid}.err"
      done <<< "$job_ids"
      cat "$dir"/job_*.log 2>/dev/null > "$dir/combined.log" || true
    else
      warn "jq absent — impossible de fusionner les logs par job."
    fi
  fi

  # 4) extraire les findings "type tableau" et "JSON" le cas échéant
  if [ -s "$dir/combined.log" ]; then
    # motifs fréquents (pip-audit table text / JSON)
    # a) table text : lignes ressemblant à "package  version  vuln  fix"
    grep -E 'CVE-|PYSEC-|GHSA-' "$dir/combined.log" > "$dir/findings.raw.txt" 2>/dev/null || true
    # b) JSON éventuel (si --format json dans le workflow)
    jq -r '.[], .dependencies[]? | .name? + " " + (.version? // "") + " " + (.vulns[]?.id? // "") + " " + (.vulns[]?.fix_versions? // "")' \
      "$dir/combined.log" 2>/dev/null > "$dir/findings.jsonlike.txt" || true

    # synthèse lisible
    {
      echo "# pip-audit findings — run $run_id"
      echo
      if [ -s "$dir/findings.raw.txt" ]; then
        echo "## Extraits textuels (CVE/GHSA)"
        sed -n '1,120p' "$dir/findings.raw.txt"
        echo
      fi
      if [ -s "$dir/findings.jsonlike.txt" ]; then
        echo "## Extraits JSON (name version vuln fix_versions)"
        sed -n '1,120p' "$dir/findings.jsonlike.txt"
        echo
      fi
      if [ ! -s "$dir/findings.raw.txt" ] && [ ! -s "$dir/findings.jsonlike.txt" ]; then
        echo "_Aucun motif CVE/GHSA détecté dans le log consolidé. Voir combined.log pour le détail._"
      fi
    } > "$dir/REPORT.md"
    ok "Rapport → $dir/REPORT.md"
  else
    warn "Aucun log exploitable pour run $run_id (voir $dir)."
  fi

  url="$(gh run view "$run_id" --json url -q .url 2>/dev/null)"
  [ -n "$url" ] && echo "$url" > "$dir/run.url"
done

echo
ok "Terminé. Parcours: $OUT (fenêtre laissée OUVERTE)"
