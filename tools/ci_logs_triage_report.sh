#!/usr/bin/env bash
# tools/ci_logs_triage_report.sh
# Résume les logs ZIP déjà collectés par tools/collect_ci_logs_v2.sh
# Sortie : _tmp/ci_failures_v2/triage_report.md + extraits par job
# Sûr : pas de set -e, aucune action destructive.

set -o pipefail
trap 'printf "\n\033[1;34m[INFO]\033[0m Triage terminé (mode safe).\n"' EXIT

ROOT="_tmp/ci_failures_v2"
OUT="$ROOT/triage_report.md"
mkdir -p "$ROOT" || true

i(){ printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
w(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

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
      w "unzip n’est pas dispo; j’essaie avec 'jar xvf' si présent."
      command -v jar >/dev/null 2>&1 && (cd "$dest" && jar xvf "../$(basename "$z")" >/dev/null 2>&1 || true)
    fi
  fi
done

# Heuristiques de détection d’échecs courants
sigfile="$ROOT/_signatures.txt"
cat > "$sigfile" <<'EOF'
# id | label | regex
pip-audit|pip-audit|(?i)\b(vuln|cve|insecure|advisory|requires python|resolution failed)\b
gitleaks|gitleaks|(?i)\b(gitleaks|Secret\ ?Detected|leaks found|rule:)\b
manifest|manifest-guard|(?i)\b(MANIFEST|sdist|missing file|listed but missing|unexpected)\b
readme|readme-guard|(?i)\b(README|badge|section|anchor|toc)\b
generated|guard-generated|(?i)\b(generated|regen(erate)?|out of date)\b
integrity|integrity|(?i)\b(checksum|sha256|integrity|hash mismatch)\b
latex|pdf/build-pdf|(?i)\b(latex|xelatex|pdflatex|TeX Live|Missing package|tlmgr|fontspec|Package not found)\b
perm|perms-and-shebang|(?i)\b(permission denied|exec format error|shebang)\b
semantic|semantic-pr|(?i)\b(conventional commits|semantic|title)\b
EOF

# Nettoie le rapport
: > "$OUT"
echo "# CI triage report" >> "$OUT"
echo "" >> "$OUT"
echo "_Généré par tools/ci_logs_triage_report.sh_" >> "$OUT"
echo "" >> "$OUT"

show_tail(){
  local f="$1"; local n="${2:-200}"
  # Affiche la fin en retirant un peu de bruit des timestamps GitHub
  tail -n "$n" "$f" 2>/dev/null | sed -E 's/^[[:space:]]*//'
}

scan_job_dir(){
  local jobdir="$1"
  local jobname="$(basename "$jobdir")"

  # Choisir le plus gros .txt (souvent le log principal)
  local mainlog="$(ls -S "$jobdir"/*.txt 2>/dev/null | head -n1)"
  [[ -z "$mainlog" ]] && return 0

  # Détecter les signatures
  local hits=""
  while IFS='|' read -r _id _label _re; do
    [[ "$_id" =~ ^#|^$ ]] && continue
    if grep -Eq "$_re" "$mainlog"; then
      hits="$hits, $_label"
    fi
  done < "$sigfile"
  hits="${hits#, }"
  [[ -z "$hits" ]] && hits="(generic failure?)"

  {
    echo "## Job: \`$jobname\`"
    echo ""
    echo "**Signatures**: $hits"
    echo ""
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

for runlogs in "$ROOT"/run_*_logs; do
  [[ ! -d "$runlogs" ]] && continue
  rid="$(basename "$runlogs" | sed 's/run_//; s/_logs//')"
  echo "----" >> "$OUT"
  echo "## Run $rid" >> "$OUT"
  echo "" >> "$OUT"

  # Chaque ZIP décompresse un répertoire par job avec des fichiers *.txt
  find "$runlogs" -maxdepth 1 -type d -mindepth 1 | while read -r jd; do
    scan_job_dir "$jd"
  done
done

echo "" >> "$OUT"
echo "> Fin du rapport." >> "$OUT"

i "Rapport généré : $OUT"
