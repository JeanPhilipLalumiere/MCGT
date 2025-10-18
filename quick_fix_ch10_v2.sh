#!/usr/bin/env bash
# quick_fix_ch10_v2.sh — Patchs minimaux chap.10 (safe) + relance + pause

set -Eeuo pipefail

pause_on_exit() {
  local status=$?
  echo
  echo "[DONE] Statut de sortie = $status"
  echo
  if [ -t 0 ]; then
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _
  else
    # garde la fenêtre interactive ouverte même en non-interactif
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

# 1) Corriger argparse: %(default)d / %(default)i -> %(default)s (évite TypeError)
fix_argparse_placeholders() {
  local f="$1"
  [ -f "$f" ] || return 0
  if grep -q '%(default)d' "$f"; then
    backup_once "$f"
    sed -i 's/%(default)d/%(default)s/g' "$f"
    echo "[FIX] argparse placeholders (d->s) : $f"
  fi
  if grep -q '%(default)i' "$f"; then
    backup_once "$f"
    sed -i 's/%(default)i/%(default)s/g' "$f"
    echo "[FIX] argparse placeholders (i->s) : $f"
  fi
}

for f in zz-scripts/chapter10/plot_fig*.py; do
  fix_argparse_placeholders "$f"
done

# 2) Dé-denter les lignes signalées (en « fixed string » pour éviter les regex)
dedent_line_if_matches() {
  # $1=file, $2=line_number, $3=fragment (fixed string)
  local f="$1" ln="$2" frag="$3"
  [ -f "$f" ] || { echo "[SKIP] $f manquant"; return 0; }
  local line; line="$(sed -n "${ln}p" "$f" || true)"
  [[ -z "$line" ]] && { echo "[SKIP] $f:${ln} introuvable"; return 0; }
  if printf '%s' "$line" | grep -F -q -- "$frag"; then
    # Si déjà sans indentation, ne rien faire
    if printf '%s' "$line" | grep -q '^[[:space:]]'; then
      backup_once "$f"
      sed -i "${ln}s/^[[:space:]]\+//" "$f"
      echo "[FIX] dé-dent $f:$ln  → $(echo "$line" | sed 's/^[[:space:]]\+//')"
    else
      echo "[OK ] pas d’indent à retirer $f:$ln"
    fi
  else
    echo "[SKIP] fragment non trouvé à $f:$ln"
  fi
}

dedent_line_if_matches "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py" 137 'p95_col = detect_p95_column'
dedent_line_if_matches "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py" 118 'orig_col = detect_column'
dedent_line_if_matches "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py" 84 'p95_col = detect_p95_column'
dedent_line_if_matches "zz-scripts/chapter10/plot_fig06_residual_map.py" 97 'x = df['
dedent_line_if_matches "zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py" 173 'p95_col = detect_p95_column'

# 3) Relance chap.10 (auto-selection du --results)
if [ -x ./run_ch10_v3.sh ]; then
  ./run_ch10_v3.sh
else
  echo "[ERR] run_ch10_v3.sh introuvable; crée-le puis relance."
  exit 3
fi

# 4) Mettre à jour le manifest (et log visible)
python3 tools/figure_manifest_builder.py || true
