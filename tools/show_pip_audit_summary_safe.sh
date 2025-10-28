# tools/show_pip_audit_summary_safe.sh
#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — résume les 2 derniers runs pip-audit déjà collectés
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

ROOT="_tmp/pip_audit_findings_now"
if [ ! -d "$ROOT" ] || ! ls "$ROOT"/run_*/combined.log >/dev/null 2>&1; then
  warn "Aucun log pip-audit collecté. Je lance la collecte (branche main)…"
  bash tools/ci_probe_pip_audit_findings_safe.sh main || true
fi

shopt -s nullglob
runs=( "$ROOT"/run_* )
if [ "${#runs[@]}" -eq 0 ]; then
  warn "Toujours aucun run pip-audit disponible. Ouvre l’onglet Actions pour vérifier."
  exit 0
fi

printf '\n\033[1m== PIP-AUDIT SUMMARY ==\033[0m\n'
for R in "${runs[@]}"; do
  rid="${R##*/run_}"
  log="$R/combined.log"
  urlfile="$R/run.url"
  [ -s "$urlfile" ] && url="$(cat "$urlfile")" || url="(no-url)"
  echo
  echo "—— run ${rid} ——"
  echo "   ${url}"

  # 1) extraire lignes CVE/GHSA/PYSEC si présentes
  grep -E 'CVE-|GHSA-|PYSEC-' "$log" > "$R/findings.raw.txt" 2>/dev/null || true

  # 2) tentative d’extraction structurée (si le job avait --format json)
  #    on filtre uniquement les triplets utiles: name, version, vuln id, fix_versions (si dispo)
  : > "$R/findings.tsv"
  if command -v jq >/dev/null 2>&1; then
    jq -r '
      (.. | objects? | select(has("dependencies"))) as $r
      | $r.dependencies[]
      | .name as $n
      | (.version // "") as $v
      | (.vulns // [])[]
      | [$n, $v, (.id // ""), ((.fix_versions // [])|join(","))]
      | @tsv
    ' "$log" 2>/dev/null > "$R/findings.tsv"
  fi

  # 3) impression lisible
  if [ -s "$R/findings.tsv" ]; then
    echo "package\tversion\tvuln_id\tfix_versions"
    sort -u "$R/findings.tsv" | column -t -s $'\t'
  elif [ -s "$R/findings.raw.txt" ]; then
    echo "(signaux texte bruts — pas de JSON structuré détecté)"
    sed -n '1,80p' "$R/findings.raw.txt"
  else
    echo "_Aucun motif CVE/GHSA trouvé. Voir tail du log:_"
    tail -n 80 "$log" || true
  fi
done

# 4) vue agrégée (si des TSV existent)
agg="$(mktemp)"
found_any=0
for R in "${runs[@]}"; do
  if [ -s "$R/findings.tsv" ]; then
    awk -F'\t' '{print $1"\t"$2"\t"$3"\t"$4}' "$R/findings.tsv" >> "$agg"
    found_any=1
  fi
done
if [ "$found_any" -eq 1 ]; then
  printf '\n\033[1m== AGRÉGÉ (unique) ==\033[0m\n'
  echo "package\tversion\tvuln_id\tfix_versions"
  sort -u "$agg" | column -t -s $'\t'
  printf '\n\033[1m== PAR PAQUET (compte de vulnérabilités) ==\033[0m\n'
  awk -F'\t' '{print $1}' "$agg" | sort | uniq -c | sort -nr
else
  warn "Pas de données structurées à agréger (pas de sortie JSON)."
fi
rm -f "$agg" 2>/dev/null || true

echo
ok "Résumé terminé (fenêtre laissée OUVERTE)."
