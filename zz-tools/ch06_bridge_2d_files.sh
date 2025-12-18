#!/usr/bin/env bash
# ch06_bridge_2d_files.sh – Harmoniser *_2d.csv -> *2D.csv pour CH06
set -Eeuo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "[ch06_bridge_2d] Bridge des fichiers *_2d.csv -> *2D.csv si nécessaire"

pairs=(
  "zz-data/chapter06/06_cmb_chi2_scan_2d.csv zz-data/chapter06/06_cmb_chi2_scan2D.csv"
  "zz-data/chapter06/06_delta_rs_scan_2d.csv zz-data/chapter06/06_delta_rs_scan2D.csv"
)

for entry in "${pairs[@]}"; do
  set -- $entry
  src="$1"
  dst="$2"

  if [[ -f "$src" && ! -f "$dst" ]]; then
    echo "[ch06_bridge_2d] cp \"$src\" -> \"$dst\""
    cp "$src" "$dst"
  elif [[ -f "$src" && -f "$dst" ]]; then
    echo "[ch06_bridge_2d] OK (déjà présents) : $src et $dst"
  elif [[ ! -f "$src" && -f "$dst" ]]; then
    echo "[ch06_bridge_2d] OK (canonique seulement) : $dst"
  else
    echo "[ch06_bridge_2d][WARN] Aucun des deux fichiers n'existe encore : $src , $dst"
  fi
done

echo "[ch06_bridge_2d] Terminé."
