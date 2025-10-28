#!/usr/bin/env bash
# File: stepR2_build_and_preview.sh
# Construit REVIEW = (Inventaire − IGNORE) ∪ ADD (priorité ADD>IGNORE), produit un plan dry-run.
set -Euo pipefail

need(){ command -v "$1" >/dev/null 2>&1 || { echo "[ERR] manquant: $1"; exit 2; }; }
for b in git awk sed sort uniq; do need "$b"; done

ADD="add_list_round2.txt"
IGN="ignore_list_round2.txt"
REV="review_list_round2.txt"      # sera régénéré
OUT="purge_plan_dryrun.txt"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p _logs

test -f "$ADD" || { echo "[ERR] introuvable: $ADD"; exit 2; }
test -f "$IGN" || { echo "[ERR] introuvable: $IGN"; exit 2; }

# 1) Inventaire canonique → fichiers suivis par git (hors supprimés)
echo "[INFO] Inventaire git…"
git ls-files -z | tr -d '\r' | tr '\0' '\n' | sed 's#^\./##' | sort -u > _logs/inventory_${STAMP}.lst

# 2) Normalise listes utilisateur (ignore commentaires/lignes vides)
norm_list () {
  local f="$1"
  sed -e 's/\r$//' -e 's/#.*$//' "$f" | awk 'NF' | sort -u
}

norm_list "$ADD" > _logs/add_${STAMP}.lst || true
norm_list "$IGN" > _logs/ign_${STAMP}.lst || true

# 3) Applique priorité ADD > IGNORE
#    - A = inventaire
#    - I = IGN \ ADD
#    - R = (A − I) ∪ ADD  (ensuite intersecté à A pour éviter les chemins hors inventaire)
comm -23 _logs/ign_${STAMP}.lst _logs/add_${STAMP}.lst > _logs/ign_effective_${STAMP}.lst  # IGN sans les ADD
# A − I
grep -Fvx -f _logs/ign_effective_${STAMP}.lst _logs/inventory_${STAMP}.lst > _logs/a_minus_i_${STAMP}.lst || cp _logs/inventory_${STAMP}.lst _logs/a_minus_i_${STAMP}.lst
# (A − I) ∪ ADD
cat _logs/a_minus_i_${STAMP}.lst _logs/add_${STAMP}.lst 2>/dev/null | sort -u > _logs/review_unclamped_${STAMP}.lst
# Clamp à l’inventaire réel
grep -Fxf _logs/inventory_${STAMP}.lst _logs/review_unclamped_${STAMP}.lst > "$REV"

# 4) Plan de purge (dry-run) = A − REVIEW
comm -23 _logs/inventory_${STAMP}.lst "$REV" > "$OUT"

# 5) Comptes & résumé
NA=$(wc -l < _logs/inventory_${STAMP}.lst | awk '{print $1}')
NADD=$(wc -l < _logs/add_${STAMP}.lst       | awk '{print $1}')
NIGN=$(wc -l < _logs/ign_${STAMP}.lst       | awk '{print $1}')
NREV=$(wc -l < "$REV"                       | awk '{print $1}')
NPUR=$(wc -l < "$OUT"                       | awk '{print $1}')

{
  echo "=== ROUND2 DRY-RUN @ ${STAMP} ==="
  echo "Inventaire (A)              : $NA"
  echo "ADD (prioritaire)           : $NADD"
  echo "IGNORE (avant priorité)     : $NIGN"
  echo "REVIEW (= (A−IGN)+ADD)      : $NREV"
  echo "PURGE PLAN (= A−REVIEW)     : $NPUR"
  echo
  echo "[FICHIERS]"
  echo "- Inventaire : _logs/inventory_${STAMP}.lst"
  echo "- ADD        : _logs/add_${STAMP}.lst"
  echo "- IGN eff.   : _logs/ign_effective_${STAMP}.lst"
  echo "- REVIEW     : ${REV}"
  echo "- PURGE PLAN : ${OUT}"
} | tee "_logs/round2_summary_${STAMP}.txt"

echo "[OK] Dry-run terminé. Rien n'a été supprimé."
