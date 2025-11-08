#!/usr/bin/env bash
# tools/ci_logs_triage_report_v2.sh
# Résume les logs ZIP collectés par tools/collect_ci_logs_v2.sh
# Sortie : _tmp/ci_failures_v2/triage_report.md
# Sûr : aucun exit brutal, garde-fous & compat GNU/BSD.

set -o pipefail
trap 'printf "\n\033[1;34m[INFO]\033[0m Triage terminé (mode safe).\n"' EXIT

ROOT="_tmp/ci_failures_v2"
OUT="$ROOT/triage_report.md"
mkdir -p "$ROOT" || true

i(){ printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
w(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

# Permet aux glob *.txt de ne pas provoquer "ls: cannot access"
shopt -s nullglob 2>/dev/null || true

if ! ls "$ROOT"/run_*.zip >/dev/null 2>&1; then
  w "Aucun ZIP trouvé dans $ROOT. Lance d’abord tools/collect_ci_logs_v2.sh."
  exit 0
fi

# Décompresse tous les ZIP manquants
for z in "$ROOT"/run_*.zip; do
  run_id="$(basename "$z" .zip | sed 's/run_//')"
  dest="$ROOT/run_${run_id}_logs"
  if [[ ! -d "$dest" ]]; then
    mkdir -p "$dest"
    if command -v unzip >/dev/null 2>&1; then
      unzip -q -o "$z" -d "$dest" || true
    else
      w "unzip indisponible; tentative avec 'jar xvf'."
      command -v jar >/dev/null 2>&1 && (cd "$dest" && jar xvf "../$(basename "$z")" >/dev/null 2>&1 || true)
    fi
  fi
done

# Heuristiques de détection d’échecs courants (sans (?i), on utilisera -i côté grep)
sigfile="$ROOT/_signatures.txt"
cat > "$sigfile" <<'EOF'
# id | label | regex (sans (?i); grep -Ei sera utilisé)
pip-audit|pip-audit|(vuln|cve|insecure|advisory|requires python|resolution failed)
gitleaks|gitleaks|(gitleaks|secret ?detected|leaks found|rule:)
manifest|manifest-guard|(MANIFEST|sdist|missing file|listed but missing|unexpected)
readme|readme-guard|(README|badge|section|anchor|toc)
generated|guard-generated|(generated|regenerate|out of date)
integrity|integrity|(checksum|sha256|integrity|hash mismatch)
latex|pdf/build-pdf|(latex|xelatex|pdflatex|TeX Live|Missing package|tlmgr|fontspec|Package not found)
perm|perms-and-shebang|(permission denied|exec format error|shebang)
semantic|semantic-pr|(conventional commits|semantic|title)
EOF

# Réinitialise le rapport
: > "$OUT"
{
  echo "# CI triage report"
  echo
  echo "_Généré par tools/ci_logs_triage_report_v2.sh_"
  echo
} >> "$OUT"

show_tail(){
  # Affiche la fin du fichier en réduisant le bruit
  local f="$1"; local n="${2:-200}"
  tail -n "$n" "$f" 2>/dev/null | sed -E 's/^[[:space:]]*//'
}

scan_job_dir(){
  local jobdir="$1"
  local jobname
  jobname="$(basename "$jobdir")"

  # Choisir le plus gros .txt comme log principal
  local mainlog=""
  local candidates=("$jobdir"/*.txt)
  if [[ ${#candidates[@]} -gt 0 ]]; then
    # tri par taille décroissante
    IFS=$'\n' read -r -d '' -a sorted < <(ls -S "${candidates[@]}" 2>/dev/null && printf '\0')
    mainlog="${sorted[0]}"
  fi
  [[ -z "$mainlog" ]] && return 0

  # Détecter les signatures
  local hits=""
  while IFS='|' read -r _id _label _re; do
    [[ "$_id" =~ ^#|^$ ]] && continue
    if grep -Eiq "$_re" "$mainlog"; then
      hits="$hits, $_label"
    fi
  done < "$sigfile"
  hits="${hits#, }"
  [[ -z "$hits" ]] && hits="(generic failure?)"

  {
    echo "## Job: \`$jobname\`"
    echo
    echo "**Signatures**: $hits"
    echo
    echo "<details><summary>Dernières ~200 lignes</summary>"
    echo
    echo '```text'
    show_tail "$mainlog" 200
    echo '```'
    echo
    echo "</details>"
    echo
  } >> "$OUT"
}

# Parcourt chaque run_*_logs et ses sous-dossiers (jobs)
for runlogs in "$ROOT"/run_*_logs; do
  [[ ! -d "$runlogs" ]] && continue
  rid="$(basename "$runlogs" | sed 's/run_//; s/_logs//')"
  {
    echo "----"
    echo "## Run $rid"
    echo
  } >> "$OUT"

  # On évite les ennuis d’ordre avec find : on boucle simplement
  for jd in "$runlogs"/*; do
    [[ -d "$jd" ]] || continue
    scan_job_dir "$jd"
  done
done

{
  echo
  echo "> Fin du rapport."
} >> "$OUT"

i "Rapport généré : $OUT"
