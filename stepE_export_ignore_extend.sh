#!/usr/bin/env bash
# File: stepE_export_ignore_extend.sh
# Étend .gitattributes (export-ignore) de façon idempotente + sauvegarde.
set -Euo pipefail
need(){ command -v "$1" >/dev/null 2>&1 || { echo "[ERR] manquant: $1"; exit 2; }; }
need git
mkdir -p _logs
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ATTR=".gitattributes"
BAK="_logs/${ATTR}.bak_${STAMP}"

# Liste canonique à ignorer dans les exports (Release tarballs / git archive)
mapfile -t LINES <<'EOF'
# --- export-ignore (MCGT round2 canonical) ---
_attic_untracked/** export-ignore
_tmp/** export-ignore
_tmp-* export-ignore
*.bak export-ignore
*.bak_* export-ignore
*.lock.json export-ignore
*.tmp export-ignore
*.tmp.* export-ignore
*.swp export-ignore
*.log export-ignore
_logs/** export-ignore
arborescence.txt export-ignore
purge_plan_dryrun.txt export-ignore
gitignore_proposition_round2.txt export-ignore
add_list_round2.txt export-ignore
ignore_list_round2.txt export-ignore
review_list_round2.txt export-ignore
README-REPRO.md export-ignore
# --- end export-ignore (MCGT round2) ---
EOF

touch "$ATTR"
cp -f "$ATTR" "$BAK"

append_if_missing () {
  local line="$1"
  grep -Fqx -- "$line" "$ATTR" || echo "$line" >> "$ATTR"
}

for ln in "${LINES[@]}"; do
  # garder les commentaires et lignes vides tels quels
  if [[ -z "${ln// }" ]]; then echo "" >> "$ATTR"; continue; fi
  append_if_missing "$ln"
done

git add "$ATTR"
echo "[OK] ${ATTR} étendu (backup: ${BAK})."
