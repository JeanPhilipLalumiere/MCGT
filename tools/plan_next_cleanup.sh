#!/usr/bin/env bash
set -euo pipefail

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/plan_next_cleanup.$TS.log"
mkdir -p _tmp

say(){ echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG"; }

say "== plan_next_cleanup: start =="

# 1) Santé du repo (réutilise nos outils, non destructif)
COMPUTE_SHA=1 bash tools/scan_repo_health.sh | tee -a "$LOG" || true

# Entrées générées par scan_repo_health.sh
#   _tmp/health_tracked_not_in_manifest.txt
#   _tmp/health_dupe_sha256.tsv

TNIM="_tmp/health_tracked_not_in_manifest.txt"
DUPES="_tmp/health_dupe_sha256.tsv"

if [[ ! -s "$TNIM" ]]; then
  say "ERROR: $TNIM introuvable ou vide. As-tu bien tools/scan_repo_health.sh ?"
  exit 2
fi

# 2) Règles de tri : racines “bruit” vs “candidates manifeste”
#    (ajuste la liste si besoin)
NOISE_ROOTS='^(zz-out/|legacy-tex/|_snapshots/|docs/|\.github/|_tmp-figs/|_attic_untracked/|_archives_preclean/)'
KEEP_ROOTS='^(zz-configuration/|zz-data/|zz-schemas/|zz-workflows/|policies/|tools/|mcgt/|config/)$'

# 3) Produire les listes d’action
CAND_ADD="_tmp/candidates_add_to_manifest.$TS.txt"
CAND_IGNORE="_tmp/candidates_ignore.$TS.txt"
CAND_UNCLASS="_tmp/candidates_unclassified.$TS.txt"

: > "$CAND_ADD"; : > "$CAND_IGNORE"; : > "$CAND_UNCLASS"

awk -v NOISE="$NOISE_ROOTS" -v KEEP="$KEEP_ROOTS" '
  NF==0 { next }
  $0 ~ NOISE { print > "'"$CAND_IGNORE"'" ; next }
  $0 ~ KEEP  { print > "'"$CAND_ADD"'"    ; next }
  { print > "'"$CAND_UNCLASS"'" }
' "$TNIM"

# 4) Prioriser les doublons SHA (s’il y en a)
TOP_DUPES="_tmp/dupe_priority.$TS.tsv"
if [[ -s "$DUPES" ]]; then
  # Garde les groupes à >=2 fichiers, trie par groupe puis taille descendante
  awk 'NR==1{print;next} {print}' "$DUPES" \
  | awk -F'\t' 'NR==1{print; next} {count[$1]++} END{for (k in count) if (count[k]>=2) print k}' \
  | sort \
  | join -t $'\t' -1 1 -2 1 - <(sort -t $'\t' -k1,1 "$DUPES") \
  | awk 'BEGIN{FS=OFS="\t"} {print $0}' > "$TOP_DUPES" || true
fi

# 5) Résumé
n_add=$(wc -l < "$CAND_ADD" | tr -d ' ')
n_ign=$(wc -l < "$CAND_IGNORE" | tr -d ' ')
n_unc=$(wc -l < "$CAND_UNCLASS" | tr -d ' ')
n_dup=0; [[ -f "$TOP_DUPES" ]] && n_dup=$(wc -l < "$TOP_DUPES" | tr -d ' ')

say "SUMMARY:"
say "  candidates_add_to_manifest: $n_add   -> $CAND_ADD"
say "  candidates_ignore        : $n_ign   -> $CAND_IGNORE"
say "  candidates_unclassified  : $n_unc   -> $CAND_UNCLASS"
say "  dupe_priority rows       : $n_dup   -> ${TOP_DUPES:-none}"
say "NOTE: rien n’est modifié. Étape suivante :"
say "  - passer en revue $CAND_ADD et $CAND_IGNORE"
say "  - ajuster ROOTS (NOISE/KEEP) ci-dessus si besoin"
say "  - puis je fournis un script APPLY (add manifest / renforcer .gitignore)"
say "== plan_next_cleanup: done =="
# === COPY LOGS FROM HERE ===
