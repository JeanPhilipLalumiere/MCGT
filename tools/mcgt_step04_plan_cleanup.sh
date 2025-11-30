#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p zz-logs
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
log="zz-logs/step04_cleanup_plan_${timestamp}.log"

echo "=== MCGT Step 04 : plan de nettoyage (attic & doublons) ===" | tee "$log"
echo "[INFO] Repo root : $ROOT" | tee -a "$log"
echo "[INFO] Horodatage (UTC) : ${timestamp}" | tee -a "$log"
echo | tee -a "$log"

# -----------------------------------------------------------------
# 1) Figures non canoniques (noms ne commençant pas par NN_fig_)
# -----------------------------------------------------------------
echo "------------------------------------------------------------" | tee -a "$log"
echo "[FIGURES] Candidats pour attic/ (noms non canoniques fig_*.png)" | tee -a "$log"

for ch in $(seq -w 1 10); do
  dir="zz-figures/chapter${ch}"
  [ -d "$dir" ] || continue
  found=0
  while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    # Canonique: NN_fig_*.png
    if [[ ! "$base" =~ ^${ch}_fig_.*\.png$ ]]; then
      if [ "$found" -eq 0 ]; then
        echo "[CH${ch}] Figures non canoniques (candidats attic)" | tee -a "$log"
        found=1
      fi
      echo "ATTIC_DUP_FIG $f" | tee -a "$log"
    fi
  done < <(find "$dir" -maxdepth 1 -type f -name '*.png' -print0 | sort -z)
done

# -----------------------------------------------------------------
# 2) Données suspectes (placeholder/dummy/example)
# -----------------------------------------------------------------
echo "------------------------------------------------------------" | tee -a "$log"
echo "[DATA] Fichiers placeholder/dummy/example (à vérifier avant attic)" | tee -a "$log"

for ch in $(seq -w 1 10); do
  dir="zz-data/chapter${ch}"
  [ -d "$dir" ] || continue
  found=0
  while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    low="${base,,}"
    if [[ "$low" == *placeholder* ]] || [[ "$low" == *dummy* ]] || [[ "$low" == *example* ]]; then
      if [ "$found" -eq 0 ]; then
        echo "[CH${ch}] Données à faible priorité (candidats attic/testdata)" | tee -a "$log"
        found=1
      fi
      echo "LOW_PRIORITY_DATA $f" | tee -a "$log"
    fi
  done < <(find "$dir" -maxdepth 1 -type f -print0 | sort -z)
done

# -----------------------------------------------------------------
# 3) Scripts doublons (via dernier rapport Step03)
# -----------------------------------------------------------------
echo "------------------------------------------------------------" | tee -a "$log"
echo "[SCRIPTS] Doublons potentiels (issus du rapport Step03)" | tee -a "$log"

step03_log="$(ls -1t zz-logs/step03_candidates_*.log 2>/dev/null | head -n1 || true)"
if [ -z "$step03_log" ]; then
  echo "[WARN] Aucun rapport Step03 trouvé, section SCRIPTS sautée." | tee -a "$log"
else
  echo "[INFO] Rapport Step03 utilisé : $step03_log" | tee -a "$log"
  echo | tee -a "$log"

  current_key=""
  canonical=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ key=([^[:space:]]+) ]]; then
      current_key="${BASH_REMATCH[1]}"
      canonical="$current_key"
      echo | tee -a "$log"
      echo "[KEY] $current_key" | tee -a "$log"
    elif [[ "$line" =~ ^zz-scripts/ ]]; then
      path="$line"
      base="$(basename "$path")"
      if [ -n "$canonical" ] && [ "$base" = "$canonical" ]; then
        echo "KEEP_CANONICAL_SCRIPT $path" | tee -a "$log"
      else
        echo "ATTIC_DUP_SCRIPT $path" | tee -a "$log"
      fi
    fi
  done < "$step03_log"
fi

echo | tee -a "$log"
echo "[OK] Step 04 (plan de nettoyage) terminé. Rapport : $log" | tee -a "$log"
