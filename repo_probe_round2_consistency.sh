# repo_probe_round2_consistency.sh (lecture seule)
set +e; set -u
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
L="$REPO/zz-manifests/triage_round2"
A="$L/add_list_round2.txt"; I="$L/ignore_list_round2.txt"; R="$L/review_list_round2.txt"

echo "== CHECK ADD =="
awk 'NF' "$A" | while read -r p; do
  [ -e "$REPO/${p#/}" ] && echo "OK  $p" || echo "MISS $p"
done | tee /tmp/round2_add_status.txt
echo; echo "Résumé ADD:"; awk '{c[$1]++}END{for(k in c) printf "%s\t%d\n",k,c[k]}' /tmp/round2_add_status.txt | sort

echo; echo "== CHECK REVIEW (figures & requirements) =="
awk 'NF' "$R" | while read -r p; do
  full="$REPO/${p#/}"
  kind="other"
  [[ "$p" =~ \.png$ ]] && kind="figure"
  [[ "$p" =~ requirements\.txt$ ]] && kind="req"
  if [ -e "$full" ]; then echo "OK  [$kind] $p"
  else echo "MISS[$kind] $p"; fi
done | tee /tmp/round2_review_status.txt
echo; echo "Résumé REVIEW:"; awk '{c[$1]++}END{for(k in c) printf "%s\t%d\n",k,c[k]}' /tmp/round2_review_status.txt | sort

echo; echo "== SPOTCHECK IGNORE (globs et chemins) =="
# On tague les lignes contenant un * comme GLOB, sinon PATH, et on montre un échantillon d’expansion
n=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if [[ "$line" == *"*"* || "$line" == *"**"* || "$line" == *"?"* ]]; then
    echo "GLOB $line"
    # expansion échantillon (max 5)
    shopt -s nullglob globstar
    arr=( $REPO/${line#/} )
    for f in "${arr[@]:0:5}"; do echo "  -> $(realpath --relative-to="$REPO" "$f")"; done
    shopt -u nullglob globstar
  else
    if [ -e "$REPO/${line#/}" ]; then echo "PATH OK  $line"; else echo "PATH MISS $line"; fi
  fi
  n=$((n+1)); [ $n -ge 20 ] && break
done < "$I"
echo; echo "NOTE: affichage limité à 20 lignes d'IGNORE pour spotcheck."
read -r -p "[PAUSE] Entrée..." _
