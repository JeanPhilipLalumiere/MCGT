#!/usr/bin/env bash
set -euo pipefail

echo "[PASS10] Inventaire STUB/SHIM/*.bak (chapitres 01–10)"

SROOT="zz-scripts"
OUTDIR="zz-out"
TXT="$OUTDIR/homog_stub_inventory.txt"
CSV="$OUTDIR/homog_stub_inventory.csv"
mkdir -p "$OUTDIR"

# Collecte fichiers .py et .py.bak
mapfile -t PYFILES < <(find "$SROOT"/chapter0{1..9} "$SROOT"/chapter10 -type f -name "*.py" | sort)
mapfile -t BAKFILES < <(find "$SROOT"/chapter0{1..9} "$SROOT"/chapter10 -type f -name "*.py.bak" | sort)

# Index des .bak existants (pour test rapide)
tmp_bak_index="$(mktemp)"
trap 'rm -f "$tmp_bak_index"' EXIT
for b in "${BAKFILES[@]}"; do
  echo "${b%.bak}" >> "$tmp_bak_index"
done

echo "# STUB/SHIM inventory $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$TXT"
echo "chapter,file,has_stub_marker,has_shim_marker,has_bak" > "$CSV"

count_total=0
count_stub=0
count_shim=0
count_bak=0

# Déclarer les tableaux associatifs pour les cumuls
declare -A CH_SUM_STUB=()
declare -A CH_SUM_SHIM=()
declare -A CH_SUM_BAK=()
declare -A CH_SUM_TOTAL=()

for f in "${PYFILES[@]}"; do
  ((count_total++)) || true
  chap="$(sed -nE 's@^.*/chapter([0-9]{2})/.*@\1@p' <<<"$f")"
  [[ -z "${chap:-}" ]] && chap="??"

  # Marqueurs
  has_stub="no"
  has_shim="no"
  if grep -q '=== \[PASS6-STUB\] ===' "$f"; then has_stub="yes"; fi
  if grep -q '=== \[PASS5B-SHIM\] ===' "$f"; then has_shim="yes"; fi

  # .bak correspondant
  has_bak="no"
  if grep -qxF "$f" "$tmp_bak_index"; then has_bak="yes"; fi

  # Cumuls (avec défaut 0)
  CH_SUM_TOTAL["$chap"]=$(( ${CH_SUM_TOTAL["$chap"]:-0} + 1 ))
  if [[ "$has_stub" == "yes" ]]; then
    ((count_stub++)) || true
    CH_SUM_STUB["$chap"]=$(( ${CH_SUM_STUB["$chap"]:-0} + 1 ))
  fi
  if [[ "$has_shim" == "yes" ]]; then
    ((count_shim++)) || true
    CH_SUM_SHIM["$chap"]=$(( ${CH_SUM_SHIM["$chap"]:-0} + 1 ))
  fi
  if [[ "$has_bak" == "yes" ]]; then
    ((count_bak++)) || true
    CH_SUM_BAK["$chap"]=$(( ${CH_SUM_BAK["$chap"]:-0} + 1 ))
  fi

  echo "$chap,$f,$has_stub,$has_shim,$has_bak" >> "$CSV"
done

# Résumé texte
{
  echo ""
  echo "=== Résumé global ==="
  echo "Total .py       : $count_total"
  echo "Avec STUB       : $count_stub"
  echo "Avec SHIM       : $count_shim"
  echo "Avec .bak       : $count_bak"
  echo ""
  echo "=== Par chapitre ==="
  # Lister toutes les clés rencontrées, triées
  for chap in $(printf "%s\n" "${!CH_SUM_TOTAL[@]}" | sort); do
    s=${CH_SUM_STUB["$chap"]:-0}
    h=${CH_SUM_SHIM["$chap"]:-0}
    b=${CH_SUM_BAK["$chap"]:-0}
    t=${CH_SUM_TOTAL["$chap"]:-0}
    printf "ch%s  | py:%-3s  stub:%-3s  shim:%-3s  bak:%-3s\n" "$chap" "$t" "$s" "$h" "$b"
  done
} >> "$TXT"

echo "[DONE] Rapport écrit:"
echo " - $TXT"
echo " - $CSV"
tail -n 12 "$TXT" || true
