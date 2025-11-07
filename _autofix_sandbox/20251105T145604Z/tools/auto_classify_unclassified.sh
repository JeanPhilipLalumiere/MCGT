#!/usr/bin/env bash
set -euo pipefail

# Cherche le fichier le plus récent correspondant à un motif
latest_file(){ ls -1t _tmp/"$1".*.txt 2>/dev/null | head -n1; }

ADD_SRC="$(latest_file candidates_add_to_manifest)"
IGN_SRC="$(latest_file candidates_ignore)"
UNC_SRC="$(latest_file candidates_unclassified)"

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/auto_classify_unclassified.$TS.log"
mkdir -p _tmp

say(){ echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG"; }

say "== auto_classify_unclassified: start =="
say "sources:"
say "  ADD_SRC=${ADD_SRC:-<none>}"
say "  IGN_SRC=${IGN_SRC:-<none>}"
say "  UNC_SRC=${UNC_SRC:-<none>}"

if [[ -z "${UNC_SRC:-}" || ! -s "${UNC_SRC:-}" ]]; then
  say "ERROR: pas de fichier unclassified récent. Lance d'abord tools/plan_next_cleanup.sh"
  exit 2
fi

# Fichiers de sortie (propositions)
ADD_OUT="_tmp/proposed_add_to_manifest.$TS.txt"
IGN_OUT="_tmp/proposed_ignore.$TS.txt"
UNR_OUT="_tmp/proposed_unreviewed.$TS.txt"
: > "$ADD_OUT"; : > "$IGN_OUT"; : > "$UNR_OUT"

# Heuristiques PRUDENTES
NOISE_ROOTS='^(zz-out/|legacy-tex/|_snapshots/|docs/|\.github/|_attic_untracked/|_archives_preclean/|_tmp-figs/)'
KEEP_ROOTS='^(zz-configuration/|zz-data/|zz-schemas/|zz-workflows/|policies/|mcgt/|config/|tools/)'
NOISE_EXT='(\.log|\.tmp|\.bak|\.save|\.old|\.aux|\.toc|\.out|\.synctex\.gz|\.pdf)$'
KEEP_EXT='(\.sh|\.py|\.json|\.ini|\.yml|\.yaml|\.md|\.csv|\.dat|\.txt)$'

awk -v NOISE_R="$NOISE_ROOTS" -v KEEP_R="$KEEP_ROOTS" -v NOISE_E="$NOISE_EXT" -v KEEP_E="$KEEP_EXT" '
  NF==0 { next }
  $0 ~ NOISE_R                 { print > "'"$IGN_OUT"'"; next }
  $0 ~ KEEP_R && $0 ~ KEEP_E   { print > "'"$ADD_OUT"'"; next }
  $0 ~ NOICE_E                 { print > "'"$IGN_OUT"'"; next }
  { print > "'"$UNR_OUT"'" }
' "$UNC_SRC"

# Oups, petite coquille orthographique ci-dessus : NOICE_E -> NOISE_E
# On refait le passage proprement (remplace l’awk précédent) :
: > "$ADD_OUT.tmp"; : > "$IGN_OUT.tmp"; : > "$UNR_OUT.tmp"
awk -v NOISE_R="$NOISE_ROOTS" -v KEEP_R="$KEEP_ROOTS" -v NOISE_E="$NOISE_EXT" -v KEEP_E="$KEEP_EXT" '
  NF==0 { next }
  $0 ~ NOISE_R                 { print > "'"$IGN_OUT"'.tmp"; next }
  $0 ~ KEEP_R && $0 ~ KEEP_E   { print > "'"$ADD_OUT"'.tmp"; next }
  $0 ~ NOISE_E                 { print > "'"$IGN_OUT"'.tmp"; next }
  { print > "'"$UNR_OUT"'.tmp" }
' "$UNC_SRC"
mv -f "$ADD_OUT.tmp" "$ADD_OUT"
mv -f "$IGN_OUT.tmp" "$IGN_OUT"
mv -f "$UNR_OUT.tmp" "$UNR_OUT"

# Dédupli + tri
for f in "$ADD_OUT" "$IGN_OUT" "$UNR_OUT"; do sort -u "$f" -o "$f"; done

say "résumé:"
say "  proposed_add_to_manifest : $(wc -l < "$ADD_OUT" | tr -d ' ')  -> $ADD_OUT"
say "  proposed_ignore          : $(wc -l < "$IGN_OUT" | tr -d ' ')  -> $IGN_OUT"
say "  proposed_unreviewed      : $(wc -l < "$UNR_OUT" | tr -d ' ')  -> $UNR_OUT"
say "NOTE: rien n’est modifié. Étape suivante: revue $ADD_OUT et $IGN_OUT."
say "== auto_classify_unclassified: done =="
echo "# === COPY LOGS FROM HERE ==="
