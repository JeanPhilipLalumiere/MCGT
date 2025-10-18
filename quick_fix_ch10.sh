#!/usr/bin/env bash
# quick_fix_ch10.sh — Patchs minimaux chap.10 + relance + pause

set -Eeuo pipefail

pause_on_exit() {
  local status=$?
  echo
  echo "[DONE] Statut de sortie = $status"
  echo
  if [ -t 0 ]; then
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _
  else
    bash --noprofile --norc -i
  fi
}
trap pause_on_exit EXIT INT

cd ~/MCGT

# 0) (optionnel) activer l’environnement
conda activate mcgt-dev 2>/dev/null || source ~/miniforge3/bin/activate mcgt-dev || true

backup_once() {
  local f="$1"
  [ -f "${f}.bak1" ] || cp -p "$f" "${f}.bak1"
}

# 1) Fix argparse: %d -> %s dans les help strings (évite TypeError)
fix_argparse_placeholders() {
  local f="$1"
  if grep -q '%(default)d' "$f"; then
    backup_once "$f"
    sed -i 's/%(default)d/%(default)s/g' "$f"
    echo "[FIX] argparse placeholders: %(default)d -> %(default)s  ($f)"
  fi
}

fix_argparse_placeholders "zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py"
# (optionnel) étendre aux autres fichiers si besoin :
for f in zz-scripts/chapter10/plot_fig*.py; do
  [ -f "$f" ] && fix_argparse_placeholders "$f" || true
done

# 2) Dé-denter les lignes signalées par le log (IndentationError)
dedent_line_if_matches() {
  # $1=file, $2=line_number, $3=grep_fragment
  local f="$1" ln="$2" frag="$3"
  [ -f "$f" ] || { echo "[SKIP] $f manquant"; return 0; }
  local line; line="$(sed -n "${ln}p" "$f" || true)"
  [[ "$line" == "" ]] && { echo "[SKIP] $f:${ln} introuvable"; return 0; }
  if echo "$line" | grep -q "$frag"; then
    backup_once "$f"
    # retire l'indent en début de ligne
    sed -i "${ln}s/^[[:space:]]\+//" "$f"
    echo "[FIX] dé-dent $f:$ln  → $(echo "$line" | sed 's/^[[:space:]]\+//')"
  fi
}

dedent_line_if_matches "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py" 137 'p95_col = detect_p95_column'
dedent_line_if_matches "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py" 118 'orig_col = detect_column'
dedent_line_if_matches "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py" 84 'p95_col = detect_p95_column'
dedent_line_if_matches "zz-scripts/chapter10/plot_fig06_residual_map.py" 97 'x = df['
dedent_line_if_matches "zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py" 173 'p95_col = detect_p95_column'

# 3) Relance chap.10 (auto-sélection du --results)
if [ -x ./run_ch10_v3.sh ]; then
  ./run_ch10_v3.sh
else
  echo "[ERR] run_ch10_v3.sh introuvable; crée-le puis relance."
  exit 3
fi

# 4) Mettre à jour le manifest
python3 tools/figure_manifest_builder.py || true
